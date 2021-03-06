pragma solidity ^0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import "../libraries/AppStorage.sol";


contract WithDrawFacet {
    AppStorage internal s;

    
    ////this is to log event that _who modified the SLA state to _newstate at time stamp _time
    event SLAStateModified(address indexed _who, uint _time, State _newstate);

    //// the customer end the violated SLA and withdraw its compensation
    function customerEndVSLAandWithdraw()
        public
    {
        require(s.SLAState == State.Violated);
        require(msg.sender == s.Customer);
        /////end the Service 
        s.ServiceEnd = block.timestamp;
        ////end the violation reports
        if(block.timestamp < s.ReportTimeBegin + s.ReportTimeWin)
            s.ReportTimeBegin = block.timestamp - s.ReportTimeWin;
         
        for(uint i = 0 ; i < s.witnessCommittee.length ; i++){
            if(s.witnesses[s.witnessCommittee[i]].violated == true){
                s.witnesses[s.witnessCommittee[i]].balance += s.WF4Violation;  ///reward the witness who reported this violation
                s.SharedBalance -= s.WF4Violation;
                s.witnessPool[s.witnessCommittee[i]].reputation += 1;
            }else{
                s.witnessPool[s.witnessCommittee[i]].reputation -= 1;  ////the reputation value of this witness decreases by 1
               //witnesses[witnessCommittee[i]].balance += WF4NoViolation;  
                //SharedBalance -= WF4NoViolation;
            }
        }
        
        rankingProvider();
        
        ///compensate the customer for service violation
        s.CustomerBalance += s.CompensationFee;
        s.ProviderBalance -= s.CompensationFee;
        
        /// customer and provider divide the remaining shared balance
        if(s.SharedBalance > 0){
            s.CustomerBalance += (s.SharedBalance/2);
            s.ProviderBalance += (s.SharedBalance/2);
        }
        s.SharedBalance = 0;
        
        
        s.SLAState = State.Completed;
        emit SLAStateModified(msg.sender, block.timestamp, State.Completed);
        
        if(s.CustomerBalance > 0){
            payable(msg.sender).transfer(s.CustomerBalance);
            s.CustomerBalance = 0;
        }
        
    }
    
    function customerWithdraw()
        public
    {
        require(block.timestamp > s.ServiceEnd);
        require(s.SLAState == State.Completed);
        require(msg.sender == s.Customer);
        require(s.CustomerBalance > 0);
        
        payable(msg.sender).transfer(s.CustomerBalance);
            
        s.CustomerBalance = 0;
    }
    
    function providerWithdraw()
        public
    {
        require(block.timestamp > s.ServiceEnd);
        require(s.SLAState == State.Completed);
        require(msg.sender == s.Provider);
        require(s.ProviderBalance > 0);
        
        payable(msg.sender).transfer(s.ProviderBalance);
        
        s.ProviderBalance = 0;
    }

//     //// this means there is no violation during this service. This function needs provider to invoke to end and gain its benefit
    function providerEndNSLAandWithdraw()
        public
    {
        require(block.timestamp > s.ServiceEnd);
        require(s.SLAState == State.Active);
        require(msg.sender == s.Provider);

        for(uint i = 0 ; i < s.witnessCommittee.length ; i++){
            if(s.witnesses[s.witnessCommittee[i]].violated == true && s.confirmedViolationNumber < s.witnesses[s.witnessCommittee[i]].reported){
                s.SharedBalance += s.witnesses[s.witnessCommittee[i]].balance;   ////penalty for the reported witness, might be cheating
                s.witnesses[s.witnessCommittee[i]].balance = 0;

                s.witnessPool[s.witnessCommittee[i]].reputation -= 1;   ////the reputation value of this witness decreases by 1
            }else{
                s.witnesses[s.witnessCommittee[i]].balance += s.WF4NoViolation;       /// reward the witness
                s.SharedBalance -= s.WF4NoViolation;
            }
            
        }
        
        /// customer and provider divide the remaining shared balance
        if(s.SharedBalance > 0){
            s.CustomerBalance += (s.SharedBalance/2);
            s.ProviderBalance += (s.SharedBalance/2);
        }
        s.SharedBalance = 0;
        
        s.SLAState = State.Completed;
        emit SLAStateModified(msg.sender, block.timestamp, State.Completed);
        
        if(s.ProviderBalance > 0){
            payable(msg.sender).transfer(s.ProviderBalance);
            s.ProviderBalance = 0;
        }
            
        
        rankingProvider();
    }
    
    function witnessWithdraw()
        public
    {
        require(block.timestamp > s.ServiceEnd);
        require(s.SLAState == State.Completed);
        require(s.witnesses[msg.sender].selected);
        require(s.witnesses[msg.sender].balance > 0);
            
        payable(msg.sender).transfer(s.witnesses[msg.sender].balance);
        
        s.witnesses[msg.sender].balance = 0;
        
        
    }


    function rankingProvider()
        public  
        {
            require(s.SLAState == State.Completed);
            if(s.confirmedViolationNumber>2){
                s.providerPool[s.Provider].reputation -= 10;
            }
            else {
                s.providerPool[s.Provider].reputation += 10;
            }
        }


//         ///Ddecrease or Increase the provider reputation
//     // function setProviderReputation(address _provider, int8 _value)
//     // public
//     // {
//     //     s.providerPool[_provider].reputation += _value;
//     //     emit ProviderReputation(msg.sender, now, _value, _provider);
//     // }



}