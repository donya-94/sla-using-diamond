pragma solidity ^ 0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import "../libraries/AppStorage.sol";

contract SLAInitializing{
    
    AppStorage internal s;


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