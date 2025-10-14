// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Just reward to masternodes which is created from 2025/05/13 15:00:00 to 2025/05/30 15:00:00
contract MasterNodeSubsidy {
    event MNSubsidy(uint[] mnIDs);

    function subsidy(uint[] memory _mnIDs, address[] memory _creators, uint[] memory _amounts) public payable {
        require((_mnIDs.length == _creators.length) &&
                (_mnIDs.length == _amounts.length), "invalid params");

        for(uint i; i < _mnIDs.length; i++) {
            if(_creators[i] == address(0) || _amounts[i] == 0) {
                revert("zero address or zero amount");
            }
            payable(_creators[i]).transfer(_amounts[i]);
        }
        emit MNSubsidy(_mnIDs);
    }
}