// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccountRecord {
    struct Data {
        bytes20 id;
        address addr;
        uint amount;
        uint lockDay;
        uint startHeight; // start height
        uint unlockHeight; // unlocked height
        uint createTime;
        uint updateTime;
        uint useHeight; // for voting or regist
    }

    function create(Data memory _self, bytes20 _id, address _addr, uint _amount, uint _lockDay, uint _startHeight, uint _unlockHeight) public view {
        _self.id = _id;
        _self.addr = _addr;
        _self.amount = _amount;
        _self.lockDay = _lockDay;
        _self.startHeight = _startHeight;
        _self.unlockHeight = _unlockHeight;
        _self.createTime = block.timestamp;
        _self.updateTime = 0;
        _self.useHeight = 0;
    }

    function setAmount(Data storage _self, uint _amount) public {
        _self.amount = _amount;
        _self.updateTime = block.timestamp;
    }

    function setUseHeight(Data storage _self, uint _height) internal {
        _self.useHeight = _height;
    }
}