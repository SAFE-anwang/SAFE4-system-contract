// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccountRecord.sol";
import "./AccountHistory.sol";
import "../utils/IDUtil.sol";

contract AccountManager {

    using AccountRecord for AccountRecord.Data;
    using AccountHistory for AccountHistory.Data;

    uint id; // record id
    mapping(address => AccountRecord.Data[]) addr2records;
    mapping(uint => uint) id2index;
    mapping(uint => address) id2owner;

    mapping(address => AccountHistory.Data[]) addr2historys;

    // deposit
    function deposit() public payable returns (uint) {
        require(msg.value > 0, "invalid amount");
        id++;
        addRecord(msg.sender, id, msg.value, 0, 0);
        id2index[id] = addr2records[msg.sender].length - 1;
        addHistory(msg.sender, 1, id, msg.value);
        return id;
    }

    // deposit with lock
    function deposit(uint _lockHeight) public payable returns (uint) {
        require(msg.value > 0, "invalid amount");
        id++;
        addRecord(msg.sender, id, msg.value, block.number + 1, block.number + 1 + _lockHeight);
        addHistory(msg.sender, 1, id, msg.value);
        return id;
    }

    // deposit to address
    function deposit(address _to) public payable returns (uint) {
        require(msg.value > 0, "invalid amount");
        id++;
        addRecord(_to, id, msg.value, 0, 0);
        addHistory(_to, 1, id, msg.value);
        return id;
    }

    // deposit to address with lock
    function deposit(address _to, uint _lockHeight) public payable returns (uint) {
        require(msg.value > 0, "invalid amount");
        id++;
        addRecord(_to, id, msg.value, block.number + 1, block.number + 1 + _lockHeight);
        addHistory(_to, 1, id, msg.value);
        return id;
    }

    // withdraw all
    function withdraw() public returns (uint) {
        uint amount = 0;
        uint[] memory ids;
        (amount, ids) = getAvailableAmount();
        if(amount == 0) {
            return amount;
        }

        payable(msg.sender).transfer(amount);

        // update record & history
        for(uint i = 0; i < ids.length; i++) {
            AccountRecord.Data memory record = getRecordByID(ids[i]);
            addHistory(msg.sender, 2, ids[i], record.amount);
            delRecord(ids[i]);
        }

        return amount;
    }

    // withdraw by specify amount
    function withdraw(uint _amount) public returns(uint) {
        require(_amount > 0, "invalid amount");
        uint amount = 0;
        uint[] memory ids;
        (amount, ids) = getAvailableAmount();
        if(amount < _amount) {
            return amount;
        }

        payable(msg.sender).transfer(_amount);

        // update record & history
        AccountRecord.Data[] memory temp_records = new AccountRecord.Data[](ids.length);
        for(uint i = 0; i < ids.length; i++) {
            temp_records[i] = addr2records[msg.sender][id2index[ids[i]]];
        }
        sortByAmount(temp_records, 0, temp_records.length - 1);
        uint usedAmount = 0;
        for(uint i = 0; i < temp_records.length; i++) {
            usedAmount += temp_records[i].amount;
            if(usedAmount <= _amount) {
                delRecord(temp_records[i].id);
                addHistory(msg.sender, 2, temp_records[i].id, temp_records[i].amount);
                if(usedAmount == _amount) {
                    break;
                }
            } else {
                updateRecordAmount(temp_records[i].id, usedAmount - _amount);
                addHistory(msg.sender, 2, temp_records[i].id, temp_records[i].amount - usedAmount - _amount);
                break;
            }
        }

        return amount;
    }

    // get total amount
    function getTotalAmount() public view returns (uint, uint[] memory) {
        AccountRecord.Data[] memory records = addr2records[msg.sender];
        uint amount = 0;
        uint[] memory ids = new uint[](records.length);
        for(uint i = 0; i < records.length; i++) {
            amount += records[i].amount;
            ids[i] = records[i].id;
        }
        return (amount, ids);
    }

    // get avaiable amount
    function getAvailableAmount() public view returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord.Data[] memory records = addr2records[msg.sender];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight) {
                count++;
            }
        }

        // get avaiable amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight) {
                amount += records[i].amount;
                ids[index++] = records[i].id;
            }
        }
        return (amount, ids);
    }

    // get locked amount
    function getLockAmount() public view returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord.Data[] memory records = addr2records[msg.sender];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight) {
                count++;
            }
        }

        // get locked amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].unlockHeight) {
                amount += records[i].amount;
                ids[index++] = records[i].id;
            }
        }
        return (amount, ids);
    }

    // get account
    function getAccount() public view returns (AccountRecord.Data[] memory) {
        return addr2records[msg.sender];
    }

    /************************************************** internal **************************************************/
    // get record by id
    function getRecordByID(uint _id) internal view returns (AccountRecord.Data memory) {
        return addr2records[msg.sender][id2index[_id]];
    }

    // add record
    function addRecord(address _addr, uint _id, uint _amount, uint _startHeight, uint _unlockHeight) internal {
        AccountRecord.Data memory record;
        record.create(_id, _amount, _startHeight, _unlockHeight);
        AccountRecord.Data[] storage records = addr2records[_addr];
        records.push(record);
        id2index[_id] = records.length - 1;
        id2owner[_id] = _addr;
    }

    // delete record
    function delRecord(uint _id) internal {
        AccountRecord.Data[] storage records = addr2records[msg.sender];
        uint pos = id2index[_id];
        /*
        for(uint i = pos; i < records.length; i++) {
            records[i] = records[i + 1];
            id2index[records[i].id] = i;
        }
        records.pop();
        delete id2index[_id];
        */
        records[pos] = records[records.length - 1];
        records.pop();
        id2index[records[pos].id] = pos;
        delete id2index[_id];
        delete id2owner[_id];
    }

    // add history
    function addHistory(address _addr, uint _flag, uint _id, uint _amount) internal {
        AccountHistory.Data memory history;
        history.create(_flag, _id, _amount);
        AccountHistory.Data[] storage historys = addr2historys[_addr];
        historys.push(history);
    }

    // update amount
    function updateRecordAmount(uint _id, uint _amount) internal {
        AccountRecord.Data[] storage records = addr2records[msg.sender];
        records[id2index[_id]].setAmount(_amount);
    }

    // sort by amount
    function sortByAmount(AccountRecord.Data[] memory _arr, uint _left, uint _right) internal pure {
        uint i = _left;
        uint j = _right;
        if (i == j) return;
        AccountRecord.Data memory middle = _arr[_left + (_right - _left) / 2];
        while(i <= j) {
            while(_arr[i].amount < middle.amount) i++;
            while(middle.amount < _arr[j].amount && j > 0) j--;
            if(i <= j) {
                (_arr[i], _arr[j]) = (_arr[j], _arr[i]);
                i++;
                if(j != 0) j--;
            }
        }
        if(_left < j)
            sortByAmount(_arr, _left, j);
        if(i < _right)
            sortByAmount(_arr, i, _right);
    }
}   