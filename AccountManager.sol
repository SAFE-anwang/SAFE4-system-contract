// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/IAccountManager.sol";
import "./interfaces/ISNVote.sol";
import "./utils/SafeMath.sol";

contract AccountManager is IAccountManager, System {
    using SafeMath for uint;

    mapping(address => uint) balances;

    uint record_no; // record no.
    mapping(address => AccountRecord[]) addr2records;
    mapping(uint => uint) id2index;
    mapping(uint => address) id2addr;
    mapping(uint => RecordUseInfo) id2useinfo;

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
            if(_ids[i] == 0) {
                amount += balances[msg.sender];
            } else {
                AccountRecord memory record = getRecordByID(_ids[i]);
                RecordUseInfo memory useinfo = id2useinfo[_ids[i]];
                if(record.addr == msg.sender && block.number >= record.unlockHeight && block.number >= useinfo.unfreezeHeight) {
                    amount += record.amount;
                }
            }
        }
        if(amount != 0) {
            payable(msg.sender).transfer(amount);
            ISNVote snVote = ISNVote(SNVOTE_PROXY_ADDR);
            for(uint i = 0; i < _ids.length; i++) {
                if(_ids[i] != 0) {
                    AccountRecord memory record = getRecordByID(_ids[i]);
                    RecordUseInfo memory useinfo = id2useinfo[_ids[i]];
                    if(record.addr == msg.sender && block.number >= record.unlockHeight && block.number >= useinfo.unfreezeHeight) {
                        delRecord(_ids[i]);
                        snVote.removeVoteOrApproval(_ids[i]);
                    }
                } else {
                    balances[msg.sender] = 0;
                }
            }
        }
        emit SafeWithdraw(msg.sender, amount, _ids);
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
        emit SafeTransfer(msg.sender, _to, _amount, _lockDay, id);

        // update record
        AccountRecord[] memory temp_records = new AccountRecord[](ids.length);
        for(uint i = 0; i < ids.length; i++) {
            if(ids[i] != 0) {
                temp_records[i] = addr2records[msg.sender][id2index[ids[i]]];
            } else {
                temp_records[i] = AccountRecord(0, msg.sender, balances[msg.sender], 0, 0, 0);
            }
        }
        sortRecordByAmount(temp_records, 0, temp_records.length - 1);
        uint usedAmount = 0;
        ISNVote snVote = ISNVote(SNVOTE_PROXY_ADDR);
        for(uint i = 0; i < temp_records.length; i++) {
            if(usedAmount + temp_records[i].amount <= _amount) {
                if(temp_records[i].id != 0) {
                    delRecord(temp_records[i].id);
                    snVote.removeVoteOrApproval(temp_records[i].id);
                } else {
                    balances[msg.sender] = 0;
                }
                usedAmount += temp_records[i].amount;
                if(usedAmount == _amount) {
                    break;
                }
            } else {
                if(temp_records[i].id != 0) {
                addr2records[msg.sender][id2index[temp_records[i].id]].amount = usedAmount + temp_records[i].amount - _amount;
                snVote.removeVoteOrApproval(temp_records[i].id);
                } else {
                    balances[msg.sender] = usedAmount + temp_records[i].amount - _amount;
                }
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

    function setRecordFreeze(uint _id, address _addr, uint _day) public {
        require(existRecord(_id), "invalid record id");
        RecordUseInfo storage useinfo = id2useinfo[_id];
        if(_day == 0) {
            if(useinfo.sepcialAddr != address(0)) {
                emit SafeUnfreeze(_id, useinfo.sepcialAddr);
            }
            useinfo.sepcialAddr = address(0);
            useinfo.freezeHeight = 0;
            useinfo.unfreezeHeight = 0;
        } else {
            if(useinfo.sepcialAddr != address(0)) {
                emit SafeUnfreeze(_id, useinfo.sepcialAddr);
            }
            useinfo.sepcialAddr = _addr;
            useinfo.freezeHeight = block.number + 1;
            useinfo.unfreezeHeight = useinfo.freezeHeight + _day.mul(86400).div(getPropertyValue("block_space"));
            emit SafeFreeze(_id, _addr, _day);
        }
    }

    function setRecordVote(uint _id, address _addr, uint _day) public {
        require(existRecord(_id), "invalid record id");
        RecordUseInfo storage useinfo = id2useinfo[_id];
        if(_day == 0) {
            useinfo.votedAddr = address(0);
            useinfo.voteHeight = 0;
            useinfo.releaseHeight = 0;
        } else {
            useinfo.votedAddr = _addr;
            useinfo.voteHeight = block.number + 1;
            useinfo.releaseHeight = useinfo.voteHeight + _day.mul(86400).div(getPropertyValue("block_space"));
        }
    }

    function addLockDay(uint _id, uint _day) public {
        if(_id == 0 || _day == 0) {
            return;
        }
        require(existRecord(_id), "invalid record id");
        AccountRecord storage record = addr2records[id2addr[_id]][id2index[_id]];
        uint oldLockDay = record.lockDay;
        if(block.number >= record.unlockHeight) {
            record.lockDay = _day;
            record.startHeight = block.number + 1;
        } else {
            record.lockDay += _day;
        }
        record.unlockHeight = record.startHeight + record.lockDay.mul(86400).div(getPropertyValue("block_space"));
        emit SafeAddLockDay(_id, oldLockDay, record.lockDay);
    }

    // get all
    function getAll(address _addr) public view returns (AccountRecord[] memory) {
        return addr2records[_addr];
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
            if(curHeight >= records[i].unlockHeight && curHeight >= id2useinfo[records[i].id].unfreezeHeight) {
                count++;
            }
        }
        if(balances[_addr] != 0) {
            count++;
        }

        // get avaiable amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight && curHeight >= id2useinfo[records[i].id].unfreezeHeight) {
                amount += records[i].amount;
                ids[index++] = records[i].id;
            }
        }
        if(balances[_addr] != 0) {
            amount += balances[_addr];
            ids[index++] = 0;
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
            if(curHeight < id2useinfo[records[i].id].unfreezeHeight) {
                count++;
            }
        }

        // get locked amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < id2useinfo[records[i].id].unfreezeHeight) {
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

    // get record by id
    function getRecordUseInfo(uint _id) public view returns (RecordUseInfo memory) {
        return id2useinfo[_id];
    }

    function existRecord(uint _id) internal view returns (bool) {
        return id2addr[_id] == msg.sender;
    }

    // add record
    function addRecord(address _addr, uint _amount, uint _lockDay) internal returns (uint) {
        if(_lockDay == 0) {
            balances[_addr] += _amount;
            return 0;
        }
        uint startHeight = block.number + 1;
        uint unlockHeight = startHeight + _lockDay.mul(86400).div(getPropertyValue("block_space"));
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_addr];
        records.push(AccountRecord(id, _addr, _amount, _lockDay, startHeight, unlockHeight));
        id2index[id] = records.length - 1;
        id2addr[id] = _addr;
        return id;
    }

    // delete record
    function delRecord(uint _id) internal {
        if(_id == 0) {
            return;
        }
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
        delete id2useinfo[_id];
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