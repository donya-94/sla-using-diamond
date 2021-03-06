 pragma solidity ^0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import "../libraries/AppStorage.sol";


 contract CloudSLA {
     
    AppStorage internal s;

    
    ////this is to log event that _witness report a violation at time stamp _time for a SLA monitoring round of _roundID
    event SLAViolationRep(address indexed _witness, uint _time, uint _roundID);    
     ////this is to log event that _who modified the SLA state to _newstate at time stamp _time
    event SLAStateModified(address indexed _who, uint _time, State _newstate);

    event WitnessSelected(address indexed _who, uint _index, address _forWhom);
    
    ////record the provider _who generates a SLA contract of address _contractAddr at time _time
    // event SLAContractGen(address indexed _who, uint _time, address _contractAddr);

 
    // constructor () 
    // {
    //     emit SLAContractGen(msg.sender, block.timestamp, address(this));
    // }

    // function genSLA (address _customer) external {
    //     require(!s.providerPool[msg.sender].registered);
    //     s.Provider = msg.sender;
    //     s.Customer =  _customer;
    //     s.SLAContractPool[address(this)].valid = true;
        
    //     emit SLAContractGen(msg.sender, block.timestamp, address(this));
    //     console.log('constructor is deployed address is:', address(this));
    // }

    function request()
        public 
        returns
        (bool success)
    {
        console.log('s.Provider is:', s.Provider);
        require(msg.sender == s.Provider , "msg.sender is not Provider");
        require(s.SLAContractPool[address(this)].valid , "sla contract is not valid");
        console.log('msg.sender is:', msg.sender);
        
        ////record current block number
        s.SLAContractPool[address(this)].curBlockNum = block.number;
        s.SLAContractPool[address(this)].blkNeed = s.BlkNeeded;
        return true;
    }


     
    function sortition(uint _N)
        public
        returns
        (bool success)
    {
        require(s.Provider == msg.sender);
        (s.WitnessNumber > s.witnessCommittee.length);
        
        require(s.WitnessNumber - s.witnessCommittee.length >= _N);
        
        require(s.Customer != address(0x0));
        require(s.SLAContractPool[address(this)].valid, "sortition: sla contract is not valid");
        ////make sure the request is invoked before this interface
        require(s.SLAContractPool[address(this)].curBlockNum != 0);
        //// there should be more than 10 times of _N online witnesses
        require(s.onlineCounter >= _N+2 , "online counter error");   ///this is debug mode
        //require(onlineCounter > 10*_N);
        
        ////currently, the hash value can only be accessed within 255 depth. In this case, invoke 'request' again
        require( block.number < s.SLAContractPool[address(this)].curBlockNum + 255);
        //// there should be more than extra 2*blkNeed blocks generated  
        // require( block.number > SLAContractPool[msg.sender].curBlockNum + 2*SLAContractPool[msg.sender].blkNeed , "> error");
        uint seed = 0;
        for(uint bi = 0 ; bi<s.SLAContractPool[address(this)].blkNeed ; bi++)
            seed += (uint)(blockhash(s.SLAContractPool[address(this)].curBlockNum + bi + 1 ));
        
        uint wcounter = 0;
        while(wcounter < _N){
            address sAddr = s.witnessAddrs[seed % s.witnessAddrs.length];
            
            if(s.witnessPool[sAddr].state == WState.Online && s.witnessPool[sAddr].reputation > 0
               && sAddr != msg.sender && sAddr != s.Customer)
            {
                s.witnessPool[sAddr].state = WState.Candidate;
                s.witnessPool[sAddr].confirmDeadline = block.timestamp + 5 minutes;   /// 5 minutes for confirmation
                s.witnessPool[sAddr].SLAContract = address(this);
                emit WitnessSelected(sAddr, s.witnessPool[sAddr].index, address(this));
                s.onlineCounter--;
                wcounter++;
                console.log("selectesd witness is:",sAddr);
            }
            
            seed = (uint)(keccak256(abi.encodePacked(seed)));
        }
        
        ///make this interface cannot be invoked twice without 'request'
        s.SLAContractPool[address(this)].curBlockNum = 0;
        return true;
    }
    

    //// this is for Cloud provider to set up this SLA and wait for Customer to accept
    function setupSLA() 
        public 
        payable 
    {
        require(s.SLAState == State.Fresh,"problem is in slaState requier");
        require(msg.sender == s.Provider);
        require((uint)(msg.value) >= s.PPrepayment);

        require(s.WitnessNumber == s.witnessCommittee.length);
        
        s.ProviderBalance += ((uint)(msg.value));
        s.SLAState = State.Init;
        s.AcceptTimeEnd = block.timestamp + s.AcceptTimeWin;
        console.log("accept time end is: ", s.AcceptTimeEnd);
        emit SLAStateModified(msg.sender, block.timestamp, State.Init);
        console.log("setUp SLA is done!");
    }

    function cancleSLA()
        public
    {
        require(s.SLAState == State.Init);
        require(msg.sender == s.Provider);
        require(block.timestamp < s.AcceptTimeEnd);
        if(s.ProviderBalance > 0){
            payable(msg.sender).transfer(s.ProviderBalance);
            s.ProviderBalance = 0;
        }
        
        s.SLAState = State.Fresh;
        
    }

    //// this is for customer to put its prepaid fee and accept the SLA
    function acceptSLA() 
        public 
        payable 
    {
        require(s.SLAState == State.Init);
        require(msg.sender == s.Customer);
        console.log("accept time end is: ", s.AcceptTimeEnd);
        console.log("block.timestamp is: ", block.timestamp);
        require(block.timestamp <= s.AcceptTimeEnd);
        require((uint)(msg.value) >= s.CPrepayment);

        uint _value;
        require(s.WitnessNumber == s.witnessCommittee.length);
        
        s.CustomerBalance += msg.value;
        s.SLAState = State.Active;
        emit SLAStateModified(msg.sender, block.timestamp, State.Active);
        s.ServiceEnd = block.timestamp + s.ServiceDuration;
        
        ///transfer ServiceFee from customer to provider 
        //ProviderBalance += ServiceFee;
        s.CustomerBalance -= s.ServiceFee;
        
        ///setup the SharedBalance
        s.ProviderBalance -= s.SharedFee;
        s.CustomerBalance -= s.SharedFee;
        s.SharedBalance += s.SharedFee*2;
        
        ////send amount of service fee to the provider if provider ranking is high
        if(s.providerPool[s.Provider].reputation >= 100){
            
            payable(s.Provider).transfer(s.ServiceFee - s.CompensationFee);
            s.CustomerBalance -= (s.ServiceFee - s.CompensationFee);
        }

        console.log("accept SLA is done!");
        
    }

    


    /**
     * Contract Interface::
     * Candidate witness calls the SLA contract and confirm the sortition. 
     * */
    function confirm()
        public
        returns 
        (bool)
    {
        require(s.witnessPool[msg.sender].registered);
        require(s.SLAContractPool[address(this)].valid);

        ////have not registered in the witness committee
        require(!s.witnesses[msg.sender].selected);
        
        ////The candidate witness can neither be the provider nor the customer
        require(msg.sender != s.Provider);
        require(msg.sender != s.Customer);

        ////have not reached the confirmation deadline
        require( block.timestamp < s.witnessPool[msg.sender].confirmDeadline );
        
        ////only able to confirm in candidate state
        require(s.witnessPool[msg.sender].state == WState.Candidate);
        
        ////only the SLA contract can select it.
        require(s.witnessPool[msg.sender].SLAContract == address(this));
        
        s.witnessPool[msg.sender].state = WState.Busy;

        s.witnessCommittee.push(msg.sender);
        s.witnesses[msg.sender].selected = true;
        
        console.log("witness confirmed: ", msg.sender);

        return true;
    }


    function reportViolation()
        public
        payable
    {
         require(block.timestamp < s.ServiceEnd);
         require(s.witnesses[msg.sender].selected);
         require((uint)(msg.value) >= s.VoteFee);

        uint equalOp = 0;   /////nonsense operation to make every one using the same gas 
        
        if(s.ReportTimeBegin == 0)
            s.ReportTimeBegin = block.timestamp;
        else
            equalOp = block.timestamp; 
            
        ////only valid within the confirmation time window
        require(block.timestamp < s.ReportTimeBegin + s.ReportTimeWin);
        
        require( s.SLAState == State.Violated || s.SLAState == State.Active );
        
        /////one witness cannot vote twice 
        require(!s.witnesses[msg.sender].violated);
        
        s.witnesses[msg.sender].violated = true;
        s.witnesses[msg.sender].balance += s.VoteFee;
        s.witnesses[msg.sender].reported += 1;
        
        s.ConfirmRepCount++;
        
        ////the witness who reports in the last order pay more gas as penalty
        if( s.ConfirmRepCount >= s.ConfirmNumRequired ){
            s.SLAState = State.Violated;
            emit SLAStateModified(msg.sender, block.timestamp, State.Violated);
            s.confirmedViolationNumber++;
        }
        
        emit SLAViolationRep(msg.sender, block.timestamp, s.ServiceEnd);

        console.log("violated");
    }

    function resetWitnessByWitness() 
        public 

       checkWitnessSelected(){
            require(s.SLAState == State.Violated);
            require(block.timestamp > s.ServiceEnd);
            require(s.witnesses[msg.sender].selected);
            if(s.witnesses[s.witnessCommittee[msg.sender]].violated == true && s.confirmedViolationNumber < s.witnesses[s.witnessCommittee[msg.sender]].reported){
                s.witnesses[s.witnessCommittee[msg.sender]].violated = false;
                s.SharedBalance += s.witnesses[s.witnessCommittee[msg.sender]].balance;    ///penalty
                s.witnesses[s.witnessCommittee[msg.sender]].balance = 0;
                s.witnessPool[s.witnessCommittee[msg.sender]].reputation -= 1;  ////the reputation value of this witness decreases by 1
            }
    }

     ///this only restart the SLA lifecycle, not including the selecting the witness committee. This is to continuously deliver the servce. 
    function restartSLA()
        public
        payable
    {

        require(s.SLAState == State.Completed);
        require(block.timestamp > s.ServiceEnd);
        require(msg.sender == s.Provider);
        require((uint)(msg.value) >= s.PPrepayment);
        
    //// to ensure all the customers and witnesses has withdrawn money back
        require(s.CustomerBalance == 0);
        
        for(uint i = 0 ; i < s.witnessCommittee.length ; i++)
            require(s.witnesses[s.witnessCommittee[i]].balance == 0);// for and the upper requier are together

        require(s.WitnessNumber == s.witnessCommittee.length);
        
        /// reset all the related values
        s.ConfirmRepCount = 0;
        s.ReportTimeBegin = 0;
        
        ///reset the witnesses' state only
        for(uint i = 0 ; i < s.witnessCommittee.length ; i++){
            if(s.witnesses[s.witnessCommittee[i]].violated == true)
                s.witnesses[s.witnessCommittee[i]].violated = false;
        }
        
        
        s.ProviderBalance = msg.value;
        s.SLAState = State.Init;
        s.AcceptTimeEnd = block.timestamp + s.AcceptTimeWin;
        emit SLAStateModified(msg.sender, block.timestamp, State.Init);
    }




 }