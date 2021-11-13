pragma solidity ^ 0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import "../libraries/AppStorage.sol";

contract SLAInitializing{
    
    AppStorage internal s;

constructor (){
    s.confirmedViolationNumber = 0;// this is for number of confirmed violation
    s.cloudServiceDetail = "";
    
    s.BlkNeeded = 2;
    
    s.CompensationFee = 500e15; ///0.5 ether
    s.ServiceFee = 1 ether;
    s.ServiceDuration = 2 minutes;  
    s.ServiceEnd = 0;
    
    s.WF4NoViolation = 10e15;  ///the fee for the witness if there is no violation
    s.WF4Violation = 10*s.WF4NoViolation;   ///the fee for the witness in case there is violation
    s.VoteFee = s.WF4NoViolation;   ///this is the fee for witness to report its violation
    
    s.WitnessNumber = 3;   ///N
    s.ConfirmNumRequired = 2;   ////M: This is a number to indicate how many witnesses needed to confirm the violation
    
    s.SharedFee = (s.WitnessNumber * s.WF4Violation)/2;  ////this is the maximum shared fee to pay the witnesses
    s.ReportTimeWin = 2 seconds;   ////the time window for waiting all the witnesses to report a violation event 
    s.ReportTimeBegin = 0;
    s.ConfirmRepCount = 0;
    
    s.AcceptTimeWin = 2 minutes;   ///the time window for waiting the customer to accept this SLA, otherwise the state of SLA is transferred to Completed
    s.AcceptTimeEnd = 0;

    s.CustomerBalance = 0;
    s.CPrepayment = s.ServiceFee + s.SharedFee;
    
    s.ProviderBalance = 0;
    s.PPrepayment = s.SharedFee;
    
    /////this is the balance to reward the witnesses from the committee
    s.SharedBalance = 0;
}

function returnTime() public view
    {
       console.log('ReportTimeWin is: ', s.ReportTimeWin); 
    }


    function setBlkNeeded(uint8 _blkNeed)
        public 
        
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        require(_blkNeed > 1);
        s.BlkNeeded = _blkNeed;
    }

////the unit is Szabo = 0.001 finney
    function setCompensationFee(uint _compensationFee)
        public 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        require(_compensationFee > 0);
        uint oneUnit = 1e12;
        s.CompensationFee = _compensationFee*oneUnit;
    }

    function setServiceFee(uint _serviceFee)
        public 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        require(_serviceFee > 0);
        uint oneUnit = 1e12;
        s.ServiceFee = _serviceFee*oneUnit;
    }

    function setWitnessFee(uint _witnessFee)
        public 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        require(_witnessFee > 0);
        uint oneUnit = 1e12;
        s.WF4NoViolation = _witnessFee*oneUnit;
        s.VoteFee = s.WF4NoViolation;
    }

    //the unit is minutes
    function setServiceDuration(uint _serviceDuration)
        public 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        require(_serviceDuration > 0);
        uint oneUnit = 1 minutes;
        s.ServiceDuration = _serviceDuration*oneUnit;
    }

    //Set the witness committee number, which is the 'N'
    function setWitnessCommNum(uint _witnessCommNum)
        public 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        require(_witnessCommNum > 2);
        require(_witnessCommNum > s.witnessCommittee.length);
        s.WitnessNumber = _witnessCommNum;
    }

    // Set the 'M' out of 'N' to confirm the violation
    function setConfirmNum(uint _confirmNum)
        public 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        //// N/2 < M < N 
        require(_confirmNum > (s.WitnessNumber/2));
        require(_confirmNum < s.WitnessNumber);
        
        s.ConfirmNumRequired = _confirmNum;
    }

    //Set the customer address
    // function setCustomer(address _customer)
    //     public 
    //     checkState(State.Fresh) 
    //     checkProvider
    // {
    //     Customer = _customer;
    // }

     //// this is for Cloud provider to publish its service detail
    function publishService(string memory _serviceDetail) 
        public 
    {
        require(s.SLAState == State.Fresh);
        require(msg.sender == s.Provider);
        s.cloudServiceDetail = _serviceDetail;
    }

}