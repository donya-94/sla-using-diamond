// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { AppStorage } from "./libraries/AppStorage.sol";


contract Diamond {  
    AppStorage s;  

    constructor(address _contractOwner, address _diamondCutFacet) payable {        
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet, 
            action: IDiamondCut.FacetCutAction.Add, 
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");

        s.Provider = msg.sender;
        s.Customer = msg.sender;
        s.SLAContractPool[address(this)].valid = true; //this is for initializing not using
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

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facetAddressAndSelectorPosition[msg.sig].facetAddress));
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
             // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}
