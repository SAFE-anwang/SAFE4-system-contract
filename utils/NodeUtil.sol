// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StringUtil.sol";

library NodeUtil {
    using StringUtil for string;

    function check(uint _nodeType, bool _isUnion, address _addr, uint _lockDay, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) internal pure returns (string memory) {
        require(_nodeType == 1 || _nodeType == 2, "invalid node type");
        checkAddress(_addr);
        checkLockDay(_lockDay);
        checkDescription(_nodeType, _description);
        checkIncentive(_nodeType, _isUnion, _creatorIncentive, _partnerIncentive, _voterIncentive);
        return checkEnode(_enode);
    }

    function checkAddress(address _addr) internal pure {
        require(_addr != address(0), "invalid address");
    }

    function checkLockDay(uint _lockDay) internal pure {
        //require(_lockDay >= 720, "lock 2 years at least");
        require(_lockDay >= 5, "lock 5 days at least"); // for test
    }

    function checkDescription(uint _nodeType, string memory _description) internal pure {
        require(bytes(_description).length <= 4096, "invalid description");
        if(_nodeType == 2) {
            require(bytes(_description).length > 0, "description is empty");
        }
    }

    function checkIncentive(uint _nodeType, bool _isUnion, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) internal pure {
        require(_creatorIncentive + _partnerIncentive + _voterIncentive == 100, "total incentive must be 100");
        if(_nodeType == 1) {
            require(_voterIncentive == 0, "masternode don't need voter");
            if(_isUnion) {
                require(_creatorIncentive > 0 && _creatorIncentive <= 50, "creator incentive exceed 50%");
            }
        } else {
            if(_isUnion) {
                require(_creatorIncentive > 0 && _creatorIncentive <= 10, "creator incentive exceed 10%");
                require(_partnerIncentive >= 40 && _partnerIncentive <= 50, "partner incentive is 40% - 50%");
                require(_voterIncentive >= 40 && _voterIncentive <= 50, "creator incentive is 40% - 50%");
            }
        }
    }

    function checkEnode(string memory _enode) internal pure returns (string memory) {
        bytes memory enodeBytes = bytes(_enode);
        require(enodeBytes.length >= 150, "invalid nodeInfo");
        require(enodeBytes[136] == '@');
        require(keccak256(abi.encodePacked(_enode.substring(0, 8))) == keccak256(abi.encodePacked("enode://")), "missing enode://");
        uint count = 0;
        for(uint i = 137; i < enodeBytes.length; i++) {
            if(enodeBytes[i] == ':') {
                break;
            }
            require(enodeBytes[i] == '.' || (enodeBytes[i] >= '0' && enodeBytes[i] <= '9'), "invalid ip of enode");
            count++;
        }
        require(count >= 7 && count <= 15, "invalid ip length of enode");
        bytes memory ipBytes = new bytes(count);
        for(uint i = 0; i < count; i++) {
            ipBytes[i] = enodeBytes[i + 137];
        }
        return string(ipBytes);
    }

    function find(address[] memory _arr, address _addr) internal pure returns (int) {
        for(uint i = 0; i < _arr.length; i++) {
            if(_arr[i] == _addr) {
                return int(i);
            }
        }
        return -1;
    }
}