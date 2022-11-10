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

    function create(bytes20 _recordID, uint _amount, uint _flag) public view returns (Data memory) {
        Data memory data;
        data.recordID = _recordID;
        data.amount = _amount;
        data.flag = _flag;
        data.height = block.number;
        data.time = block.timestamp;
        return data;
    }
}