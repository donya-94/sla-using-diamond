pragma solidity ^0.8.0;

import "hardhat/console.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import "../libraries/AppStorage.sol";

contract SortitionFacet {

    
    AppStorage internal s;

    event WitnessSelected(address indexed _who, uint _index, address _forWhom);

    function returnTime() external view
    {
       console.log('ReportTimeWin is: ', s.ReportTimeWin); 
    }

    /**
     * Contract Interface::
     * This is for SLA contract to submit a committee sortition request.
     * _blkNeed: This is a number to specify how many blocks needed in the future for the committee sortition. 
     *            Its range should be 2~255. The recommended value is 12.  
     * */
    // function request(address slaContractAddr)
    //     public 
    //     returns
    //     (bool success)
    // {
    //     require(msg.sender == s.Provider , "msg.sender is not Provider");
    //     require(s.SLAContractPool[slaContractAddr].valid , "sla contract is not valid");
    //     console.log('msg.sender is:', msg.sender);
    //     console.log('s.Provider is:', s.Provider);
    //     ////record current block number
    //     s.SLAContractPool[slaContractAddr].curBlockNum = block.number;
    //     s.SLAContractPool[slaContractAddr].blkNeed = s.BlkNeeded;
    //     return true;
    // }
    
    





    


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