// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./System.sol";
import "./utils/ArrayUtil.sol";
import "./utils/RewardUtil.sol";

contract SuperNodeLogic is ISuperNodeLogic, System {
    event SNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _reocrdID);
    event SNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _recordID);
    event SNAddressChanged(address _addr, address _newAddr);
    event SNEnodeChanged(address _addr, string _newEnode, string _oldEnode);
    event SNStateUpdate(address _addr, uint _newState, uint _oldState);
    event SystemReward(address _nodeAddr, uint _nodeType, address[] _addrs, uint[] _rewardTypes, uint[] _amounts);
    event SNDissolve(address _addr, uint _id, address _creator, uint _lockID);
    event SNRemoveMember(address _addr, uint _id, address _founder, uint _lockID);

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable override {
        require(_addr != address(0), "invalid address");
        require(_addr != msg.sender, "address can't be caller");
        require(!getSuperNodeStorage().existNodeAddress(_addr), "existent address");
        // require(!getSuperNodeStorage().existNodeFounder(_addr), "address can't be founder of supernode and masternode");
        require(!getSuperNodeStorage().existNodeAddress(msg.sender), "caller can't be supernode and masternode");
        if(!_isUnion) {
            require(msg.value >= getPropertyValue("supernode_min_amount") * Constant.COIN, "less than min lock amount");
        } else {
            require(msg.value >= getPropertyValue("supernode_union_min_amount") * Constant.COIN, "less than min union lock amount");
        }
        require(_lockDay >= getPropertyValue("supernode_min_lockday"), "less than min lock day");
        require(bytes(_name).length >= Constant.MIN_SN_NAME_LEN && bytes(_name).length <= Constant.MAX_SN_NAME_LEN, "invalid name");
        require(!getSuperNodeStorage().existName(_name), "existent name");
        string memory enode = compressEnode(_enode);
        require(bytes(enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!getSuperNodeStorage().existNodeEnode(enode), "existent enode");
        require(bytes(_description).length >= Constant.MIN_NODE_DESCRIPTION_LEN && bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(_creatorIncentive + _partnerIncentive + _voterIncentive == Constant.MAX_INCENTIVE, "invalid incentive");
        require(_creatorIncentive >= Constant.MIN_SN_CREATOR_INCENTIVE && _creatorIncentive <= Constant.MAX_SN_CREATOR_INCENTIVE, "creator incentive exceed 10%");
        require(_partnerIncentive >= Constant.MIN_SN_PARTNER_INCENTIVE && _partnerIncentive <= Constant.MAX_SN_PARTNER_INCENTIVE, "partner incentive is 40% - 50%");
        require(_voterIncentive >= Constant.MIN_SN_VOTER_INCENTIVE && _voterIncentive <= Constant.MAX_SN_VOTER_INCENTIVE, "creator incentive is 40% - 50%");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        uint unlockHeight = block.number + _lockDay * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
        ISuperNodeStorage.IncentivePlan memory incentive = ISuperNodeStorage.IncentivePlan(_creatorIncentive, _partnerIncentive, _voterIncentive);
        getSuperNodeStorage().create(_addr, _isUnion, lockID, msg.value, _name, enode, _description, incentive, unlockHeight);
        getAccountManager().setRecordFreezeInfo(lockID, _addr, _lockDay); // creator's lock id can't register other supernode again
        emit SNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(!getSuperNodeStorage().existNodeAddress(msg.sender), "caller can't be supernode and masternode");
        require(getSuperNodeStorage().isUnion(_addr), "can't append-register independent supernode");
        require(msg.value >= getPropertyValue("supernode_append_min_amount") * Constant.COIN, "less than min append lock amount");
        require(_lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        uint unlockHeight = block.number + _lockDay * Constant.SECONDS_IN_DAY / getPropertyValue("block_space");
        getSuperNodeStorage().append(_addr, lockID, msg.value, unlockHeight);
        getAccountManager().setRecordFreezeInfo(lockID, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(!getSuperNodeStorage().existNodeAddress(msg.sender), "caller can't be supernode and masternode");
        require(getSuperNodeStorage().isUnion(_addr), "can't turn-register independent supernode");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(block.number < record.unlockHeight, "record isn't locked");
        require(record.amount >= getPropertyValue("supernode_append_min_amount") * Constant.COIN, "less than min append lock amount");
        require(record.lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight && block.number >= useinfo.releaseHeight, "record is freezen");
        if(useinfo.votedAddr != address(0)) {
            getSNVote().removeVoteOrApproval2(msg.sender, _lockID);
        }
        if(isSN(useinfo.frozenAddr)) {
            getSuperNodeLogic().removeMember(useinfo.frozenAddr, _lockID);
        } else if(isMN(useinfo.frozenAddr)) {
            getMasterNodeLogic().removeMember(useinfo.frozenAddr, _lockID);
        }
        getSuperNodeStorage().append(_addr, _lockID, record.amount, record.unlockHeight);
        getAccountManager().setRecordFreezeInfo(_lockID, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable override onlySystemRewardContract {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(msg.value >= RewardUtil.getSNReward(block.number, getPropertyValue("block_space")), "invalid reward");
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfo(_addr);
        uint creatorReward = msg.value * info.incentivePlan.creator / Constant.MAX_INCENTIVE;
        uint partnerReward = msg.value * info.incentivePlan.partner / Constant.MAX_INCENTIVE;
        uint voterReward = msg.value - creatorReward - partnerReward;
        rewardCreator(info, creatorReward);
        rewardFounders(info, partnerReward);
        rewardVoters(info, voterReward);
        getSuperNodeStorage().updateLastRewardHeight(_addr, block.number);
    }

    function removeMember(address _addr, uint _lockID) public override onlyMnSnAmContract {
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfo(_addr);
        for(uint i; i < info.founders.length; i++) {
            if(info.founders[i].lockID == _lockID) {
                if(i == 0) { // lockID comes from creator
                    // unfreeze partner
                    for(uint k = 1; k < info.founders.length; k++) {
                        getAccountManager().setRecordFreezeInfo(info.founders[k].lockID, address(0), 0);
                    }
                    // clear snvote
                    getSNVote().clearVoteOrApproval(_addr);
                }
                getSuperNodeStorage().removeMember(_addr, i);
                if(i == 0) {
                    emit SNDissolve(_addr, info.id, info.creator, _lockID);
                } else {
                    emit SNRemoveMember(_addr, info.id, info.founders[i].addr, _lockID);
                }
                return;
            }
        }
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(_newAddr != address(0), "invalid new address");
        require(_newAddr != msg.sender, "new address can't be caller");
        require(!getSuperNodeStorage().existNodeAddress(_newAddr), "existent new address");
        // require(!getSuperNodeStorage().existNodeFounder(_newAddr), "new address can't be founder of supernode and masternode");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't creator");
        getSuperNodeStorage().updateAddress(_addr, _newAddr);
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfo(_newAddr);
        for(uint i; i < info.founders.length; i++) {
            getAccountManager().updateRecordFreezeAddr(info.founders[i].lockID, _newAddr);
        }

        // update voters' frozen addr
        uint idNum = getSNVote().getIDNum(_addr);
        if(idNum > 0) {
            uint batchNum = idNum / 100;
            if(idNum % 100 != 0) {
                batchNum++;
            }
            for(uint k; k < batchNum; k++) {
                uint[] memory votedIDs = getSNVote().getIDs(_addr, k * 100, 100);
                for(uint m; m < votedIDs.length; m++) {
                    getAccountManager().updateRecordVoteAddr(votedIDs[m], _newAddr);
                }
            }
        }
        getSNVote().updateDstAddr(_addr, _newAddr);
        emit SNAddressChanged(_addr, _newAddr);
    }

    function changeName(address _addr, string memory _name) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(bytes(_name).length >= Constant.MIN_SN_NAME_LEN && bytes(_name).length <= Constant.MAX_SN_NAME_LEN, "invalid name");
        require(!getSuperNodeStorage().existName(_name), "existent name");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't creator");
        getSuperNodeStorage().updateName(_addr, _name);
    }

    function changeNameByID(uint _id, string memory _name) public override {
        require(getSuperNodeStorage().existID(_id), "non-existent supernode");
        require(bytes(_name).length >= Constant.MIN_SN_NAME_LEN && bytes(_name).length <= Constant.MAX_SN_NAME_LEN, "invalid name");
        require(!getSuperNodeStorage().existName(_name), "existent name");
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfoByID(_id);
        require(msg.sender == info.creator, "caller isn't creator");
        getSuperNodeStorage().updateName(info.addr, _name);
    }

    function changeEnode(address _addr, string memory _enode) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        string memory enode = compressEnode(_enode);
        require(bytes(enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!getSuperNodeStorage().existNodeEnode(enode), "existent enode");
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfo(_addr);
        string memory oldEnode = info.enode;
        require(msg.sender == info.creator, "caller isn't creator");
        getSuperNodeStorage().updateEnode(_addr, enode);
        emit SNEnodeChanged(_addr, enode, oldEnode);
    }

    function changeEnodeByID(uint _id, string memory _enode) public override {
        require(getSuperNodeStorage().existID(_id), "non-existent supernode");
        string memory enode = compressEnode(_enode);
        require(bytes(enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!getSuperNodeStorage().existNodeEnode(enode), "existent enode");
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfoByID(_id);
        require(msg.sender == info.creator, "caller isn't creator");
        string memory oldEnode = info.enode;
        getSuperNodeStorage().updateEnode(info.addr, enode);
        emit SNEnodeChanged(info.addr, enode, oldEnode);
    }

    function changeDescription(address _addr, string memory _description) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(bytes(_description).length >= Constant.MIN_NODE_DESCRIPTION_LEN && bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't creator");
        getSuperNodeStorage().updateDescription(_addr, _description);
    }

    function changeDescriptionByID(uint _id, string memory _description) public override {
        require(getSuperNodeStorage().existID(_id), "non-existent supernode");
        require(bytes(_description).length >= Constant.MIN_NODE_DESCRIPTION_LEN && bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfoByID(_id);
        require(msg.sender == info.creator, "caller isn't creator");
        getSuperNodeStorage().updateDescription(info.addr, _description);
    }

    function changeIsOfficial(address _addr, bool _flag) public override onlyOwner {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        getSuperNodeStorage().updateIsOfficial(_addr, _flag);
    }

    function changeState(uint _id, uint _state) public override onlySuperNodeStateContract {
        if(!getSuperNodeStorage().existID(_id)) {
            return;
        }
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfoByID(_id);
        uint oldState = info.state;
        getSuperNodeStorage().updateState(info.addr, _state);
        emit SNStateUpdate(info.addr, _state, oldState);
    }

    function rewardCreator(ISuperNodeStorage.SuperNodeInfo memory _info, uint _amount) internal {
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
        emit SystemReward(_info.addr, Constant.REWARD_SN, rewardAddrs, rewardTypes, rewardAmounts);
    }

    function rewardFounders(ISuperNodeStorage.SuperNodeInfo memory _info, uint _amount) internal {
        if(_amount == 0) {
            return;
        }

        uint num;
        uint totalAmount;
        uint minAmount = getPropertyValue("supernode_min_amount") * Constant.COIN;
        for(; num < _info.founders.length; num++) {
            if(totalAmount >= minAmount) {
                break;
            }
            totalAmount += _info.founders[num].amount;
        }
        require(totalAmount >= minAmount, "invalid SuperNode, total amount less than min_amount");

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
        emit SystemReward(_info.addr, Constant.REWARD_SN, rewardAddrs, rewardTypes, rewardAmounts);
    }

    function rewardVoters(ISuperNodeStorage.SuperNodeInfo memory _info, uint _amount) internal {
        if(_amount == 0) {
            return;
        }

        address[] memory rewardAddrs;
        uint[] memory rewardAmounts;
        uint[] memory rewardTypes;
        uint voterNum = getSNVote().getVoterNum(_info.addr);
        if(voterNum == 0) { // reward to creator when voterNum = 0
            rewardAddrs = new address[](1);
            rewardAmounts = new uint[](1);
            rewardTypes = new uint[](1);
            rewardAddrs[0] = _info.creator;
            rewardAmounts[0] = _amount;
            rewardTypes[0] = Constant.REWARD_VOTER;
            getAccountManager().reward{value: _amount}(rewardAddrs, rewardAmounts);
            emit SystemReward(_info.addr, Constant.REWARD_SN, rewardAddrs, rewardTypes, rewardAmounts);
            return;
        }

        uint totalVoteNum = getSNVote().getTotalVoteNum(_info.addr);
        uint batchNum = voterNum / 100;
        if(voterNum % 100 != 0) {
            batchNum++;
        }
        for(uint i; i < batchNum; i++) {
            address[] memory voterAddrs;
            uint[] memory voteNums;
            (voterAddrs, voteNums) = getSNVote().getVoters(_info.addr, 100*i, 100);

            rewardAddrs = new address[](voterAddrs.length);
            rewardAmounts = new uint[](voterAddrs.length);
            rewardTypes = new uint[](voterAddrs.length);

            uint totalAmount;
            for(uint k; k < voterAddrs.length; k++) {
                rewardAddrs[k] = voterAddrs[k];
                rewardAmounts[k] = _amount * voteNums[k] / totalVoteNum;
                rewardTypes[k] = Constant.REWARD_VOTER;
                totalAmount += rewardAmounts[k];
            }
            if(totalAmount != 0) {
                getAccountManager().reward{value: totalAmount}(rewardAddrs, rewardAmounts);
                emit SystemReward(_info.addr, Constant.REWARD_SN, rewardAddrs, rewardTypes, rewardAmounts);
            }
        }
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