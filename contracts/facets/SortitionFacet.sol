pragma solidity ^0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { AppStorage, WState, State } from "../libraries/AppStorage.sol";

contract SortitionFacet {

    
    AppStorage internal s;

    event WitnessSelected(address indexed _who, uint _index, address _forWhom);


    /**
     * Contract Interface::
     * This is for SLA contract to submit a committee sortition request.
     * _blkNeed: This is a number to specify how many blocks needed in the future for the committee sortition. 
     *            Its range should be 2~255. The recommended value is 12.  
     * */
    function request(address slaContractAddr)
        public 
        returns
        (bool success)
    {
        require(msg.sender == s.Provider);
        require(s.SLAContractPool[slaContractAddr].valid);
        console.log('msg.sender is:', msg.sender);
        console.log('s.Provider is:', s.Provider);
        ////record current block number
        s.SLAContractPool[slaContractAddr].curBlockNum = block.number;
        s.SLAContractPool[slaContractAddr].blkNeed = s.BlkNeeded;
        return true;
    }
    
    /**
     * Contract Interface::
     * Request for a sortition of _N witnesses. The _provider and _customer must not be selected.
     * */

     // باید این تابع از طرف sla فرستاده بشه 
    function sortition(uint _N, address _provider, address _customer)
        public
        returns
        (bool success)
    {
        require(s.SLAContractPool[msg.sender].valid);
        ////make sure the request is invoked before this interface
        require(s.SLAContractPool[msg.sender].curBlockNum != 0);
        //// there should be more than 10 times of _N online witnesses
        require(s.onlineCounter >= _N+2 , "online counter error");   ///this is debug mode
        //require(onlineCounter > 10*_N);
        
        ////currently, the hash value can only be accessed within 255 depth. In this case, invoke 'request' again
        require( block.number < s.SLAContractPool[msg.sender].curBlockNum + 255);
        //// there should be more than extra 2*blkNeed blocks generated  
        // require( block.number > SLAContractPool[msg.sender].curBlockNum + 2*SLAContractPool[msg.sender].blkNeed , "> error");
        uint seed = 0;
        for(uint bi = 0 ; bi<s.SLAContractPool[msg.sender].blkNeed ; bi++)
            seed += (uint)(blockhash(s.SLAContractPool[msg.sender].curBlockNum + bi + 1 ));
        
        uint wcounter = 0;
        while(wcounter < _N){
            address sAddr = s.witnessAddrs[seed % s.witnessAddrs.length];
            
            if(s.witnessPool[sAddr].state == WState.Online && s.witnessPool[sAddr].reputation > 0
               && sAddr != _provider && sAddr != _customer)
            {
                s.witnessPool[sAddr].state = WState.Candidate;
                s.witnessPool[sAddr].confirmDeadline = block.timestamp + 5 minutes;   /// 5 minutes for confirmation
                s.witnessPool[sAddr].SLAContract = msg.sender;
                emit WitnessSelected(sAddr, s.witnessPool[sAddr].index, msg.sender);
                s.onlineCounter--;
                wcounter++;
            }
            
            seed = (uint)(keccak256(abi.encodePacked(seed)));
        }
        
        ///make this interface cannot be invoked twice without 'request'
        s.SLAContractPool[msg.sender].curBlockNum = 0;
        return true;
    }





    


     /**
     * Contract Interface::
     * Decrease the reputation value. 
     * */
    // function reputationDecrease(address _witness, int8 _value)
    //     public
    //     checkWitness(_witness)
    //     checkSLAContract(msg.sender)
    // {
    //     ////only able to release in Busy state
    //     require( _value > 0 );
        
    //     ////only the SLA contract can operate on it.
    //     require(s.witnessPool[_witness].SLAContract == msg.sender);
        
    //     s.witnessPool[_witness].reputation -= _value;
        
    // }

     ///Ddecrease or Increase the provider reputation
    // function setProviderReputation(address _provider, int8 _value)
    // public
    // checkSLAContract(msg.sender)
    // {
    //     s.providerPool[_provider].reputation += _value;
    //     emit ProviderReputation(msg.sender, block.timestamp, _value, _provider);
    // }




}