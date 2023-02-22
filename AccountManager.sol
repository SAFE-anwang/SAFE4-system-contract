// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/IAccountManager.sol";
import "./interfaces/ISMNVote.sol";
import "./utils/SafeMath.sol";

contract AccountManager is IAccountManager, System {
    using SafeMath for uint;

    uint record_no; // record no.
    mapping(address => AccountRecord[]) addr2records;
    mapping(bytes20 => uint) recordID2index;
    mapping(bytes20 => address) recordID2addr;

    event SafeDeposit(address _addr, uint _amount, uint _lockDay, bytes20 _reocrdID);
    event SafeWithdraw(address _addr, uint _amount);
    event SafeTransfer(address _from, address _to, uint _amount, uint _lockDay);

    receive() external payable {}
    fallback() external payable {}

    // deposit
    function deposit(address _to, uint _lockDay) public payable returns (bytes20) {
        require(msg.value > 0, "invalid amount");
        bytes20 recordID = addRecord(_to, msg.value, _lockDay, block.number, block.number + _lockDay.mul(86400).div(getPropertyValue("block_space")));
        emit SafeDeposit(_to, msg.value, _lockDay, recordID);
        return recordID;
    }

    // withdraw all
    function withdraw() public returns (uint) {
        uint amount = 0;
        bytes20[] memory recordIDs;
        (amount, recordIDs) = getAvailableAmount();
        require(amount > 0, "insufficient amount");
        return withdraw(recordIDs);
    }

    // withdraw by specify amount
    function withdraw(bytes20[] memory _recordIDs) public returns (uint) {
        require(_recordIDs.length > 0, "invalid record id");
        uint amount = 0;
        for(uint i = 0; i < _recordIDs.length; i++) {
            AccountRecord memory record = getRecordByID(_recordIDs[i]);
            if(block.number <= record.unlockHeight || block.number <= record.bindInfo.unbindHeight) {
                continue;
            }
            amount += record.amount;
        }
        if(amount == 0) {
            emit SafeWithdraw(msg.sender, amount); // insufficient balance
            return 0;
        }
        payable(msg.sender).transfer(amount);
        ISMNVote smnVote = ISMNVote(SMNVOTE_PROXY_ADDR);
        for(uint i = 0; i < _recordIDs.length; i++) {
            AccountRecord memory record = getRecordByID(_recordIDs[i]);
            if(block.number < record.unlockHeight || block.number <= record.bindInfo.unbindHeight) {
                continue;
            }
            delRecord(_recordIDs[i]);
            smnVote.removeVote(_recordIDs[i]);
            smnVote.removeApproval(_recordIDs[i]);
        }
        emit SafeWithdraw(msg.sender, amount);
        return amount;
    }

    function transfer(address _to, uint _amount, uint _lockDay) public returns (bytes20) {
        require(_to != address(0), "transfer to the zero address");
        require(_amount > 0, "invalid amount");

        uint amount = 0;
        bytes20[] memory recordIDs;
        (amount, recordIDs) = getAvailableAmount();
        require(amount >= _amount, "insufficient balance");

        bytes20 recordID = addRecord(_to, _amount, _lockDay, block.number, block.number + _lockDay.mul(86400).div(getPropertyValue("block_space")));
        emit SafeTransfer(msg.sender, _to, _amount, _lockDay);

        // update record
        AccountRecord[] memory temp_records = new AccountRecord[](recordIDs.length);
        for(uint i = 0; i < recordIDs.length; i++) {
            temp_records[i] = addr2records[msg.sender][recordID2index[recordIDs[i]]];
        }
        sortRecordByAmount(temp_records, 0, temp_records.length - 1);
        uint usedAmount = 0;
        ISMNVote smnVote = ISMNVote(SMNVOTE_PROXY_ADDR);
        for(uint i = 0; i < temp_records.length; i++) {
            if(usedAmount + temp_records[i].amount <= _amount) {
                delRecord(temp_records[i].id);
                smnVote.removeVote(temp_records[i].id);
                smnVote.removeApproval(temp_records[i].id);
                usedAmount += temp_records[i].amount;
                if(usedAmount == _amount) {
                    break;
                }
            } else {
                addr2records[msg.sender][recordID2index[temp_records[i].id]].amount = usedAmount + temp_records[i].amount - _amount;
                addr2records[msg.sender][recordID2index[temp_records[i].id]].updateHeight = block.number;
                uint tempVoteAmount = _amount - usedAmount;
                uint tempVoteNum = 0;
                if(isMN(msg.sender)) {
                    tempVoteNum = tempVoteAmount.mul(2);
                } else if(temp_records[i].unlockHeight != 0) {
                    tempVoteNum = tempVoteNum.mul(15).div(10);
                } else {
                    tempVoteNum = tempVoteAmount;
                }
                smnVote.DecreaseVoteNum(temp_records[i].id, tempVoteAmount, tempVoteNum);
                smnVote.DecreaseApprovalNum(temp_records[i].id, tempVoteAmount, tempVoteNum);
                break;
            }
        }
        return recordID;
    }

    function reward(address _to, uint8 _rewardType) public payable returns (bytes20) {
        require(_to != address(0), "reward to the zero address");
        require(msg.value > 0, "invalid amount");
        require(_rewardType == 6 || _rewardType == 7, "invalid reward type, only 6(masternode reward), 7(supermasternode reward)");
        return addRecord(_to, msg.value, 0, block.number, block.number);
    }

    function setBindDay(bytes20 _recordID, uint _bindDay) public {
        require(existRecord(_recordID), "invalid record id");
        AccountRecord storage record = addr2records[recordID2addr[_recordID]][recordID2index[_recordID]];
        record.bindInfo.bindHeight = block.number;
        record.bindInfo.unbindHeight = block.number + _bindDay.mul(86400).div(getPropertyValue("block_space"));
        record.updateHeight = block.number;
    }

    // get total amount
    function getTotalAmount() public view returns (uint, bytes20[] memory) {
        AccountRecord[] memory records = addr2records[msg.sender];
        uint amount = 0;
        bytes20[] memory recordIDs = new bytes20[](records.length);
        for(uint i = 0; i < records.length; i++) {
            amount += records[i].amount;
            recordIDs[i] = records[i].id;
        }
        return (amount, recordIDs);
    }

    // get avaiable amount
    function getAvailableAmount() public view returns (uint, bytes20[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[msg.sender];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight > records[i].unlockHeight && curHeight > records[i].bindInfo.unbindHeight) {
                count++;
            }
        }

        // get avaiable amount and id list
        bytes20[] memory recordIDs = new bytes20[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight > records[i].unlockHeight && curHeight > records[i].bindInfo.unbindHeight) {
                amount += records[i].amount;
                recordIDs[index++] = records[i].id;
            }
        }
        return (amount, recordIDs);
    }

    // get locked amount
    function getLockAmount() public view returns (uint, bytes20[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[msg.sender];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].unlockHeight) {
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

    // get bind amount
    function getBindAmount() public view returns (uint, bytes20[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[msg.sender];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].bindInfo.unbindHeight) {
                count++;
            }
        }

        // get locked amount and id list
        bytes20[] memory recordIDs = new bytes20[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].bindInfo.unbindHeight) {
                amount += records[i].amount;
                recordIDs[index++] = records[i].id;
            }
        }
        return (amount, recordIDs);
    }

    // get account records
    function getRecords() public view returns (AccountRecord[] memory) {
        return addr2records[msg.sender];
    }

    // get record by id
    function getRecordByID(bytes20 _recordID) public view returns (AccountRecord memory) {
        require(existRecord(_recordID), "invalid record id");
        return addr2records[msg.sender][recordID2index[_recordID]];
    }

    function existRecord(bytes20 _recordID) internal view returns (bool) {
        return recordID2addr[_recordID] != address(0);
    }

    // add record
    function addRecord(address _addr, uint _amount, uint _lockDay, uint _startHeight, uint _unlockHeight) internal returns (bytes20) {
        bytes20 recordID = ripemd160(abi.encodePacked(++record_no, _addr, _amount, _lockDay, _startHeight, _unlockHeight));
        AccountRecord[] storage records = addr2records[_addr];
        records.push(AccountRecord(recordID, _addr, _amount, _lockDay, _startHeight, _unlockHeight, BindInfo(0, 0), block.number, 0));
        recordID2index[recordID] = records.length - 1;
        recordID2addr[recordID] = _addr;
        return recordID;
    }

    // delete record
    function delRecord(bytes20 _recordID) internal {
        require(existRecord(_recordID), "invalid record id");
        AccountRecord[] storage records = addr2records[msg.sender];
        uint pos = recordID2index[_recordID];
        records[pos] = records[records.length - 1];
        records.pop();
        if(records.length != 0) {
            recordID2index[records[pos].id] = pos;
        }
        delete recordID2index[_recordID];
        delete recordID2addr[_recordID];
    }

    // sort by amount
    function sortRecordByAmount(AccountRecord[] memory _arr, uint _left, uint _right) internal pure {
        uint i = _left;
        uint j = _right;
        if (i == j) return;
        AccountRecord memory middle = _arr[_left + (_right - _left) / 2];
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
            sortRecordByAmount(_arr, _left, j);
        if(i < _right)
            sortRecordByAmount(_arr, i, _right);
    }
}