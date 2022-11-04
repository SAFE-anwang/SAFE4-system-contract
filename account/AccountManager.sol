// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccountRecord.sol";
import "./AccountHistory.sol";
import "../SafeProperty.sol";
import "../utils/SafeMath.sol";

contract AccountManager {
    using SafeMath for uint;
    using BytesUtil for bytes;
    using AccountRecord for AccountRecord.Data;
    using AccountHistory for AccountHistory.Data;

    uint internal counter;
    SafeProperty internal property;

    mapping(address => AccountRecord.Data[]) addr2records;
    mapping(bytes20 => uint) id2index;
    mapping(bytes20 => address) id2owner;

    mapping(address => AccountHistory.Data[]) addr2historys;

    uint UNKNOW_TYPE = 0;
    uint DEPOSIT_TYPE = 1;
    uint DEPOSIT_LOCK_TYPE = 2;
    uint WITHDRAW_TYPE = 3;
    uint TRANSFER_TYPE = 4;
    uint TRANSFER_LOCK_TYPE = 5;
    uint REWARD_TYPE = 6;

    event SafeDeposit(address _addr, uint _amount, uint _lockDay, string _msg);
    event SafeWithdraw(address _addr, uint _amount, string _msg);
    event SafeTransfer(address _addr, address _to, uint _amount, uint _lockDay, string _msg);

    constructor(SafeProperty _property) {
        counter = 1;
        property = _property;
    }

    // deposit
    function deposit(address _to, uint _amount) public returns (bytes20) {
        return deposit(_to, _amount, 0);
    }

    // deposit with lock
    function deposit(address _to, uint _amount, uint _lockDay) public returns (bytes20) {
        require(_to != address(0), "deposit to the zero address");
        require(_amount > 0, "invalid amount");
        bytes20 recordID;
        if(_lockDay == 0) {
            recordID = addRecord(_to, _amount, 0, 0, 0);
            if(recordID != 0) {
                addHistory(_to, recordID, _amount, DEPOSIT_TYPE);
                emit SafeDeposit(_to, _amount, _lockDay, "deposit successfully");
            } else {
                emit SafeDeposit(_to, _amount, _lockDay, "deposit failed");
            }
        } else {
            recordID = addRecord(_to, _amount, _lockDay, block.number, block.number + _lockDay.mul(86400).div(property.getProperty("block_space").value.toUint()));
            if(recordID != 0) {
                addHistory(_to, recordID, _amount, DEPOSIT_LOCK_TYPE);
                emit SafeDeposit(_to, _amount, _lockDay, "deposit with lock successfully");
            } else {
                emit SafeDeposit(_to, _amount, _lockDay, "deposit with lock failed");
            }
        }
        return recordID;
    }

    // withdraw all
    function withdraw(address _from) public returns (uint) {
        require(_from != address(0), "withdraw from the zero address");
        uint amount = 0;
        bytes20[] memory recordIDs;
        (amount, recordIDs) = getAvailableAmount(_from);
        return withdraw(_from, recordIDs);
    }

    // withdraw by specify amount
    function withdraw(address _from, bytes20[] memory _recordIDs) public returns(uint) {
        require(_from != address(0), "withdraw from the zero address");
        require(_recordIDs.length > 0, "invalid record id");
        uint amount = 0;
        for(uint i = 0; i < _recordIDs.length; i++) {
            AccountRecord.Data memory record = getRecordByID(_from, _recordIDs[i]);
            if(block.number < record.unlockHeight) {
                continue;
            }
            amount += record.amount;
            addHistory(_from, _recordIDs[i], record.amount, WITHDRAW_TYPE);
            delRecord(_recordIDs[i]);
        }
        if(amount == 0) {
            emit SafeWithdraw(_from, amount, "withdraw failed: insufficient available amount");
        } else {
            payable(_from).transfer(amount);
            emit SafeWithdraw(_from, amount, "withdraw successfully");
        }
        return amount;
    }

    function transfer(address _from, address _to, uint _amount) public returns (bytes20) {
        return transferLock(_from, _to, _amount, 0);
    }

    function transferLock(address _from, address _to, uint _amount, uint _lockDay) public returns (bytes20) {
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        require(_amount > 0, "invalid amount");

        uint amount = 0;
        bytes20[] memory recordIDs;
        (amount, recordIDs) = getAvailableAmount(_from);
        require(amount >= _amount, "insufficient balance");

        // update record & history
        AccountRecord.Data[] memory temp_records = new AccountRecord.Data[](recordIDs.length);
        for(uint i = 0; i < recordIDs.length; i++) {
            temp_records[i] = addr2records[msg.sender][id2index[recordIDs[i]]];
        }
        sortByAmount(temp_records, 0, temp_records.length - 1);
        uint usedAmount = 0;
        for(uint i = 0; i < temp_records.length; i++) {
            usedAmount += temp_records[i].amount;
            if(usedAmount <= _amount) {
                delRecord(temp_records[i].id);
                addHistory(msg.sender, temp_records[i].id, temp_records[i].amount, TRANSFER_TYPE);
                if(usedAmount == _amount) {
                    break;
                }
            } else {
                updateRecordAmount(temp_records[i].id, usedAmount - _amount);
                addHistory(msg.sender, temp_records[i].id, temp_records[i].amount - usedAmount - _amount, TRANSFER_TYPE);
                break;
            }
        }

        bytes20 recordID;
        if(_lockDay == 0) {
            recordID = addRecord(_to, _amount, 0, 0, 0);
            if(recordID != 0) {
                addHistory(_to, recordID, _amount, TRANSFER_TYPE);
                emit SafeTransfer(_from, _to, amount, _lockDay, "transfer successfully");
            } else {
                emit SafeTransfer(_from, _to, amount, _lockDay, "transfer failed");
            }
        } else {
            recordID = addRecord(_to, _amount, _lockDay, block.number, block.number + _lockDay.mul(86400).div(property.getProperty("block_space").value.toUint()));
            if(recordID != 0) {
                addHistory(_to, recordID, _amount, TRANSFER_LOCK_TYPE);
                emit SafeTransfer(_from, _to, amount, _lockDay, "transfer with lock successfully");
            } else {
                emit SafeTransfer(_from, _to, amount, _lockDay, "transfer with lock failed");
            }
        }
        return recordID;
    }

    function reward(address _to, uint _amount) public returns (bytes20) {
        require(_to != address(0), "reward to the zero address");
        require(_amount > 0, "invalid amount");
        bytes20 recordID = addRecord(_to, _amount, 0, 0, 0);
        if(recordID != 0) {
            addHistory(_to, recordID, _amount, REWARD_TYPE);
        }
        return recordID;
    }

    // get total amount
    function getTotalAmount(address _addr) public view returns (uint, bytes20[] memory) {
        AccountRecord.Data[] memory records = addr2records[_addr];
        uint amount = 0;
        bytes20[] memory recordIDs = new bytes20[](records.length);
        for(uint i = 0; i < records.length; i++) {
            amount += records[i].amount;
            recordIDs[i] = records[i].id;
        }
        return (amount, recordIDs);
    }

    // get avaiable amount
    function getAvailableAmount(address _addr) public view returns (uint, bytes20[] memory) {
        uint curHeight = block.number;
        AccountRecord.Data[] memory records = addr2records[_addr];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight) {
                count++;
            }
        }

        // get avaiable amount and id list
        bytes20[] memory recordIDs = new bytes20[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight) {
                amount += records[i].amount;
                recordIDs[index++] = records[i].id;
            }
        }
        return (amount, recordIDs);
    }

    // get locked amount
    function getLockAmount(address _addr) public view returns (uint, bytes20[] memory) {
        uint curHeight = block.number;
        AccountRecord.Data[] memory records = addr2records[_addr];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight) {
                count++;
            }
        }

        // get locked amount and id list
        bytes20[] memory recordIDs = new bytes20[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].unlockHeight) {
                amount += records[i].amount;
                recordIDs[index++] = records[i].id;
            }
        }
        return (amount, recordIDs);
    }

    // get account records
    function getAccountRecords(address _addr) public view returns (AccountRecord.Data[] memory) {
        return addr2records[_addr];
    }

    function setUseHeight(bytes20 _recordID, uint _height) public {
        addr2records[id2owner[_recordID]][id2index[_recordID]].setUseHeight(_height);
    }

    /************************************************** internal **************************************************/
    // get record by id
    function getRecordByID(address _addr, bytes20 _recordID) public view returns (AccountRecord.Data memory) {
        return addr2records[_addr][id2index[_recordID]];
    }

    // add record
    function addRecord(address _addr, uint _amount, uint _lockDay, uint _startHeight, uint _unlockHeight) internal returns (bytes20) {
        AccountRecord.Data memory record;
        bytes20 recordID = ripemd160(abi.encodePacked(counter++, _addr, _amount, _lockDay, _startHeight, _unlockHeight));
        record.create(recordID, _addr, _amount, _lockDay, _startHeight, _unlockHeight);
        AccountRecord.Data[] storage records = addr2records[_addr];
        records.push(record);
        id2index[recordID] = records.length - 1;
        id2owner[recordID] = _addr;
        return recordID;
    }

    // delete record
    function delRecord(bytes20 _recordID) internal {
        AccountRecord.Data[] storage records = addr2records[msg.sender];
        uint pos = id2index[_recordID];
        records[pos] = records[records.length - 1];
        records.pop();
        id2index[records[pos].id] = pos;
        delete id2index[_recordID];
        delete id2owner[_recordID];
    }

    // add history
    function addHistory(address _addr, bytes20 _recordID, uint _amount, uint _flag) internal {
        AccountHistory.Data memory history;
        history.create(_recordID, _amount, _flag);
        AccountHistory.Data[] storage historys = addr2historys[_addr];
        historys.push(history);
    }

    // update amount
    function updateRecordAmount(bytes20 _reocrdID, uint _amount) internal {
        AccountRecord.Data[] storage records = addr2records[msg.sender];
        records[id2index[_reocrdID]].setAmount(_amount);
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