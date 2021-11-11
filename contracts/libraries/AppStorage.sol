pragma solidity ^0.8.0;

enum WState { Offline, Online, Candidate, Busy }
    
enum PState {Offline, Online} 

enum State { Fresh, Init, Active, Violated, Completed }

struct Witness {
    bool registered;    ///true: this witness has registered.
    uint index;         ///the index of the witness in the address pool, if it is registered
        
    WState state;    ///the state of the witness
        
    address SLAContract;    ////the contract address of 
    uint confirmDeadline;   ////Must confirm the sortition in the state of Candidate. Otherwise, reputation -10.
    int8 reputation;       ///the reputation of the witness, the initial value is 100. If it is 0, than it is blocked.
}

struct Provider {
    bool registered;    ///true: this Provider has registered.
    uint index;         ///the index of the Provider in the address pool, if it is registered
        
    PState state;    ///the state of the Provider
        
    address SLAContract;    ////the contract address of 
    int8 reputation;       ///the reputation of the witness, the initial value is 100. If it is 0, than it is blocked.
}

struct SortitionInfo{
    bool valid;
    uint curBlockNum;
    uint8 blkNeed;   ////how many blocks needed for sortition
}

//This struct is for SLA Contract
struct WitnessAccount {
    bool selected;   ///wheterh it is a member witness committee
    bool violated;   ///whether it has reported that the service agreement is violated 
    uint balance;    ///the account balance of this witness
    uint8 reported;  ///this is for holding number of violation that witnesses report
}

struct AppStorage{

    uint onlineCounter;

    WState[] wState;
    PState[] pState;
    State[] state;

    mapping(address => Witness) witnessPool;    
    address [] witnessAddrs;    ////the address pool of witnesses

    mapping(address => Provider) providerPool;    
    address [] providerAddrs;    ////the address pool of providers
    
    mapping(address => SortitionInfo) SLAContractPool;   ////record the requester's initial block number. The sortition will be based on the hash value after this block.
    

////SLA Contract State Variables ********************************************
    mapping(address => WitnessAccount) witnesses; ////This is for SLA Contract

    State SLAState;
    
    uint confirmedViolationNumber;// this is for number of confirmed violation
    
    string cloudServiceDetail;
    
    uint8 BlkNeeded;
    
    uint CompensationFee; ///0.5 ether
    uint ServiceFee;
    uint ServiceDuration;  
    uint ServiceEnd;
    
    uint WF4NoViolation;  ///the fee for the witness if there is no violation
    uint WF4Violation;   ///the fee for the witness in case there is violation
    uint VoteFee;   ///this is the fee for witness to report its violation
    
    uint WitnessNumber;   ///N
    uint ConfirmNumRequired;   ////M: This is a number to indicate how many witnesses needed to confirm the violation
    
    uint SharedFee;  ////this is the maximum shared fee to pay the witnesses
    uint ReportTimeWin;   ////the time window for waiting all the witnesses to report a violation event 
    uint ReportTimeBegin;
    uint ConfirmRepCount;
    
    uint AcceptTimeWin;   ///the time window for waiting the customer to accept this SLA, otherwise the state of SLA is transferred to Completed
    uint AcceptTimeEnd;

    address Customer;
    uint CustomerBalance;
    uint CPrepayment;
    
    address Provider;
    uint ProviderBalance;
    uint PPrepayment;
    
    /////this is the balance to reward the witnesses from the committee
    uint SharedBalance;
    
    //// this is the witness committee
    address [] witnessCommittee;
    
}



contract Modifier {
    AppStorage internal s;

    ////record the provider _who generates a SLA contract of address _contractAddr at time _time
    event SLAContractGen(address indexed _who, uint _time, address _contractAddr);


    event WitnessSelected(address indexed _who, uint _index, address _forWhom);

 
    ////this is to log event that _who modified the SLA state to _newstate at time stamp _time
    event SLAStateModified(address indexed _who, uint _time, State _newstate);

    ////this is to log event that _witness report a violation at time stamp _time for a SLA monitoring round of _roundID
    event SLAViolationRep(address indexed _witness, uint _time, uint _roundID);

    ////record the _SLAContract which rank the _provider
    event ProviderReputation(address indexed _contractAddr, uint _time, int8 _value, address _provider);

    ////check whether the register has already registered
    modifier checkRegister(address _register){
        require(!s.witnessPool[_register].registered);
        _;
    }

    modifier checkProviderRegister(address _register){
        require(!s.providerPool[_register].registered);
        _;
    } 
    
    ////check whether it is a registered witness
    modifier checkWitness(address _witness){
        require(s.witnessPool[_witness].registered);
        _;
    }
    ////check whether the sender is a legal witness member in the committee 
    modifier checkWitnessSelected() {
        
        require(s.witnesses[msg.sender].selected);
        _;
    }
    
    // ////check whether it is a registered provider
    // modifier checkProvider(address _provider){
    //     require(s.providerPool[_provider].registered);
    //     _;
    // }
    
    ////check whether it is a valid SLA contract
    modifier checkSLAContract(address _sla){
        require(s.SLAContractPool[_sla].valid);
        _;
    }

    modifier checkState(State _state){
        require(s.SLAState == _state);
        _;
    }

    
    modifier checkProvider() {
        require(msg.sender == s.Provider);
        _;
    }

    // modifier checkProviderReputation (address _provider)
    // {
    //     require(s.providerPool[_provider].reputation >= 100);
    //     _;
    // }
    
    modifier checkCustomer() {
        require(msg.sender == s.Customer);
        _;
    }
    
    modifier checkMoney(uint _money) {
        require((uint)(msg.value) >= _money);
        _;
    }
    
    modifier checkTimeIn(uint _endTime) {
        require(block.timestamp < _endTime);
        _;
    }
    
    modifier checkTimeOut(uint _endTime) {
        require(block.timestamp > _endTime);
        _;
    }
    
    //// to ensure all the customers and witnesses has withdrawn money back
    modifier checkAllBalance(){
        require(s.CustomerBalance == 0);
        
        for(uint i = 0 ; i < s.witnessCommittee.length ; i++)
            require(s.witnesses[s.witnessCommittee[i]].balance == 0);
        
        _;
    }
}