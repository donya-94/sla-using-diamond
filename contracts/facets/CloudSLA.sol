 pragma solidity ^0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import "../libraries/AppStorage.sol";


 contract CloudSLA {
     
    AppStorage internal s;

     ////this is to log event that _who modified the SLA state to _newstate at time stamp _time
    event SLAStateModified(address indexed _who, uint _time, State _newstate);
    
    ////record the provider _who generates a SLA contract of address _contractAddr at time _time
    event SLAContractGen(address indexed _who, uint _time, address _contractAddr);

 
    constructor (address _customer)
        public
    {
        require(!s.providerPool[msg.sender].registered);
        console.log('before  s.ReportTimeWin is: ',  s.ReportTimeWin);
        s.Provider = msg.sender;
        console.log('s.Provider is:', s.Provider);
        s.Customer = _customer;
        s.SLAContractPool[address(this)].valid = true;
        emit SLAContractGen(msg.sender, block.timestamp, address(this));
        console.log('constructor is deployed address is:', address(this));
    }

    

    //// this is for Cloud provider to set up this SLA and wait for Customer to accept
    function setupSLA() 
        public 
        payable 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        require((uint)(msg.value) >= s.PPrepayment);

        require(s.WitnessNumber == s.witnessCommittee.length);
        
        s.ProviderBalance += ((uint)(msg.value));
        s.SLAState = State.Init;
        s.AcceptTimeEnd = block.timestamp + s.AcceptTimeWin;
        emit SLAStateModified(msg.sender, block.timestamp, State.Init);
    }

    function cancleSLA()
        public
    {
        require(s.SLAState == State.Init);
        require(msg.sender == s.Provider);
        require(block.timestamp > s.AcceptTimeEnd);
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
        require(block.timestamp > s.AcceptTimeEnd);
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
        
    }

    


    /**
     * Contract Interface::
     * Candidate witness calls the SLA contract and confirm the sortition. 
     * */
    // function confirm()
    //     public
    //     checkWitness(msg.sender)
    //     checkSLAContract(address(this))
    //     returns 
    //     (bool)
    // {
    //     require(s.witnessPool[msg.sender].registered);
    //     require(s.SLAContractPool[address(this)].valid);

    //     ////have not registered in the witness committee
    //     require(!s.witnesses[msg.sender].selected);
        
    //     ////The candidate witness can neither be the provider nor the customer
    //     require(msg.sender != s.Provider);
    //     require(msg.sender != s.Customer);

    //     ////have not reached the confirmation deadline
    //     require( block.timestamp < s.witnessPool[msg.sender].confirmDeadline );
        
    //     ////only able to confirm in candidate state
    //     require(s.witnessPool[msg.sender].state == WState.Candidate);
        
    //     ////only the SLA contract can select it.
    //     require(s.witnessPool[msg.sender].SLAContract == address(this));
        
    //     s.witnessPool[msg.sender].state = WState.Busy;

    //     s.witnessCommittee.push(msg.sender);
    //     s.witnesses[msg.sender].selected = true;
        
    //     return true;
    // }


    // function reportViolation()
    //     public
    //     payable
    //     checkTimeIn(s.ServiceEnd)
    //     checkWitnessSelected() 
    //     checkMoney(s.VoteFee)
    // {
    //     uint equalOp = 0;   /////nonsense operation to make every one using the same gas 
        
    //     if(s.ReportTimeBegin == 0)
    //         s.ReportTimeBegin = block.timestamp;
    //     else
    //         equalOp = block.timestamp; 
            
    //     ////only valid within the confirmation time window
    //     require(block.timestamp < s.ReportTimeBegin + s.ReportTimeWin);
        
    //     require( s.SLAState == State.Violated || s.SLAState == State.Active );
        
    //     /////one witness cannot vote twice 
    //     require(!s.witnesses[msg.sender].violated);
        
    //     s.witnesses[msg.sender].violated = true;
    //     s.witnesses[msg.sender].balance += s.VoteFee;
    //     s.witnesses[msg.sender].reported += 1;
        
    //     s.ConfirmRepCount++;
        
    //     ////the witness who reports in the last order pay more gas as penalty
    //     if( s.ConfirmRepCount >= s.ConfirmNumRequired ){
    //         s.SLAState = State.Violated;
    //         emit SLAStateModified(msg.sender, block.timestamp, State.Violated);
    //         s.confirmedViolationNumber++;
    //     }
        
    //     emit SLAViolationRep(msg.sender, block.timestamp, s.ServiceEnd);
    // }

    //  ///this only restart the SLA lifecycle, not including the selecting the witness committee. This is to continuously deliver the servce. 
    // function restartSLA()
    //     public
    //     payable
    //     checkState(State.Completed)
    //     checkTimeOut(s.ServiceEnd)
    //     checkProvider
    //     checkAllBalance
    //     checkMoney(s.PPrepayment)
    // {
    //     require(s.WitnessNumber == s.witnessCommittee.length);
        
    //     /// reset all the related values
    //     s.ConfirmRepCount = 0;
    //     s.ReportTimeBegin = 0;
        
    //     ///reset the witnesses' state only
    //     for(uint i = 0 ; i < s.witnessCommittee.length ; i++){
    //         if(s.witnesses[s.witnessCommittee[i]].violated == true)
    //             s.witnesses[s.witnessCommittee[i]].violated = false;
    //     }
        
        
    //     s.ProviderBalance = msg.value;
    //     s.SLAState = State.Init;
    //     s.AcceptTimeEnd = block.timestamp + s.AcceptTimeWin;
    //     emit SLAStateModified(msg.sender, block.timestamp, State.Init);
    // }




 }