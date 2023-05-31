// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/IAccountManager.sol";
import "./interfaces/ISNVote.sol";
import "./utils/SafeMath.sol";

contract AccountManager is IAccountManager, System {
    using SafeMath for uint;

    uint record_no; // record no.
    mapping(address => AccountRecord[]) addr2records;
    mapping(uint => uint) id2index;
    mapping(uint => address) id2addr;

    event SafeDeposit(address _addr, uint _amount, uint _lockDay, uint _id);
    event SafeWithdraw(address _addr, uint _amount);
    event SafeTransfer(address _from, address _to, uint _amount, uint _lockDay);

    receive() external payable {}
    fallback() external payable {}

    // deposit
    function deposit(address _to, uint _lockDay) public payable returns (uint) {
        require(msg.value > 0, "invalid amount");
        uint id = addRecord(_to, msg.value, _lockDay);
        emit SafeDeposit(_to, msg.value, _lockDay, id);
        return id;
    }

    // withdraw all
    function withdraw() public returns (uint) {
        uint amount = 0;
        uint[] memory ids;
        (amount, ids) = getAvailableAmount(msg.sender);
        require(amount > 0, "insufficient amount");
        return withdraw(ids);
    }

    // withdraw by specify amount
    function withdraw(uint[] memory _ids) public returns (uint) {
        require(_ids.length > 0, "invalid record ids");
        uint amount = 0;
        for(uint i = 0; i < _ids.length; i++) {
            AccountRecord memory record = getRecordByID(_ids[i]);
            if(block.number >= record.unlockHeight && block.number >= record.unfreezeHeight) {
                amount += record.amount;
            }
        }
        if(amount == 0) {
            emit SafeWithdraw(msg.sender, amount); // insufficient balance
            return 0;
        }
        payable(msg.sender).transfer(amount);
        ISNVote snVote = ISNVote(SNVOTE_PROXY_ADDR);
        for(uint i = 0; i < _ids.length; i++) {
            AccountRecord memory record = getRecordByID(_ids[i]);
            if(block.number >= record.unlockHeight && block.number >= record.unfreezeHeight) {
                delRecord(_ids[i]);
                snVote.removeVote(_ids[i]);
                snVote.removeApproval(_ids[i]);
            }
        }
        emit SafeWithdraw(msg.sender, amount);
        return amount;
    }

    function transfer(address _to, uint _amount, uint _lockDay) public returns (uint) {
        require(_to != address(0), "transfer to the zero address");
        require(_amount > 0, "invalid amount");

        uint amount = 0;
        uint[] memory ids;
        (amount, ids) = getAvailableAmount(msg.sender);
        require(amount >= _amount, "insufficient balance");

        uint id = addRecord(_to, _amount, _lockDay);
        emit SafeTransfer(msg.sender, _to, _amount, _lockDay);

        // update record
        AccountRecord[] memory temp_records = new AccountRecord[](ids.length);
        for(uint i = 0; i < ids.length; i++) {
            temp_records[i] = addr2records[msg.sender][id2index[ids[i]]];
        }
        sortRecordByAmount(temp_records, 0, temp_records.length - 1);
        uint usedAmount = 0;
        ISNVote snVote = ISNVote(SNVOTE_PROXY_ADDR);
        for(uint i = 0; i < temp_records.length; i++) {
            if(usedAmount + temp_records[i].amount <= _amount) {
                delRecord(temp_records[i].id);
                uint tempVoteNum = temp_records[i].amount;
                if(isMN(msg.sender)) {
                    tempVoteNum = temp_records[i].amount.mul(2);
                } else if(temp_records[i].unlockHeight != 0) {
                    tempVoteNum = temp_records[i].amount.mul(15).div(10);
                }
                snVote.decreaseRecord(temp_records[i].id, temp_records[i].amount, tempVoteNum);
                usedAmount += temp_records[i].amount;
                if(usedAmount == _amount) {
                    break;
                }
            } else {
                addr2records[msg.sender][id2index[temp_records[i].id]].amount = usedAmount + temp_records[i].amount - _amount;
                addr2records[msg.sender][id2index[temp_records[i].id]].updateHeight = block.number;
                uint tempVoteAmount = _amount - usedAmount;
                uint tempVoteNum = tempVoteAmount;
                if(isMN(msg.sender)) {
                    tempVoteNum = tempVoteAmount.mul(2);
                } else if(temp_records[i].unlockHeight != 0) {
                    tempVoteNum = tempVoteNum.mul(15).div(10);
                }
                snVote.decreaseRecord(temp_records[i].id, tempVoteAmount, tempVoteNum);
                break;
            }
        }
        return id;
    }

    function reward(address _to) public payable returns (uint) {
        require(_to != address(0), "reward to the zero address");
        require(msg.value > 0, "invalid amount");
        return addRecord(_to, msg.value, 0);
    }

    function freeze(uint _id, uint _day) public {
        require(existRecord(_id), "invalid record id");
        AccountRecord storage record = addr2records[id2addr[_id]][id2index[_id]];
        if(_day == 0) {
            record.freezeHeight = 0;
            record.unfreezeHeight = 0;
        } else {
            record.freezeHeight = block.number + 1;
            record.unfreezeHeight = block.number + _day.mul(86400).div(getPropertyValue("block_space"));
        }
        record.updateHeight = block.number;
    }

    // get total amount
    function getTotalAmount(address _addr) public view returns (uint, uint[] memory) {
        AccountRecord[] memory records = addr2records[_addr];
        uint amount = 0;
        uint[] memory ids = new uint[](records.length);
        for(uint i = 0; i < records.length; i++) {
            amount += records[i].amount;
            ids[i] = records[i].id;
        }
        return (amount, ids);
    }

    // get avaiable amount
    function getAvailableAmount(address _addr) public view returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[_addr];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight && curHeight >= records[i].unfreezeHeight) {
                count++;
            }
        }

        // get avaiable amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight && curHeight >= records[i].unfreezeHeight) {
                amount += records[i].amount;
                ids[index++] = records[i].id;
            }
        }
        return (amount, ids);
    }

    // get locked amount
    function getLockAmount(address _addr) public view returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[_addr];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].unlockHeight) {
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

    // get bind amount
    function getFreezeAmount(address _addr) public view returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[_addr];

        // get avaiable count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].unfreezeHeight) {
                count++;
            }
        }

        // get locked amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < records[i].unfreezeHeight) {
                amount += records[i].amount;
                ids[index++] = records[i].id;
            }
        }
        return (amount, ids);
    }

    // get account records
    function getRecords(address _addr) public view returns (AccountRecord[] memory) {
        return addr2records[_addr];
    }

    // get record by id
    function getRecordByID(uint _id) public view returns (AccountRecord memory) {
        return addr2records[id2addr[_id]][id2index[_id]];
    }

    function existRecord(uint _id) internal view returns (bool) {
        return id2addr[_id] == msg.sender;
    }

    // add record
    function addRecord(address _addr, uint _amount, uint _lockDay) internal returns (uint) {
        uint startHeight = 0;
        uint unlockHeight = 0;
        if(_lockDay > 0) {
            startHeight = block.number + 1;
            unlockHeight = startHeight + _lockDay.mul(86400).div(getPropertyValue("block_space"));
        }
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_addr];
        records.push(AccountRecord(id, _addr, _amount, _lockDay, startHeight, unlockHeight, 0, 0, block.number, 0));
        id2index[id] = records.length - 1;
        id2addr[id] = _addr;
        return id;
    }

    // delete record
    function delRecord(uint _id) internal {
        require(existRecord(_id), "invalid record id");
        AccountRecord[] storage records = addr2records[msg.sender];
        uint pos = id2index[_id];
        records[pos] = records[records.length - 1];
        records.pop();
        if(records.length != 0) {
            id2index[records[pos].id] = pos;
        }
        delete id2index[_id];
        delete id2addr[_id];
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