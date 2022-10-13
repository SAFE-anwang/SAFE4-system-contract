// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccountRecord {
    struct Data {
        uint id;
        uint amount;
        uint startHeight; // start height
        uint unlockHeight; // unlocked height
        uint createTime;
        uint updateTime;
    }

    function create(Data memory _self, uint _id, uint _amount, uint _start, uint _unlock) public view {
        _self.id = _id;
        _self.amount = _amount;
        _self.startHeight = _start;
        _self.unlockHeight = _unlock;
        _self.createTime = block.timestamp;
        _self.updateTime = 0;
    }

    function setAmount(Data storage _self, uint _amount) public {
        _self.amount = _amount;
        _self.updateTime = block.timestamp;
    }
}