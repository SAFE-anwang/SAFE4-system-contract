// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccountHistory {
    struct Data {
        uint flag; // deposit(1), withdraw(2) or others(0)
        uint recordID; // account record id
        uint amount;
        uint height;
        uint createTime;
    }

    function create(Data memory _self, uint _flag, uint _id, uint _amount) public view {
        _self.flag = _flag;
        _self.recordID = _id;
        _self.amount = _amount;
        _self.height = block.number;
        _self.createTime = block.timestamp;
    }
}