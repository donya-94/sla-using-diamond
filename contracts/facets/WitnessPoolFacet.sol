pragma solidity ^0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import "../libraries/AppStorage.sol";

contract WitnessPoolFacet {

    
    AppStorage internal s;

    function returnValue() public view
    {
       console.log('ReportTimeWin is: ', s.ReportTimeWin); 
    }
    
    
    // AppStorage internal s;

    /**
     * Provider Interface::
     * This is for provider to register itself
    * */
    function registerProvider() 
        public  
    {
        require(!s.providerPool[msg.sender].registered);
        s.providerAddrs.push(msg.sender);
        s.providerPool[msg.sender].index = s.providerAddrs.length - 1;
        s.providerPool[msg.sender].state = PState.Online;
        s.providerPool[msg.sender].reputation = 100; 
        s.providerPool[msg.sender].registered = true;
        console.log('registered provider');
    }


/**
     * Normal User Interface::
     * This is for the normal user to register as a witness into the pool
     * */
    function register() 
        public  
    {
        require(!s.witnessPool[msg.sender].registered);
        s.witnessAddrs.push(msg.sender);
        s.witnessPool[msg.sender].index = s.witnessAddrs.length - 1;
        s.witnessPool[msg.sender].state = WState.Online;
        s.witnessPool[msg.sender].reputation = 100; 
        s.witnessPool[msg.sender].registered = true;
        s.onlineCounter++;
        console.log('registerd Witness');
    }
    
   

    /**
     * Witness Interface::
     * Reject the sortition for candidate. Because the SLA contract is not valid.
     * */
    function reject()
        public
    {
        require(s.witnessPool[msg.sender].registered);
        ////only reject in candidate state
        require(s.witnessPool[msg.sender].state == WState.Candidate);
        
        ////have not reached the rejection deadline
        require( block.timestamp < s.witnessPool[msg.sender].confirmDeadline );
        
        s.witnessPool[msg.sender].state = WState.Online;
        s.onlineCounter++;
    }
    
    
    
    
    /**
     * Witness Interface::
     * Reverse its own state to Online after the confirmation deadline. But need to reduece the reputation. 
     * */
    function reverse()
        public
    {
        require(s.witnessPool[msg.sender].registered);
        ////must exceed the confirmation deadline
        require( block.timestamp > s.witnessPool[msg.sender].confirmDeadline );
        
        ////able to turn only in candidate state
        require(s.witnessPool[msg.sender].state == WState.Candidate);
        
        s.witnessPool[msg.sender].reputation -= 10;
        
        if(s.witnessPool[msg.sender].reputation <= 0){
            s.witnessPool[msg.sender].state = WState.Offline;
        }else{
            s.witnessPool[msg.sender].state = WState.Online;
            s.onlineCounter++;
        }
    }
    
    /**
     * Witness Interface::
     * Turn online to wait for sortition. The witness with reputation samller than 0 cannot be turned on.
     * */
    function turnOn()
        public
    {
        require(s.witnessPool[msg.sender].registered);
        ////must be in the state of offline
        require(s.witnessPool[msg.sender].state == WState.Offline);
        
        ///its reputation must be bigger than 0
        require( s.witnessPool[msg.sender].reputation > 0 );
        
        s.witnessPool[msg.sender].state = WState.Online;
        s.onlineCounter++;
    }
    
    /**
     * Witness Interface::
     * Turn offline to avoid sortition.
     * */
    function turnOff()
        public
    {
        
        require(s.witnessPool[msg.sender].registered);
        ////must be in the state of online
        require(s.witnessPool[msg.sender].state == WState.Online);
        
        s.witnessPool[msg.sender].state = WState.Offline;
        s.onlineCounter--;
    }
    
    
    /**
     * Witness Interface::
     * For witness itself to check the state of itself and the reputation.
     * If it is selected, following two return values show its confirmation deadline and the address of the SLA contract, who sortited it. 
     * */
    function checkWState(address _witness)
        public
        view
        returns
        (WState, int8, uint, address)
    {
        return (s.witnessPool[_witness].state, s.witnessPool[_witness].reputation, s.witnessPool[_witness].confirmDeadline, s.witnessPool[_witness].SLAContract);
    }






    /**
     * Customer Interface:
     * Reset the witnesses' state, who have reported.
     * */
    // function resetWitnessByCustomer() 
    //     public 
    //     checkState(State.Active) 
    //     checkCustomer
    //     checkTimeIn(s.ServiceEnd)
    // {
    //     ////some witness has reported the violation
    //     require(s.ReportTimeBegin != 0);
        
    //     ////some witness reported, but the violation is not confirmed 
    //     require(block.timestamp > s.ReportTimeBegin + s.ReportTimeWin);
        
        
    //     for(uint i = 0 ; i < s.witnessCommittee.length ; i++){
    //         if(s.witnesses[s.witnessCommittee[i]].violated == true && s.confirmedViolationNumber < s.witnesses[s.witnessCommittee[i]].reported){
    //             s.witnesses[s.witnessCommittee[i]].violated = false;
    //             s.SharedBalance += s.witnesses[s.witnessCommittee[i]].balance;    ///penalty
    //             s.witnesses[s.witnessCommittee[i]].balance = 0;
    //             s.witnessPool[s.witnessCommittee[i]].reputation -= 1;  ////the reputation value of this witness decreases by 1
    //         }
            
    //     }
        
    //     s.ConfirmRepCount = 0;
    //     s.ReportTimeBegin = 0;
        
    // }


    // function resetWitnessByWitness() 
    //     public 
    //     checkState(State.Violated) 
    //    checkWitnessSelected()
    //     checkTimeIn(s.ServiceEnd) {
    //     if(s.witnesses[msg.sender].violated == true && s.confirmedViolationNumber <= s.witnesses[msg.sender].reported){
    //             s.witnesses[msg.sender].violated = false;
    //             // SharedBalance += witnesses[witnessCommittee[i]].balance;    ///penalty
    //             // witnesses[witnessCommittee[i]].balance = 0;
    //         }
    // }



}