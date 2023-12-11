// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/ArrayUtil.sol";

contract SuperNodeLogic is ISuperNodeLogic, System {
    event SNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _reocrdID);
    event SNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _recordID);
    event SNStateUpdate(address _addr, uint _newState, uint _oldState);
    event SystemReward(address _nodeAddr, uint _nodeType, address[] _addrs, uint[] _rewardTypes, uint[] _amounts);

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable override {
        require(_addr != address(0), "invalid address");
        require(!existNodeAddress(_addr), "existent address");
        if(!_isUnion) {
            require(msg.value >= getPropertyValue("supernode_min_amount") * Constant.COIN, "less than min lock amount");
        } else {
            require(msg.value >= getPropertyValue("supernode_union_min_amount") * Constant.COIN, "less than min union lock amount");
        }
        require(_lockDay >= getPropertyValue("supernode_min_lockday"), "less than min lock day");
        require(bytes(_name).length >= Constant.MIN_SN_NAME_LEN && bytes(_name).length <= Constant.MAX_SN_NAME_LEN, "invalid name");
        require(!getSuperNodeStorage().existName(_name), "existent name");
        require(bytes(_enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(_enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!existNodeEnode(_enode), "existent enode");
        require(bytes(_description).length >= Constant.MIN_NODE_DESCRIPTION_LEN && bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(_creatorIncentive + _partnerIncentive + _voterIncentive == Constant.MAX_INCENTIVE, "invalid incentive");
        require(_creatorIncentive >= Constant.MIN_SN_CREATOR_INCENTIVE && _creatorIncentive <= Constant.MAX_SN_CREATOR_INCENTIVE, "creator incentive exceed 10%");
        require(_partnerIncentive >= Constant.MIN_SN_PARTNER_INCENTIVE && _partnerIncentive <= Constant.MAX_SN_PARTNER_INCENTIVE, "partner incentive is 40% - 50%");
        require(_voterIncentive >= Constant.MIN_SN_VOTER_INCENTIVE && _voterIncentive <= Constant.MAX_SN_VOTER_INCENTIVE, "creator incentive is 40% - 50%");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        getSuperNodeStorage().create(_addr, lockID, msg.value, _name, _enode, _description, ISuperNodeStorage.IncentivePlan(_creatorIncentive, _partnerIncentive, _voterIncentive));
        getAccountManager().setRecordFreezeInfo(lockID, _addr, _lockDay); // creator's lock id can't register other supernode again
        emit SNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(msg.value >= getPropertyValue("supernode_append_min_amount") * Constant.COIN, "less than min append lock amount");
        require(_lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        getSuperNodeStorage().append(_addr, lockID, msg.value);
        getAccountManager().setRecordFreezeInfo(lockID, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(block.number < record.unlockHeight, "record isn't locked");
        require(record.amount >= getPropertyValue("supernode_append_min_amount") * Constant.COIN, "less than min append lock amount");
        require(record.lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight, "record is freezen");
        getSuperNodeStorage().append(_addr, _lockID, record.amount);
        getAccountManager().setRecordFreezeInfo(_lockID, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable override onlySystemRewardContract {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(msg.value > 0, "invalid reward");
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfo(_addr);
        uint creatorReward = msg.value * info.incentivePlan.creator / Constant.MAX_INCENTIVE;
        uint partnerReward = msg.value * info.incentivePlan.partner / Constant.MAX_INCENTIVE;
        uint voterReward = msg.value - creatorReward - partnerReward;

        uint maxCount = info.founders.length + info.voteInfo.voters.length;
        address[] memory tempAddrs = new address[](maxCount);
        uint[] memory tempAmounts = new uint[](maxCount);
        uint[] memory tempRewardTypes = new uint[](maxCount);
        uint count = 0;
        // reward to creator
        if(creatorReward != 0) {
            tempAddrs[count] = info.creator;
            tempAmounts[count] = creatorReward;
            tempRewardTypes[count] = Constant.REWARD_CREATOR;
            count++;
        }

        uint minAmount = getPropertyValue("supernode_min_amount") * Constant.COIN;
        // reward to partner
        if(partnerReward != 0) {
            uint total = 0;
            for(uint i = 0; i < info.founders.length; i++) {
                ISuperNodeStorage.MemberInfo memory partner = info.founders[i];
                if(total + partner.amount <= minAmount) {
                    uint tempAmount = partnerReward * partner.amount / minAmount;
                    if(tempAmount != 0) {
                        int pos = ArrayUtil.find(tempAddrs, partner.addr);
                        if(pos == -1) {
                            tempAddrs[count] = partner.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = Constant.REWARD_PARTNER;
                            count++;
                        } else {
                            tempAmounts[uint(pos)] += tempAmount;
                        }
                    }
                    total += partner.amount;
                    if(total == minAmount) {
                        break;
                    }
                } else {
                    uint tempAmount = partnerReward * (minAmount - total) / minAmount;
                    if(tempAmount != 0) {
                        int pos = ArrayUtil.find(tempAddrs, partner.addr);
                        if(pos == -1) {
                            tempAddrs[count] = partner.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = Constant.REWARD_PARTNER;
                            count++;
                        } else {
                            tempAmounts[uint(pos)] += tempAmount;
                        }
                    }
                    break;
                }
            }
        }
        // reward to voter
        if(voterReward != 0) {
            if(info.voteInfo.voters.length > 0) {
                for(uint i = 0; i < info.voteInfo.voters.length; i++) {
                    ISuperNodeStorage.MemberInfo memory voter = info.voteInfo.voters[i];
                    uint tempAmount = voterReward * voter.amount / info.voteInfo.totalAmount;
                    if(tempAmount != 0) {
                        int pos = ArrayUtil.find(tempAddrs, voter.addr);
                        if(pos == -1) {
                            tempAddrs[count] = voter.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = Constant.REWARD_VOTER;
                            count++;
                        } else {
                            tempAmounts[uint(pos)] += tempAmount;
                        }
                    }
                }
            } else {
                // no voters, reward to creator
                tempAmounts[0] += voterReward;
            }
        }
        // reward to address
        getAccountManager().reward{value: msg.value}(tempAddrs, tempAmounts);
        emit SystemReward(_addr, Constant.REWARD_SN, tempAddrs, tempRewardTypes, tempAmounts);
        getSuperNodeStorage().updateLastRewardHeight(_addr, block.number);
    }

    function removeMember(address _addr, uint _lockID) public override onlyAccountManagerContract {
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfo(_addr);
        for(uint i = 0; i < info.founders.length; i++) {
            if(info.founders[i].lockID == _lockID) {
                if(i == 0) {
                    // unfreeze partner
                    for(uint k = 1; k < info.founders.length; k++) {
                        getAccountManager().setRecordFreezeInfo(info.founders[k].lockID, address(0), 0);
                    }
                    // release voter
                    for(uint k = 0; k < info.voteInfo.voters.length; k++) {
                        getAccountManager().setRecordVoteInfo(info.voteInfo.voters[k].lockID, address(0), 0);
                    }
                }
                getSuperNodeStorage().removeMember(_addr, i);
                return;
            }
        }
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(_newAddr != address(0), "invalid new address");
        require(!existNodeAddress(_newAddr), "existent new address");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't creator");
        getSuperNodeStorage().updateAddress(_addr, _newAddr);
        ISuperNodeStorage.SuperNodeInfo memory info = getSuperNodeStorage().getInfo(_newAddr);
        for(uint i = 0; i < info.founders.length; i++) {
            getAccountManager().updateRecordFreezeAddr(info.founders[i].lockID, _newAddr);
        }
        for(uint i = 0; i < info.voteInfo.voters.length; i++) {
            getAccountManager().updateRecordVoteAddr(info.voteInfo.voters[i].lockID, _newAddr);
        }
    }

    function changeName(address _addr, string memory _name) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(bytes(_name).length >= Constant.MIN_SN_NAME_LEN && bytes(_name).length <= Constant.MAX_SN_NAME_LEN, "invalid name");
        require(!getSuperNodeStorage().existName(_name), "existent name");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't creator");
        getSuperNodeStorage().updateName(_addr, _name);
    }

    function changeEnode(address _addr, string memory _enode) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(bytes(_enode).length >= Constant.MIN_NODE_ENODE_LEN && bytes(_enode).length <= Constant.MAX_NODE_ENODE_LEN, "invalid enode");
        require(!existNodeEnode(_enode), "existent enode");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't creator");
        getSuperNodeStorage().updateEnode(_addr, _enode);
    }

    function changeDescription(address _addr, string memory _description) public override {
        require(getSuperNodeStorage().exist(_addr), "non-existent supernode");
        require(bytes(_description).length >= Constant.MIN_NODE_DESCRIPTION_LEN && bytes(_description).length <= Constant.MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't creator");
        getSuperNodeStorage().updateDescription(_addr, _description);
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
        uint oldState = info.stateInfo.state;
        getSuperNodeStorage().updateState(info.addr, _state);
        emit SNStateUpdate(info.addr, _state, oldState);
    }

    function changeVoteInfo(address _addr, address _voter, uint _recordID, uint _amount, uint _num, uint _type) public override onlySNVoteContract {
        if(!getSuperNodeStorage().exist(_addr)) {
            return;
        }
        if(_type == 0) { // reduce vote
            getSuperNodeStorage().reduceVote(_addr, _voter, _recordID, _amount, _num);
        } else { // increase vote
            getSuperNodeStorage().increaseVote(_addr, _voter, _recordID, _amount, _num);
        }
    }
}