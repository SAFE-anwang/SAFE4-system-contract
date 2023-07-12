// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SystemTest.sol";
import "./utils/AddressUtil.sol";

contract SystemReward is ISystemReward {
    SystemTest test;

    constructor(SystemTest _test) {
        test = _test;
        test.setSystemReward(address(this));
    }

    function reward(address _snAddr, uint _snAmount, address _mnAddr, uint _mnAmount) public payable {
        require(test.isSN(msg.sender), "caller isn't supernode");
        require(test.isSN(_snAddr), "invalid supernode");
        require(test.isMN(_mnAddr), "invalid masternode");
        require(_snAmount > 0, "invalid supernode reward");
        require(_mnAmount > 0, "invalid masternode reward");
        require(_snAmount + _mnAmount == msg.value, "invalid amount");
        console.log("total: %s", msg.value);
        console.log("snAddr: %s, snAmount: %s", _snAddr, _snAmount);
        console.log("mnAddr: %s, mnAmount: %s", _mnAddr, _mnAmount);
        test.getSuperNode().reward{value: _snAmount}(_snAddr);
        test.getMasterNode().reward{value: _mnAmount}(_mnAddr);
    }
}