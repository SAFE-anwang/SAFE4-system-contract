// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./System.sol";

contract AccountManager is IAccountManager, System {
    mapping(address => uint) balances; // for available, id = 0
    uint record_no; // record no.
    mapping(address => AccountRecord[]) addr2records; // for locked or available(unlocked)
    mapping(uint => uint) id2index;
    mapping(uint => address) id2addr;
    mapping(uint => RecordUseInfo) id2useinfo;

    mapping(address => mapping(uint => uint)) addr2mature; // key: addr, value: map (key: mature height, value: amount)
    mapping(uint => address[]) mature2addrs; // key: mature height, value: addrs

    event SafeDeposit(address _addr, uint _amount, uint _lockDay, uint _id);
    event SafeWithdraw(address _addr, uint _amount, uint[] _ids);
    event SafeMoveID0(address _addr, uint _amount, uint _id);
    event SafeFreeze(uint _id, address _addr, uint _day);
    event SafeUnfreeze(uint _id, address _addr);
    event SafeVote(uint _id, address _addr, uint _day);
    event SafeRelease(uint _id, address _addr); // remove vote
    event SafeAddLockDay(uint _id, uint _oldLockDay, uint _newLockDay);

    bool internal lock; // re-entrant lock
    modifier noReentrant() {
        require(!lock, "Error: reentrant call");
        lock = true;
        _;
        lock = false;
    }

    // deposit
    function deposit(address _to, uint _lockDay) public payable override returns (uint) {
        require(_to != address(0), "invalid deposit-address");
        require(msg.value >= getPropertyValue("deposit_min_amount"), "invalid amount");
        uint id = addRecord(_to, msg.value, _lockDay);
        emit SafeDeposit(_to, msg.value, _lockDay, id);
        return id;
    }

    function depositWithSecond(address _to, uint _lockSecond) public payable override onlyProposalContract returns (uint) {
        require(_to != address(0), "invalid deposit-address");
        require(msg.value >= getPropertyValue("deposit_min_amount"), "invalid amount");
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
        emit SafeDeposit(_to, msg.value, lockDay, id);
        return id;
    }

    function depositReturnNewID(address _to) public payable override returns (uint) {
        require(_to != address(0), "invalid deposit-address");
        require(msg.value >= getPropertyValue("deposit_min_amount"), "invalid amount");
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_to];
        records.push(AccountRecord(id, _to, msg.value, 0, 0, 0));
        id2index[id] = records.length - 1;
        id2addr[id] = _to;
        emit SafeDeposit(_to, msg.value, 0, id);
        return id;
    }

    function batchDeposit4One(address _to, uint _times, uint _spaceDay, uint _startDay) public payable override returns (uint[] memory) {
        require(msg.value > 0, "invalid value");
        require(_to != address(0), "invalid target address");
        require(_times > 0, "invalid times");
        require(msg.value / _times >= getPropertyValue("deposit_min_amount"), "amount/times is less than 1SAFE");
        uint[] memory ids = new uint[](_times);
        uint batchValue = msg.value / _times;
        uint i;
        for(; i < _times - 1; i++) {
            ids[i] = this.deposit{value: batchValue}(_to, _startDay + (i + 1) * _spaceDay);
        }
        ids[i] = this.deposit{value: batchValue + msg.value % _times}(_to, _startDay + (i + 1) * _spaceDay);
        return ids;
    }

    function batchDeposit4Multi(address[] memory _addrs, uint _times, uint _spaceDay, uint _startDay) public payable override returns (uint[] memory) {
        require(msg.value > 0, "invalid value");
        require(_addrs.length == _times, "address count is different with times");
        require(_times > 0, "invalid times");
        for(uint k; k < _addrs.length; k++) {
            require(_addrs[k] != address(0), "contain zero address");
        }
        require(msg.value / _times >= getPropertyValue("deposit_min_amount"), "amount/times is less than 1SAFE");
        uint[] memory ids = new uint[](_times);
        uint batchValue = msg.value / _times;
        uint i;
        for(; i < _times - 1; i++) {
            ids[i] = this.deposit{value: batchValue}(_addrs[i], _startDay + (i + 1) * _spaceDay);
        }
        ids[i] = this.deposit{value: batchValue + msg.value % _times}(_addrs[i], _startDay + (i + 1) * _spaceDay);
        return ids;
    }

    // withdraw by specify amount
    function withdrawByID(uint[] memory _ids) public override noReentrant returns (uint) {
        require(_ids.length > 0, "invalid record ids");
        uint amount;
        for(uint i; i < _ids.length; i++) {
            if(_ids[i] == 0) {
                if(balances[msg.sender] == 0) {
                    continue;
                }
                amount += balances[msg.sender];
                balances[msg.sender] = 0;
            } else {
                AccountRecord memory record = getRecordByID(_ids[i]);
                if(record.amount == 0) {
                    continue;
                }
                RecordUseInfo memory useinfo = id2useinfo[_ids[i]];
                if(record.addr != msg.sender || block.number < record.unlockHeight || block.number < useinfo.unfreezeHeight || block.number < useinfo.releaseHeight) {
                    continue;
                }
                amount += record.amount;
                if(useinfo.votedAddr != address(0)) {
                    getSNVote().removeVoteOrApproval2(msg.sender, _ids[i]);
                }
                if(getMasterNodeStorage().exist(useinfo.frozenAddr)) {
                    getMasterNodeLogic().removeMember(useinfo.frozenAddr, _ids[i]);
                } else if(getSuperNodeStorage().exist(useinfo.frozenAddr)) {
                    getSuperNodeLogic().removeMember(useinfo.frozenAddr, _ids[i]);
                }
                delRecord(_ids[i]);
            }
        }
        if(amount != 0) {
            payable(msg.sender).transfer(amount);
        }
        emit SafeWithdraw(msg.sender, amount, _ids);
        return amount;
    }

    function reward(address[] memory _addrs, uint[] memory _amounts) public payable override onlyMnOrSnContract {
        require(msg.value > 0, "invalid amount");
        require(_addrs.length == _amounts.length, "invalid addrs and amounts");
        uint totalAmount;
        for(uint i; i < _amounts.length; i++) {
            require(_addrs[i] != address(0), "invalid reward-address");
            totalAmount += _amounts[i];
        }
        require(msg.value >= totalAmount, "msg.value is less than amounts");
        uint rewardMaturity = block.number + getPropertyValue("reward_maturity");
        for(uint i; i < _addrs.length; i++) {
            if(_addrs[i] == address(0) || _amounts[i] == 0) {
                continue;
            }
            addr2mature[_addrs[i]][rewardMaturity] += _amounts[i];
            mature2addrs[rewardMaturity].push(_addrs[i]);
        }
        address[] memory tempAddrs = mature2addrs[block.number];
        for(uint i; i < tempAddrs.length; i++) {
            addRecord(tempAddrs[i], addr2mature[tempAddrs[i]][block.number], 0);
            delete addr2mature[tempAddrs[i]][block.number];
        }
        delete mature2addrs[block.number];
    }

    // move balance of id0 to new id
    function moveID0(address _addr) public override onlySNVoteContract returns (uint) {
        uint amount = balances[_addr];
        if(amount < getPropertyValue("deposit_min_amount")) {
            return 0;
        }
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_addr];
        records.push(AccountRecord(id, _addr, amount, 0, 0, 0));
        id2index[id] = records.length - 1;
        id2addr[id] = _addr;
        balances[_addr] = 0;
        emit SafeMoveID0(_addr, amount, id);
        return id;
    }

    function fromSafe3(address _addr, uint _lockDay, uint _remainLockHeight) public payable override onlySafe3Contract returns (uint) {
        require(msg.value > 0, "invalid amount");
        require(_addr != address(0), "reward to the zero address");
        require(_lockDay > 0, "invalid lock day");
        require(_remainLockHeight > 0, "invalid remain lock height");
        uint id = ++record_no;
        AccountRecord[] storage records = addr2records[_addr];
        records.push(AccountRecord(id, _addr, msg.value, _lockDay, block.number, block.number + _remainLockHeight));
        id2index[id] = records.length - 1;
        id2addr[id] = _addr;
        emit SafeDeposit(_addr, msg.value, _lockDay, id);
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

    function setRecordFreezeInfo2(uint _id, address _target, uint _height) public override onlyMnOrSnContract {
        if(_id == 0) {
            return;
        }
        RecordUseInfo storage useinfo = id2useinfo[_id];
        useinfo.frozenAddr = _target;
        useinfo.freezeHeight = block.number;
        useinfo.unfreezeHeight = _height;
        emit SafeFreeze(_id, _target, (_height - block.number)*getPropertyValue("block_space")/Constant.SECONDS_IN_DAY);
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
        if(_id == 0) {
            return;
        }
        require(id2addr[_id] == msg.sender, "record isn't your");
        address frozenAddr = id2useinfo[_id].frozenAddr;
        if(frozenAddr != address(0)) { // used for mn/sn
            require(_day >= 360, "invalid day, must be 360 at least");
        } else {
            if(_day == 0) {
                return;
            }
        }
        AccountRecord storage record = addr2records[id2addr[_id]][id2index[_id]];
        uint oldLockDay = record.lockDay;
        if(block.number >= record.unlockHeight) {
            record.lockDay = _day;
            record.startHeight = block.number;
            record.unlockHeight = block.number + _day * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
        } else {
            record.lockDay += _day;
            record.unlockHeight += _day * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
        }

        if(frozenAddr != address(0)) { // used for mn/sn
            if(getMasterNodeStorage().exist(frozenAddr)) {
                getMasterNodeStorage().updateFounderUnlockHeight(frozenAddr, _id, record.unlockHeight);
            } else if(getSuperNodeStorage().exist(frozenAddr)) {
                getSuperNodeStorage().updateFounderUnlockHeight(frozenAddr, _id, record.unlockHeight);
            }
        }

        emit SafeAddLockDay(_id, oldLockDay, record.lockDay);
    }

    // get immature amount
    function getImmatureAmount(address _addr) public view override returns (uint) {
        uint immatureAmount;
        uint rewardMaturity = getPropertyValue("reward_maturity");
        for(uint i = rewardMaturity; i> 0; i--) {
            immatureAmount += addr2mature[_addr][block.number + i];
        }
        return immatureAmount;
    }

    // get total amount and total record number
    function getTotalAmount(address _addr) public view override returns (uint, uint) {
        uint amount;
        uint num;
        if(balances[_addr] != 0) {
            amount += balances[_addr];
            num++;
        }

        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            amount += records[i].amount;
        }
        num += records.length;
        amount += getImmatureAmount(_addr);
        return (amount, num);
    }

    function getTotalIDs(address _addr, uint _start, uint _count) public view override returns (uint[] memory) {
        uint totalAmount;
        uint totalNum;
        (totalAmount, totalNum) = getTotalAmount(_addr);
        require(totalNum > 0, "insufficient quantity");
        require(_start < totalNum, "invalid _start, must be in [0, totalNum)");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](totalNum);
        uint index;
        if(balances[_addr] != 0) {
            temp[index++] = 0;
        }
        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            temp[index++] = records[i].id;
        }

        uint num = _count;
        if(_start + _count >= totalNum) {
            num = totalNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
        }
        return ret;
    }

    // get available amount and available record number
    function getAvailableAmount(address _addr) public view override returns (uint, uint) {
        uint amount;
        uint num;
        if(balances[_addr] != 0) {
            amount += balances[_addr];
            num++;
        }

        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            if(block.number >= records[i].unlockHeight && block.number >= id2useinfo[records[i].id].unfreezeHeight && block.number >= id2useinfo[records[i].id].releaseHeight) {
                amount += records[i].amount;
                num++;
            }
        }
        return (amount, num);
    }

    function getAvailableIDs(address _addr, uint _start, uint _count) public view override returns (uint[] memory) {
        uint availableAmount;
        uint availableNum;
        (availableAmount, availableNum) = getAvailableAmount(_addr);
        require(availableNum > 0, "insufficient quantity");
        require(_start < availableNum, "invalid _start, must be in [0, availableNum)");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](availableNum);
        uint index;
        if(balances[_addr] != 0) {
            temp[index++] = 0;
        }
        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            if(block.number >= records[i].unlockHeight && block.number >= id2useinfo[records[i].id].unfreezeHeight && block.number >= id2useinfo[records[i].id].releaseHeight) {
                temp[index++] = records[i].id;
            }
        }

        uint num = _count;
        if(_start + _count >= availableNum) {
            num = availableNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
        }
        return ret;
    }

    // get locked amount and locked record number
    function getLockedAmount(address _addr) public view override returns (uint, uint) {
        uint amount;
        uint num;
        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            if(block.number < records[i].unlockHeight) {
                amount += records[i].amount;
                num++;
            }
        }
        return (amount, num);
    }

    function getLockedIDs(address _addr, uint _start, uint _count) public view override returns (uint[] memory) {
        uint lockedAmount;
        uint lockedNum;
        (lockedAmount, lockedNum) = getLockedAmount(_addr);
        require(lockedNum > 0, "insufficient quantity");
        require(_start < lockedNum, "invalid _start, must be in [0, lockedNum)");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](lockedNum);
        uint index;
        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            if(block.number < records[i].unlockHeight) {
                temp[index++] = records[i].id;
            }
        }

        uint num = _count;
        if(_start + _count >= lockedNum) {
            num = lockedNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
        }
        return ret;
    }

    // get used amount and used record num
    function getUsedAmount(address _addr) public view override returns (uint, uint) {
        uint amount;
        uint num;
        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            if(block.number < id2useinfo[records[i].id].unfreezeHeight || block.number < id2useinfo[records[i].id].releaseHeight) {
                amount += records[i].amount;
                num++;
            }
        }
        return (amount, num);
    }

    function getUsedIDs(address _addr, uint _start, uint _count) public view override returns (uint[] memory) {
        uint usedAmount;
        uint usedNum;
        (usedAmount, usedNum) = getUsedAmount(_addr);
        require(usedNum > 0, "insufficient quantity");
        require(_start < usedNum, "invalid _start, must be in [0, usedNum)");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](usedNum);
        uint index;
        AccountRecord[] memory records = addr2records[_addr];
        for(uint i; i < records.length; i++) {
            if(block.number < id2useinfo[records[i].id].unfreezeHeight || block.number < id2useinfo[records[i].id].releaseHeight) {
                temp[index++] = records[i].id;
            }
        }

        uint num = _count;
        if(_start + _count >= usedNum) {
            num = usedNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
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
        id2index[records[pos].id] = pos;
        records.pop();
        delete id2index[_id];
        delete id2addr[_id];
        delete id2useinfo[_id];
    }
}