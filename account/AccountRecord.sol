// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccountRecord {
    struct BindInfo {
        uint bindHeight;
        uint unbindHeight;
    }

    struct Data {
        bytes20 id;
        address addr;
        uint amount;
        uint lockDay;
        uint startHeight; // start height
        uint unlockHeight; // unlocked height
        uint createTime;
        uint updateTime;
        BindInfo bindInfo; // for voting or regist
    }

    function create(bytes20 _id, address _addr, uint _amount, uint _lockDay, uint _startHeight, uint _unlockHeight) public view returns (Data memory) {
        Data memory data;
        data.id = _id;
        data.addr = _addr;
        data.amount = _amount;
        data.lockDay = _lockDay;
        data.startHeight = _startHeight;
        data.unlockHeight = _unlockHeight;
        data.createTime = block.timestamp;
        data.updateTime = 0;
        data.bindInfo = BindInfo(0, 0);
        return data;
    }

    function setAmount(Data storage _self, uint _amount) public {
        _self.amount = _amount;
        _self.updateTime = block.timestamp;
    }

    function setBindInfo(Data storage _self, uint _bindHeight, uint _unbindHeight) internal {
        _self.bindInfo.bindHeight = _bindHeight;
        _self.bindInfo.unbindHeight = _unbindHeight;
    }
}