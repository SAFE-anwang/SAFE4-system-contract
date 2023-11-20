// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/ArrayUtil.sol";

contract MasterNode is IMasterNode, System {
    uint mn_no; // masternode no.
    mapping(address => MasterNodeInfo) masternodes;
    uint[] mnIDs;
    mapping(uint => address) mnID2addr;
    mapping(string => address) mnEnode2addr;

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
        create(_addr, lockID, msg.value, _enode, _description, IncentivePlan(_creatorIncentive, _partnerIncentive, 0));
        getAccountManager().setRecordFreezeInfo(lockID, msg.sender, _addr, _lockDay); // creator's lock id can't register other masternode again
        emit MNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable override {
        require(exist(_addr), "non-existent masternode");
        require(msg.value >= getPropertyValue("masternode_append_min_amount") * COIN, "less than min append lock amount");
        require(_lockDay >= getPropertyValue("masternode_append_min_lockday"), "less than min append lock day");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        append(_addr, lockID, msg.value);
        getAccountManager().setRecordFreezeInfo(lockID, msg.sender, _addr, getPropertyValue("record_masternode_freezeday")); // partner's lock id can‘t register other masternode until unfreeze it
        emit MNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public override {
        require(exist(_addr), "non-existent masternode");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(block.number < record.unlockHeight, "record isn't locked");
        require(record.amount >= getPropertyValue("masternode_append_min_amount") * COIN, "less than min append lock amount");
        require(record.lockDay >= getPropertyValue("masternode_append_min_lockday"), "less than min append lock day");
        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight, "record is freezen");
        append(_addr, _lockID, record.amount);
        getAccountManager().setRecordFreezeInfo(_lockID, msg.sender, _addr, getPropertyValue("record_masternode_freezeday")); // partner's lock id can't register other masternode until unfreeze it
        emit MNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable override onlySystemRewardContract {
        require(exist(_addr), "non-existent masternode");
        require(msg.value > 0, "invalid reward");
        MasterNodeInfo memory info = masternodes[_addr];
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
                MemberInfo memory partner = info.founders[i];
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
        masternodes[_addr].lastRewardHeight = block.number;
    }

    function removeMember(address _addr, uint _lockID) public override onlyAccountManagerContract {
        MasterNodeInfo storage info = masternodes[_addr];
        uint i;
        for(; i < info.founders.length; i++) {
            if(info.founders[i].lockID == _lockID) {
                break;
            }
        }
        if(i != info.founders.length) {
            for(uint k = i; k < info.founder.length - 1; k++) { // by order
                info.founders[k] = info.founders[k + 1];
            }
            info.founders.pop();
        }
    }

    function fromSafe3(address _addr, uint _amount, uint _lockDay, uint _lockID) public override onlySafe3Contract {
        require(!existNodeAddress(_addr), "existent address");
        require(_amount >= getPropertyValue("masternode_min_amount") * COIN, "less than min lock amount");
        create(_addr, _lockID, _amount, "", "", IncentivePlan(MAX_INCENTIVE, 0, 0));
        getAccountManager().setRecordFreezeInfo(_lockID, _addr, _addr, _lockDay);
        emit MNRegister(_addr, msg.sender, _amount, _lockDay, _lockID);
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(exist(_addr), "non-existent masternode");
        require(_newAddr != address(0), "invalid new address");
        require(!existNodeAddress(_newAddr), "existent new address");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        masternodes[_newAddr] = masternodes[_addr];
        masternodes[_newAddr].addr = _newAddr;
        masternodes[_newAddr].updateHeight = 0;
        delete masternodes[_addr];
        mnID2addr[masternodes[_newAddr].id] = _newAddr;
        mnEnode2addr[masternodes[_newAddr].enode] = _newAddr;
    }

    function changeEnode(address _addr, string memory _enode) public override {
        require(exist(_addr), "non-existent masternode");
        require(bytes(_enode).length >= MIN_NODE_ENODE_LEN, "invalid enode");
        require(!existNodeEnode(_enode), "existent enode");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        string memory oldEnode = masternodes[_addr].enode;
        masternodes[_addr].enode = _enode;
        masternodes[_addr].updateHeight = block.number;
        mnEnode2addr[_enode] = _addr;
        delete mnEnode2addr[oldEnode];
    }

    function changeDescription(address _addr, string memory _description) public override {
        require(exist(_addr), "non-existent masternode");
        require(bytes(_description).length <= MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        masternodes[_addr].description = _description;
        masternodes[_addr].updateHeight = block.number;
    }

    function changeIsOfficial(address _addr, bool _flag) public override onlyOwner {
        require(exist(_addr), "non-existent masternode");
        masternodes[_addr].isOfficial = _flag;
        masternodes[_addr].updateHeight = block.number;
    }

    function changeState(uint _id, uint _state) public override onlyMasterNodeStateContract {
        address addr = mnID2addr[_id];
        if(addr == address(0)) {
            return;
        }
        uint oldState = masternodes[addr].stateInfo.state;
        masternodes[addr].stateInfo = StateInfo(_state, block.number);
        emit MNStateUpdate(addr, _state, oldState);
    }

    function getInfo(address _addr) public view override returns (MasterNodeInfo memory) {
        require(exist(_addr), "non-existent masternode");
        return masternodes[_addr];
    }

    function getInfoByID(uint _id) public view override returns (MasterNodeInfo memory) {
        require(existID(_id), "non-existent masternode");
        return masternodes[mnID2addr[_id]];
    }

    function getNext() public view override returns (address) {
        uint minAmount = getPropertyValue("masternode_min_amount") * COIN;
        uint count = 0;
        for(uint i = 0; i < mnIDs.length; i++) {
            MasterNodeInfo memory mn = masternodes[mnID2addr[mnIDs[i]]];
            if(mn.amount < minAmount) {
                continue;
            }
            if(mn.stateInfo.state != NODE_STATE_START) {
                continue;
            }
            count++;
        }
        if(count != 0) {
            MasterNodeInfo[] memory mns = new MasterNodeInfo[](count);
            uint index = 0;
            for(uint i = 0; i < mnIDs.length; i++) {
                MasterNodeInfo memory mn = masternodes[mnID2addr[mnIDs[i]]];
                if(mn.amount < minAmount) {
                    continue;
                }
                if(mn.stateInfo.state != NODE_STATE_START) {
                    continue;
                }
                mns[index++] = mn;
            }
            sortByRewardHeight(mns, 0, mns.length - 1);
            return mns[0].addr;
        }
        // select official masternodes
        MasterNodeInfo[] memory officials = getOfficials();
        if(officials.length != 0) {
            sortByRewardHeight(officials, 0, officials.length - 1);
            return officials[block.number % officials.length].addr;
        } else {
            return mnID2addr[(block.number % mn_no) + 1];
        }
    }

    function getAll() public view override returns (MasterNodeInfo[] memory) {
        MasterNodeInfo[] memory ret = new MasterNodeInfo[](mnIDs.length);
        for(uint i = 0; i < mnIDs.length; i++) {
            ret[i] = masternodes[mnID2addr[mnIDs[i]]];
        }
        return ret;
    }

    function getOfficials() public view override returns (MasterNodeInfo[] memory) {
        uint count;
        for(uint i = 0; i < mnIDs.length; i++) {
            if(masternodes[mnID2addr[mnIDs[i]]].isOfficial) {
                count++;
            }
        }
        MasterNodeInfo[] memory ret = new MasterNodeInfo[](count);
        uint index = 0;
        for(uint i = 0; i < mnIDs.length; i++) {
            if(masternodes[mnID2addr[mnIDs[i]]].isOfficial) {
                ret[index++] = masternodes[mnID2addr[mnIDs[i]]];
            }
        }
        return ret;
    }

    function getNum() public view override returns (uint) {
        return mnIDs.length;
    }

    function exist(address _addr) public view override returns (bool) {
        return masternodes[_addr].id != 0;
    }

    function existID(uint _id) public view override returns (bool) {
        return mnID2addr[_id] != address(0);
    }

    function existEnode(string memory _enode) public view override returns (bool) {
        return mnEnode2addr[_enode] != address(0);
    }

    function existLockID(address _addr, uint _lockID) public view override returns (bool) {
        MasterNodeInfo memory mn = masternodes[_addr];
        for(uint i = 0; i < mn.founders.length; i++) {
            if(mn.founders[i].lockID == _lockID) {
                return true;
            }
        }
        return false;
    }

    function isValid(address _addr) public view override returns (bool) {
        MasterNodeInfo memory info = masternodes[_addr];
        if(info.id == 0) {
            return false;
        }
        uint minAmount = getPropertyValue("masternode_min_amount") * COIN;
        if(info.amount < minAmount) {
            return false;
        }
        IAccountManager.AccountRecord memory record;
        uint lockAmount;
        for(uint i = 0;; i < info.founders.length; i++) {
            record = getAccountManager().getRecordByID(info.founders[i].lockID);
            if(record.unlockHeight > block.number) {
                lockAmount += record.amount;
            }
        }
        if(lockAmount < minAmount) {
            return false;
        }
        return true;
    }

    function create(address _addr, uint _lockID, uint _amount, string memory _enode, string memory _description, IncentivePlan memory plan) internal {
        MasterNodeInfo storage mn = masternodes[_addr];
        mn.id = ++mn_no;
        mn.addr = _addr;
        mn.creator = msg.sender;
        mn.amount = _amount;
        mn.enode = _enode;
        mn.description = _description;
        mn.isOfficial = false;
        mn.stateInfo = StateInfo(NODE_STATE_INIT, block.number);
        mn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        mn.incentivePlan = plan;
        mn.lastRewardHeight = 0;
        mn.createHeight = block.number;
        mn.updateHeight = 0;
        mnIDs.push(mn.id);
        mnID2addr[mn.id] = _addr;
        mnEnode2addr[mn.enode] = _addr;
    }


    function append(address _addr, uint _lockID, uint _amount) internal {
        masternodes[_addr].founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        masternodes[_addr].amount += _amount;
        masternodes[_addr].updateHeight = block.number;
    }

    // ASC by lastRewardHeight
    function sortByRewardHeight(MasterNodeInfo[] memory _arr, uint _left, uint _right) internal pure {
        uint i = _left;
        uint j = _right;
        if (i == j) return;
        MasterNodeInfo memory middle = _arr[_left + (_right - _left) / 2];
        while(i <= j) {
            while(_arr[i].lastRewardHeight < middle.lastRewardHeight) i++;
            while(middle.lastRewardHeight < _arr[j].lastRewardHeight && j > 0) j--;
            if(i <= j) {
                (_arr[i], _arr[j]) = (_arr[j], _arr[i]);
                i++;
                if(j != 0) j--;
            }
        }
        if(_left < j)
            sortByRewardHeight(_arr, _left, j);
        if(i < _right)
            sortByRewardHeight(_arr, i, _right);
    }
}