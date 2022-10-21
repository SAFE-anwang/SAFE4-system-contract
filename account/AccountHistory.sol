// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccountHistory {
    struct Data {
        bytes20 recordID; // account record id
        uint amount;
        uint flag; // deposit(1), withdraw(2) or others(0)
        uint height;
        uint time;
    }

    function create(Data memory _self, bytes20 _id, uint _amount, uint _flag) public view {
        _self.recordID = _id;
        _self.amount = _amount;
        _self.flag = _flag;
        _self.height = block.number;
        _self.time = block.timestamp;
    }
}