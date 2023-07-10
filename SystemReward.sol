// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";

contract SystemReward is ISystemReward, System {
    function reward(address _snAddr, uint _snAmount, address _mnAddr, uint _mnAmount) public payable onlySN {
        require(isSN(msg.sender), "caller isn't supernode");
        require(isSN(_snAddr), "invalid supernode");
        require(isMN(_mnAddr), "invalid masternode");
        require(_snAmount > 0, "invalid supernode reward");
        require(_mnAmount > 0, "invalid masternode reward");
        require(_snAmount + _mnAmount == msg.value, "invalid amount");
        getSuperNode().reward{value: _snAmount}(_snAddr);
        getMasterNode().reward{value: _mnAmount}(_mnAddr);
    }
}