// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./System.sol";
import "./utils/ArrayUtil.sol";
import "./utils/RewardUtil.sol";

contract MasterNodeLogic is IMasterNodeLogic, System {
    event MNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _lockID);
    event MNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _lockID);
    event MNAddressChanged(address _addr, address _newAddr);
    event MNEnodeChanged(address _addr, string _newEnode, string _oldEnode);
    event MNStateUpdate(address _addr, uint _newState, uint _oldState);
    event SystemReward(address _nodeAddr, uint _nodeType, address[] _addrs, uint[] _rewardTypes, uint[] _amounts);
    event MNDissolve(address _addr, uint _id, address _creator, uint _lockID);
    event MNRemoveMember(address _addr, uint _id, address _founder, uint _lockID);

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive) public payable override {
        require(_addr != address(0), "invalid address");
        require(_addr != msg.sender, "address can't be caller");
        require(!getMasterNodeStorage().existNodeAddress(_addr), "existent address");
        // require(!getMasterNodeStorage().existNodeFounder(_addr), "address can't be founder of supernode and masternode");
        require(!getMasterNodeStorage().existNodeAddress(msg.sender), "caller can't be supernode and masternode");
        if(!_isUnion) {
            require(msg.value >= getPropertyValue("masternode_min_amount") * Constant.COIN, "less than min lock amount");
        } else {
            require(msg.value >= getPropertyValue("masternode_union_min_amount") * Constant.COIN, "less than min union lock amount");
        }
        require(_lockDay >= getPropertyValue("masternode_min_lockday"), "less than min lock day");
        string memory enode = compressEnode(_enode);
        require(bytes(enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!getMasterNodeStorage().existNodeEnode(enode), "existent enode");
        require(bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        if(!_isUnion) {
            require(_creatorIncentive == Constant.MAX_INCENTIVE && _partnerIncentive == 0, "invalid incentive");
        } else {
            require(_creatorIncentive > 0 && _creatorIncentive <= Constant.MAX_MN_CREATOR_INCENTIVE && _creatorIncentive + _partnerIncentive == Constant.MAX_INCENTIVE, "invalid incentive");
        }
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        uint unlockHeight = block.number + _lockDay * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
        getMasterNodeStorage().create(_addr, _isUnion, msg.sender, lockID, msg.value, enode, _description, IMasterNodeStorage.IncentivePlan(_creatorIncentive, _partnerIncentive, 0), unlockHeight);
        getAccountManager().setRecordFreezeInfo(lockID, _addr, _lockDay); // creator's lock id can't register other masternode again
        emit MNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(!getMasterNodeStorage().existNodeAddress(msg.sender), "caller can't be supernode and masternode");
        require(getMasterNodeStorage().isUnion(_addr), "can't append-register independent masternode");
        require(msg.value >= getPropertyValue("masternode_append_min_amount") * Constant.COIN, "less than min append lock amount");
        require(_lockDay >= getPropertyValue("masternode_append_min_lockday"), "less than min append lock day");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        uint unlockHeight = block.number + _lockDay * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
        getMasterNodeStorage().append(_addr, lockID, msg.value, unlockHeight);
        getAccountManager().setRecordFreezeInfo(lockID, _addr, getPropertyValue("record_masternode_freezeday")); // partner's lock id can‘t register other masternode until unfreeze it
        emit MNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(!getMasterNodeStorage().existNodeAddress(msg.sender), "caller can't be supernode and masternode");
        require(getMasterNodeStorage().isUnion(_addr), "can't turn-register independent masternode");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(block.number < record.unlockHeight, "record isn't locked");
        require(record.amount >= getPropertyValue("masternode_append_min_amount") * Constant.COIN, "less than min append lock amount");
        require(record.lockDay >= getPropertyValue("masternode_append_min_lockday"), "less than min append lock day");
        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight, "record is freezen");
        if(isSN(useinfo.frozenAddr)) {
            getSuperNodeLogic().removeMember(useinfo.frozenAddr, _lockID);
        } else if(isMN(useinfo.frozenAddr)) {
            getMasterNodeLogic().removeMember(useinfo.frozenAddr, _lockID);
        }
        getMasterNodeStorage().append(_addr, _lockID, record.amount, record.unlockHeight);
        getAccountManager().setRecordFreezeInfo(_lockID, _addr, getPropertyValue("record_masternode_freezeday")); // partner's lock id can't register other masternode until unfreeze it
        emit MNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable override onlySystemRewardContract {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(msg.value >= RewardUtil.getMNReward(block.number, getPropertyValue("block_space")), "invalid reward");
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfo(_addr);
        uint creatorReward = msg.value * info.incentivePlan.creator / Constant.MAX_INCENTIVE;
        uint partnerReward = msg.value - creatorReward;
        rewardCreator(info, creatorReward);
        rewardFounders(info, partnerReward);
        getMasterNodeStorage().updateLastRewardHeight(_addr, block.number);
    }

    function removeMember(address _addr, uint _lockID) public override onlyMnSnAmContract {
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfo(_addr);
        for(uint i; i < info.founders.length; i++) {
            if(info.founders[i].lockID == _lockID) {
                if(i == 0) {
                    // unfreeze partner
                    for(uint k = 1; k < info.founders.length; k++) {
                        getAccountManager().setRecordFreezeInfo(info.founders[k].lockID, address(0), 0);
                    }
                    // clear snvote
                    getSNVote().clearVoteOrApproval(_addr);
                }
                getMasterNodeStorage().removeMember(_addr, i);
                if(i == 0) {
                    emit MNDissolve(_addr, info.id, info.creator, _lockID);
                } else {
                    emit MNRemoveMember(_addr, info.id, info.founders[i].addr, _lockID);
                }
                return;
            }
        }
    }

    function fromSafe3(address _addr, address _creator, uint _amount, uint _lockDay, uint _lockID, string memory _enode) public override onlySafe3Contract {
        require(!getMasterNodeStorage().existNodeAddress(_addr), "existent address");
        require(_amount >= getPropertyValue("masternode_min_amount") * Constant.COIN, "less than min lock amount");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == _creator, "lockID is conflicted with creator");
        require(record.amount == _amount, "lockID is conflicted with amount");
        require(record.lockDay == _lockDay, "lockID is conflicted with lockDay");
        getMasterNodeStorage().create(_addr, false, _creator, _lockID, _amount, compressEnode(_enode), "MasterNode from Safe3", IMasterNodeStorage.IncentivePlan(Constant.MAX_INCENTIVE, 0, 0), record.unlockHeight);
        getMasterNodeStorage().updateState(_addr, Constant.NODE_STATE_STOP);
        getAccountManager().setRecordFreezeInfo2(_lockID, _addr, record.unlockHeight);
        emit MNRegister(_addr, _creator, _amount, _lockDay, _lockID);
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(_newAddr != address(0), "invalid new address");
        require(_newAddr != msg.sender, "new address can't be caller");
        require(!getMasterNodeStorage().existNodeAddress(_newAddr), "existent new address");
        // require(!getMasterNodeStorage().existNodeFounder(_newAddr), "new address can't be founder of supernode and masternode");
        require(msg.sender == getMasterNodeStorage().getInfo(_addr).creator, "caller isn't masternode creator");
        getMasterNodeStorage().updateAddress(_addr, _newAddr);
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfo(_newAddr);
        for(uint i; i < info.founders.length; i++) {
            getAccountManager().updateRecordFreezeAddr(info.founders[i].lockID, _newAddr);
        }
        getSNVote().updateDstAddr(_addr, _newAddr);
        emit MNAddressChanged(_addr, _newAddr);
    }

    function changeEnode(address _addr, string memory _enode) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        string memory enode = compressEnode(_enode);
        require(bytes(enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!getMasterNodeStorage().existNodeEnode(enode), "existent enode");
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfo(_addr);
        string memory oldEnode = info.enode;
        require(msg.sender == info.creator, "caller isn't masternode creator");
        getMasterNodeStorage().updateEnode(_addr, enode);
        emit MNEnodeChanged(_addr, enode, oldEnode);
    }

    function changeEnodeByID(uint _id, string memory _enode) public override {
        require(getMasterNodeStorage().existID(_id), "non-existent masternode");
        string memory enode = compressEnode(_enode);
        require(bytes(enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!getMasterNodeStorage().existNodeEnode(enode), "existent enode");
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfoByID(_id);
        require(msg.sender == info.creator, "caller isn't masternode creator");
        string memory oldEnode = info.enode;
        getMasterNodeStorage().updateEnode(info.addr, enode);
        emit MNEnodeChanged(info.addr, enode, oldEnode);
    }

    function changeDescription(address _addr, string memory _description) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(msg.sender == getMasterNodeStorage().getInfo(_addr).creator, "caller isn't masternode creator");
        getMasterNodeStorage().updateDescription(_addr, _description);
    }

    function changeDescriptionByID(uint _id, string memory _description) public override {
        require(getMasterNodeStorage().existID(_id), "non-existent masternode");
        require(bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfoByID(_id);
        require(msg.sender == info.creator, "caller isn't masternode creator");
        getMasterNodeStorage().updateDescription(info.addr, _description);
    }

    function changeIsOfficial(address _addr, bool _flag) public override onlyOwner {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        getMasterNodeStorage().updateIsOfficial(_addr, _flag);
    }

    function changeState(uint _id, uint _state) public override onlyMasterNodeStateContract {
        if(!getMasterNodeStorage().existID(_id)) {
            return;
        }
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfoByID(_id);
        uint oldState = info.state;
        getMasterNodeStorage().updateState(info.addr, _state);
        emit MNStateUpdate(info.addr, _state, oldState);
    }

    function rewardCreator(IMasterNodeStorage.MasterNodeInfo memory _info, uint _amount) internal {
        if(_amount == 0) {
            return;
        }
        address[] memory rewardAddrs = new address[](1);
        uint[] memory rewardAmounts = new uint[](1);
        uint[] memory rewardTypes = new uint[](1);
        rewardAddrs[0] = _info.creator;
        rewardAmounts[0] = _amount;
        rewardTypes[0] = Constant.REWARD_CREATOR;
        getAccountManager().reward{value: _amount}(rewardAddrs, rewardAmounts);
        emit SystemReward(_info.addr, Constant.REWARD_MN, rewardAddrs, rewardTypes, rewardAmounts);
    }

    function rewardFounders(IMasterNodeStorage.MasterNodeInfo memory _info, uint _amount) internal {
        if(_amount == 0) {
            return;
        }

        uint num;
        uint totalAmount;
        uint minAmount = getPropertyValue("masternode_min_amount") * Constant.COIN;
        for(; num < _info.founders.length; num++) {
            if(totalAmount >= minAmount) {
                break;
            }
            totalAmount += _info.founders[num].amount;
        }
        require(totalAmount >= minAmount, "invalid MasterNode, total amount less than min_amount");

        address[] memory rewardAddrs = new address[](num);
        uint[] memory rewardAmounts = new uint[](num);
        uint[] memory rewardTypes = new uint[](num);

        totalAmount = 0;
        for(uint i; i < num; i++) {
            rewardAddrs[i] = _info.founders[i].addr;
            if(totalAmount + _info.founders[i].amount <= minAmount) {
                rewardAmounts[i]= _amount * _info.founders[i].amount / minAmount;
            } else {
                rewardAmounts[i]= _amount * (minAmount - totalAmount) / minAmount;
            }
            rewardTypes[i] = Constant.REWARD_PARTNER;
            totalAmount += _info.founders[i].amount;
        }

        getAccountManager().reward{value: _amount}(rewardAddrs, rewardAmounts);
        emit SystemReward(_info.addr, Constant.REWARD_MN, rewardAddrs, rewardTypes, rewardAmounts);
    }

    function compressEnode(string memory _enode) internal pure returns (string memory) {
        bytes memory enodeBytes = bytes(_enode);
        uint pos = enodeBytes.length;
        for (uint i; i < enodeBytes.length; i++) {
            if (enodeBytes[i] == "?") {
                pos = i;
                break;
            }
        }

        if (pos == 0) {
            return "";
        }

        if (pos == enodeBytes.length) {
            return _enode;
        }

        bytes memory ret = new bytes(pos);
        for (uint i; i < pos; i++) {
            ret[i] = enodeBytes[i];
        }

        return string(ret);
    }
}