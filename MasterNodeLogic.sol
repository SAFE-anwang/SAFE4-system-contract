// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/ArrayUtil.sol";

contract MasterNodeLogic is IMasterNodeLogic, System {
    event MNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _lockID);
    event MNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _lockID);
    event MNStateUpdate(address _addr, uint _newState, uint _oldState);
    event SystemReward(address _nodeAddr, uint _nodeType, address[] _addrs, uint[] _rewardTypes, uint[] _amounts);

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive) public payable override {
        require(_addr != address(0), "invalid address");
        require(!existNodeAddress(_addr), "existent address");
        if(!_isUnion) {
            require(msg.value >= getPropertyValue("masternode_min_amount") * COIN, "less than min lock amount");
        } else {
            require(msg.value >= getPropertyValue("masternode_union_min_amount") * COIN, "less than min union lock amount");
        }
        require(_lockDay >= getPropertyValue("masternode_min_lockday"), "less than min lock day");
        require(bytes(_enode).length >= MIN_NODE_ENODE_LEN, "invalid enode");
        require(!existNodeEnode(_enode), "existent enode");
        require(bytes(_description).length <= MAX_NODE_DESCRIPTION_LEN, "invalid description");
        if(!_isUnion) {
            require(_creatorIncentive == MAX_INCENTIVE && _partnerIncentive == 0, "invalid incentive");
        } else {
            require(_creatorIncentive > 0 && _creatorIncentive <= MAX_MN_CREATOR_INCENTIVE && _creatorIncentive + _partnerIncentive == MAX_INCENTIVE, "invalid incentive");
        }
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        getMasterNodeStorage().create(_addr, lockID, msg.value, _enode, _description, IMasterNodeStorage.IncentivePlan(_creatorIncentive, _partnerIncentive, 0));
        getAccountManager().setRecordFreezeInfo(lockID, msg.sender, _addr, _lockDay); // creator's lock id can't register other masternode again
        emit MNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(msg.value >= getPropertyValue("masternode_append_min_amount") * COIN, "less than min append lock amount");
        require(_lockDay >= getPropertyValue("masternode_append_min_lockday"), "less than min append lock day");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        getMasterNodeStorage().append(_addr, lockID, msg.value);
        getAccountManager().setRecordFreezeInfo(lockID, msg.sender, _addr, getPropertyValue("record_masternode_freezeday")); // partner's lock id can‘t register other masternode until unfreeze it
        emit MNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(block.number < record.unlockHeight, "record isn't locked");
        require(record.amount >= getPropertyValue("masternode_append_min_amount") * COIN, "less than min append lock amount");
        require(record.lockDay >= getPropertyValue("masternode_append_min_lockday"), "less than min append lock day");
        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight, "record is freezen");
        getMasterNodeStorage().append(_addr, _lockID, record.amount);
        getAccountManager().setRecordFreezeInfo(_lockID, msg.sender, _addr, getPropertyValue("record_masternode_freezeday")); // partner's lock id can't register other masternode until unfreeze it
        emit MNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable override onlySystemRewardContract {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(msg.value > 0, "invalid reward");
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfo(_addr);
        uint creatorReward = msg.value * info.incentivePlan.creator / MAX_INCENTIVE;
        uint partnerReward = msg.value* info.incentivePlan.partner / MAX_INCENTIVE;

        uint maxCount = info.founders.length;
        address[] memory tempAddrs = new address[](maxCount);
        uint[] memory tempAmounts = new uint[](maxCount);
        uint[] memory tempRewardTypes = new uint[](maxCount);
        uint count = 0;
        // reward to creator
        if(creatorReward != 0) {
            tempAddrs[count] = info.creator;
            tempAmounts[count] = creatorReward;
            tempRewardTypes[count] = REWARD_CREATOR;
            count++;
        }

        uint minAmount = getPropertyValue("masternode_min_amount") * COIN;
        // reward to partner
        if(partnerReward != 0) {
            uint total = 0;
            for(uint i = 0; i < info.founders.length; i++) {
                IMasterNodeStorage.MemberInfo memory partner = info.founders[i];
                if(total + partner.amount <= minAmount) {
                    uint tempAmount = partnerReward * partner.amount / minAmount;
                    if(tempAmount != 0) {
                        int pos = ArrayUtil.find(tempAddrs, partner.addr);
                        if(pos == -1) {
                            tempAddrs[count] = partner.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = REWARD_PARTNER;
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
                            tempRewardTypes[count] = REWARD_PARTNER;
                            count++;
                        } else {
                            tempAmounts[uint(pos)] += tempAmount;
                        }
                    }
                    break;
                }
            }
        }
        // reward to address
        getAccountManager().reward{value: msg.value}(tempAddrs, tempAmounts);
        emit SystemReward(_addr, REWARD_MN, tempAddrs, tempRewardTypes, tempAmounts);
        getMasterNodeStorage().updateLastRewardHeight(_addr, block.number);
    }

    function removeMember(address _addr, uint _lockID) public override onlyAccountManagerContract {
        IMasterNodeStorage.MasterNodeInfo memory info = getMasterNodeStorage().getInfo(_addr);
        for(uint i = 0; i < info.founders.length; i++) {
            if(info.founders[i].lockID == _lockID) {
                getMasterNodeStorage().removeMember(_addr, i);
                return;
            }
        }
    }

    function fromSafe3(address _addr, uint _amount, uint _lockDay, uint _lockID) public override onlySafe3Contract {
        require(!existNodeAddress(_addr), "existent address");
        require(_amount >= getPropertyValue("masternode_min_amount") * COIN, "less than min lock amount");
        getMasterNodeStorage().create(_addr, _lockID, _amount, "", "", IMasterNodeStorage.IncentivePlan(MAX_INCENTIVE, 0, 0));
        getAccountManager().setRecordFreezeInfo(_lockID, _addr, _addr, _lockDay);
        emit MNRegister(_addr, msg.sender, _amount, _lockDay, _lockID);
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(_newAddr != address(0), "invalid new address");
        require(!existNodeAddress(_newAddr), "existent new address");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't masternode creator");
        getMasterNodeStorage().updateAddress(_addr, _newAddr);
    }

    function changeEnode(address _addr, string memory _enode) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(bytes(_enode).length >= MIN_NODE_ENODE_LEN, "invalid enode");
        require(!existNodeEnode(_enode), "existent enode");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't masternode creator");
        getMasterNodeStorage().updateEnode(_addr, _enode);
    }

    function changeDescription(address _addr, string memory _description) public override {
        require(getMasterNodeStorage().exist(_addr), "non-existent masternode");
        require(bytes(_description).length <= MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(msg.sender == getSuperNodeStorage().getInfo(_addr).creator, "caller isn't masternode creator");
        getMasterNodeStorage().updateDescription(_addr, _description);
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
        uint oldState = info.stateInfo.state;
        getMasterNodeStorage().updateState(info.addr, _state);
        emit MNStateUpdate(info.addr, _state, oldState);
    }
}