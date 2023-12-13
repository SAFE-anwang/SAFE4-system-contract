// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";

contract AccountManager is IAccountManager, System {
    mapping(address => uint) balances; // for available, id = 0
    uint record_no; // record no.
    mapping(address => AccountRecord[]) addr2records; // for locked or available(unlocked)
    mapping(uint => uint) id2index;
    mapping(uint => address) id2addr;
    mapping(uint => RecordUseInfo) id2useinfo;

    event SafeDeposit(address _addr, uint _amount, uint _lockDay, uint _id);
    event SafeWithdraw(address _addr, uint _amount, uint[] _ids);
    event SafeTransfer(address _from, address _to, uint _amount, uint _lockDay, uint _id);
    event SafeMoveID0(address _addr, uint _amount, uint _id);
    event SafeFreeze(uint _id, address _addr, uint _day);
    event SafeUnfreeze(uint _id, address _addr);
    event SafeVote(uint _id, address _addr, uint _day);
    event SafeRelease(uint _id, address _addr); // remove vote
    event SafeAddLockDay(uint _id, uint _oldLockDay, uint _newLockDay);

    // deposit
    function deposit(address _to, uint _lockDay) public payable override returns (uint) {
        require(msg.value > 0, "invalid amount");
        uint id = addRecord(_to, msg.value, _lockDay);
        emit SafeDeposit(_to, msg.value, _lockDay, id);
        return id;
    }

    function depositWithSecond(address _to, uint _lockSecond) public payable override onlyProposalContract returns (uint) {
        require(msg.value > 0, "invalid amount");
        if(_lockSecond == 0) {
            balances[_to] += msg.value;
            return 0;
        }
        uint space = getPropertyValue("block_space");
        uint unlockHeight = block.number + _lockSecond / space;
        uint lockDay = _lockSecond / Constant.SECONDS_IN_DAY;
        if(_lockSecond % space != 0) {
            unlockHeight += 1;
            lockDay += 1;
        }
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_to];
        records.push(AccountRecord(id, _to, msg.value, lockDay, block.number, unlockHeight));
        id2index[id] = records.length - 1;
        id2addr[id] = _to;
        return id;
    }

    // withdraw all
    function withdraw() public override returns (uint) {
        uint amount = 0;
        uint[] memory ids;
        (amount, ids) = getAvailableAmount(msg.sender);
        require(amount > 0, "insufficient amount");
        return withdrawByID(ids);
    }

    // withdraw by specify amount
    function withdrawByID(uint[] memory _ids) public override returns (uint) {
        require(_ids.length > 0, "invalid record ids");
        uint amount = 0;
        for(uint i = 0; i < _ids.length; i++) {
            if(_ids[i] == 0) {
                amount += balances[msg.sender];
            } else {
                AccountRecord memory record = getRecordByID(_ids[i]);
                RecordUseInfo memory useinfo = id2useinfo[_ids[i]];
                if(record.addr == msg.sender && block.number >= record.unlockHeight && block.number >= useinfo.unfreezeHeight && block.number >= useinfo.releaseHeight) {
                    amount += record.amount;
                }
            }
        }
        if(amount != 0) {
            payable(msg.sender).transfer(amount);
            for(uint i = 0; i < _ids.length; i++) {
                if(_ids[i] != 0) {
                    AccountRecord memory record = getRecordByID(_ids[i]);
                    RecordUseInfo memory useinfo = id2useinfo[_ids[i]];
                    if(record.addr == msg.sender && block.number >= record.unlockHeight && block.number >= useinfo.unfreezeHeight && block.number >= useinfo.releaseHeight) {
                        getSNVote().removeVoteOrApproval2(msg.sender, _ids[i]);
                        if(getMasterNodeStorage().exist(useinfo.frozenAddr)) {
                            getMasterNodeLogic().removeMember(useinfo.frozenAddr, _ids[i]);
                        } else if(getSuperNodeStorage().exist(useinfo.frozenAddr)) {
                            getSuperNodeLogic().removeMember(useinfo.frozenAddr, _ids[i]);
                        }
                        delRecord(_ids[i]);
                    }
                } else {
                    balances[msg.sender] = 0;
                }
            }
        }
        emit SafeWithdraw(msg.sender, amount, _ids);
        return amount;
    }

    function transfer(address _to, uint _amount, uint _lockDay) public override returns (uint) {
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
        //sortRecordByAmount(temp_records, 0, temp_records.length - 1);
        uint usedAmount = 0;
        for(uint i = 0; i < temp_records.length; i++) {
            if(usedAmount + temp_records[i].amount <= _amount) {
                if(temp_records[i].id != 0) {
                    RecordUseInfo memory useinfo = id2useinfo[temp_records[i].id];
                    getSNVote().removeVoteOrApproval2(msg.sender, temp_records[i].id);
                    if(getMasterNodeStorage().exist(useinfo.frozenAddr)) {
                        getMasterNodeLogic().removeMember(useinfo.frozenAddr, temp_records[i].id);
                    } else if(getSuperNodeStorage().exist(useinfo.frozenAddr)) {
                        getSuperNodeLogic().removeMember(useinfo.frozenAddr, temp_records[i].id);
                    }
                    delRecord(temp_records[i].id);
                } else {
                    balances[msg.sender] = 0;
                }
                usedAmount += temp_records[i].amount;
                if(usedAmount == _amount) {
                    break;
                }
            } else {
                if(temp_records[i].id != 0) {
                    RecordUseInfo memory useinfo = id2useinfo[temp_records[i].id];
                    getSNVote().removeVoteOrApproval2(msg.sender, temp_records[i].id);
                    if(getMasterNodeStorage().exist(useinfo.frozenAddr)) {
                        getMasterNodeLogic().removeMember(useinfo.frozenAddr, temp_records[i].id);
                    } else if(getSuperNodeStorage().exist(useinfo.frozenAddr)) {
                        getSuperNodeLogic().removeMember(useinfo.frozenAddr, temp_records[i].id);
                    }
                    addr2records[msg.sender][id2index[temp_records[i].id]].amount = usedAmount + temp_records[i].amount - _amount;
                } else {
                    balances[msg.sender] = usedAmount + temp_records[i].amount - _amount;
                }
                break;
            }
        }
        return id;
    }

    function reward(address[] memory _addrs, uint[] memory _amounts) public payable override onlyMnOrSnContract {
        require(msg.value > 0, "invalid amount");
        require(_addrs.length == _amounts.length, "invalid addrs and amounts");
        for(uint i = 0; i < _addrs.length; i++) {
            addRecord(_addrs[i], _amounts[i], 0);
        }
    }

    // move balance of id0 to new id
    function moveID0(address _addr) public override onlySNVoteContract returns (uint) {
        uint amount = balances[_addr];
        require(amount != 0, "balance of id(0) is zero");
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_addr];
        records.push(AccountRecord(id, _addr, amount, 0, 0, 0));
        id2index[id] = records.length - 1;
        id2addr[id] = _addr;
        balances[_addr] = 0;
        emit SafeMoveID0(_addr, amount, id);
        return id;
    }

    function fromSafe3(address _addr, uint _amount, uint _lockDay, uint _remainLockHeight) public override onlySafe3Contract returns (uint) {
        require(_addr != address(0), "reward to the zero address");
        require(_lockDay > 0, "invalid lock day");
        require(_remainLockHeight > 0, "invalid remain lock height");
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_addr];
        records.push(AccountRecord(id, _addr, _amount, _lockDay, block.number, block.number + _remainLockHeight));
        id2index[id] = records.length - 1;
        id2addr[id] = _addr;
        return id;
    }

    function setRecordFreezeInfo(uint _id, address _target, uint _day) public override onlyMnOrSnContract {
        if(_id == 0) {
            return;
        }
        RecordUseInfo storage useinfo = id2useinfo[_id];
        if(_day == 0) {
            if(useinfo.frozenAddr != address(0)) {
                emit SafeUnfreeze(_id, useinfo.frozenAddr);
            }
            useinfo.frozenAddr = address(0);
            useinfo.freezeHeight = 0;
            useinfo.unfreezeHeight = 0;
        } else {
            if(useinfo.frozenAddr != address(0)) {
                emit SafeUnfreeze(_id, useinfo.frozenAddr);
            }
            useinfo.frozenAddr = _target;
            useinfo.freezeHeight = block.number;
            useinfo.unfreezeHeight = useinfo.freezeHeight + _day * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
            emit SafeFreeze(_id, _target, _day);
        }
    }

    function setRecordVoteInfo(uint _id, address _target, uint _day) public override onlySnOrSNVoteContract {
        if(_id == 0) {
            return;
        }
        RecordUseInfo storage useinfo = id2useinfo[_id];
        if(_day == 0) {
            if(useinfo.votedAddr != address(0)) {
                emit SafeRelease(_id, useinfo.votedAddr);
            }
            useinfo.votedAddr = address(0);
            useinfo.voteHeight = 0;
            useinfo.releaseHeight = 0;
        } else {
            if(useinfo.votedAddr != address(0)) {
                emit SafeRelease(_id, useinfo.votedAddr);
            }
            useinfo.votedAddr = _target;
            useinfo.voteHeight = block.number;
            useinfo.releaseHeight = useinfo.voteHeight + _day * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
            emit SafeVote(_id, _target, _day);
        }
    }

    function updateRecordFreezeAddr(uint _id, address _target) public override onlyMnOrSnContract {
        if(_id == 0) {
            return;
        }
        require(id2useinfo[_id].frozenAddr != address(0), "account isn't frozen");
        id2useinfo[_id].frozenAddr = _target;
    }

    function updateRecordVoteAddr(uint _id, address _target) public override onlySuperNodeLogic {
        if(_id == 0) {
            return;
        }
        require(id2useinfo[_id].votedAddr != address(0), "account isn't voted");
        id2useinfo[_id].votedAddr = _target;
    }

    function addLockDay(uint _id, uint _day) public override {
        if(_id == 0 || _day == 0) {
            return;
        }
        require(id2addr[_id] == msg.sender, "invalid record id");
        AccountRecord storage record = addr2records[id2addr[_id]][id2index[_id]];
        uint oldLockDay = record.lockDay;
        if(block.number >= record.unlockHeight) {
            record.lockDay = _day;
            record.startHeight = block.number;
        } else {
            record.lockDay += _day;
        }
        record.unlockHeight = record.startHeight + record.lockDay * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
        emit SafeAddLockDay(_id, oldLockDay, record.lockDay);
    }

    // get total amount
    function getTotalAmount(address _addr) public view override returns (uint, uint[] memory) {
        AccountRecord[] memory records = addr2records[_addr];
        uint count = records.length;
        uint tempAmount = balances[_addr];
        if(tempAmount != 0) {
            count++;
        }
        uint amount = 0;
        uint[] memory ids = new uint[](count);
        uint index = 0;
        if(tempAmount != 0) {
            amount += tempAmount;
            ids[index++] = 0;
        }
        for(uint i = 0; i < records.length; i++) {
            amount += records[i].amount;
            ids[index++] = records[i].id;
        }
        return (amount, ids);
    }

    // get available amount
    function getAvailableAmount(address _addr) public view override returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[_addr];
        uint tempAmount = balances[_addr];

        // get available count
        uint count = 0;
        if(tempAmount != 0) {
            count++;
        }
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight && curHeight >= id2useinfo[records[i].id].unfreezeHeight && curHeight >= id2useinfo[records[i].id].releaseHeight) {
                count++;
            }
        }

        // get available amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        if(tempAmount != 0) {
            amount += tempAmount;
            ids[index++] = 0;
        }
        for(uint i = 0; i < records.length; i++) {
            if(curHeight >= records[i].unlockHeight && curHeight >= id2useinfo[records[i].id].unfreezeHeight && curHeight >= id2useinfo[records[i].id].releaseHeight) {
                amount += records[i].amount;
                ids[index++] = records[i].id;
            }
        }

        return (amount, ids);
    }

    // get locked amount
    function getLockedAmount(address _addr) public view override returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[_addr];

        // get locked count
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

    // get used amount
    function getUsedAmount(address _addr) public view override returns (uint, uint[] memory) {
        uint curHeight = block.number;
        AccountRecord[] memory records = addr2records[_addr];

        // get used count
        uint count = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < id2useinfo[records[i].id].unfreezeHeight || curHeight < id2useinfo[records[i].id].releaseHeight) {
                count++;
            }
        }

        // get used amount and id list
        uint[] memory ids = new uint[](count);
        uint amount = 0;
        uint index = 0;
        for(uint i = 0; i < records.length; i++) {
            if(curHeight < id2useinfo[records[i].id].unfreezeHeight || curHeight < id2useinfo[records[i].id].releaseHeight) {
                amount += records[i].amount;
                ids[index++] = records[i].id;
            }
        }
        return (amount, ids);
    }

    // get account records
    function getRecords(address _addr) public view override returns (AccountRecord[] memory) {
        AccountRecord[] memory records = addr2records[_addr];
        uint count = records.length;
        uint tempAmount = balances[_addr];
        if(tempAmount != 0) {
            count++;
        }
        AccountRecord[] memory ret = new AccountRecord[](count);
        uint index = 0;
        if(tempAmount != 0) {
            ret[index++] = AccountRecord(0, _addr, tempAmount, 0, 0, 0);
        }
        for(uint i = 0; i < records.length; i++) {
            ret[index++] = records[i];
        }
        return ret;
    }

    function getRecord0(address _addr) public view override returns (AccountRecord memory) {
        return AccountRecord(0, _addr, balances[_addr], 0, 0, 0);
    }

    // get record by id
    function getRecordByID(uint _id) public view override returns (AccountRecord memory ret) {
        if(_id != 0 && id2addr[_id] != address(0)) {
            ret = addr2records[id2addr[_id]][id2index[_id]];
        }
    }

    // get record by id
    function getRecordUseInfo(uint _id) public view override returns (RecordUseInfo memory) {
        if(_id == 0) {
            return RecordUseInfo(address(0), 0, 0, address(0), 0, 0);
        }
        return id2useinfo[_id];
    }

    // add record
    function addRecord(address _addr, uint _amount, uint _lockDay) internal returns (uint) {
        if(_lockDay == 0) {
            balances[_addr] += _amount;
            return 0;
        }
        uint startHeight = block.number;
        uint unlockHeight = startHeight + _lockDay * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
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
        require(id2addr[_id] == msg.sender, "invalid record id");
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

    // // sort by amount
    // function sortRecordByAmount(AccountRecord[] memory _arr, uint _left, uint _right) internal pure {
    //     uint i = _left;
    //     uint j = _right;
    //     if (i == j) return;
    //     AccountRecord memory middle = _arr[_left + (_right - _left) / 2];
    //     while(i <= j) {
    //         while(_arr[i].amount < middle.amount) i++;
    //         while(middle.amount < _arr[j].amount && j > 0) j--; 
    //         if(i <= j) {
    //             (_arr[i], _arr[j]) = (_arr[j], _arr[i]);
    //             i++;
    //             if(j != 0) j--;
    //         }
    //     }
    //     if(_left < j)
    //         sortRecordByAmount(_arr, _left, j);
    //     if(i < _right)
    //         sortRecordByAmount(_arr, i, _right);
    // }
}