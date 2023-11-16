// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/ArrayUtil.sol";

contract SuperNode is ISuperNode, System {
    uint sn_no; // supernode no.
    mapping(address => SuperNodeInfo) supernodes;
    uint[] snIDs;
    mapping(uint => address) snID2addr;
    mapping(string => address) snName2addr;
    mapping(string => address) snEnode2addr;

    event SNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _reocrdID);
    event SNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _recordID);
    event SNStateUpdate(address _addr, uint _newState, uint _oldState);
    event SystemReward(address _nodeAddr, uint _nodeType, address[] _addrs, uint[] _rewardTypes, uint[] _amounts);

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable override {
        require(_addr != address(0), "invalid address");
        require(!existNodeAddress(_addr), "existent address");
        if(!_isUnion) {
            require(msg.value >= getPropertyValue("supernode_min_amount") * COIN, "less than min lock amount");
        } else {
            require(msg.value >= getPropertyValue("supernode_union_min_amount") * COIN, "less than min union lock amount");
        }
        require(_lockDay >= getPropertyValue("supernode_min_lockday"), "less than min lock day");
        require(bytes(_name).length > 0 && bytes(_name).length <= MAX_SN_NAME_LEN, "invalid name");
        require(!existName(_name), "existent name");
        require(bytes(_enode).length >= MIN_NODE_ENODE_LEN, "invalid enode");
        require(!existNodeEnode(_enode), "existent enode");
        require(bytes(_description).length > 0 && bytes(_description).length <= MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(_creatorIncentive + _partnerIncentive + _voterIncentive == MAX_INCENTIVE, "invalid incentive");
        require(_creatorIncentive > 0 && _creatorIncentive <= MAX_SN_CREATOR_INCENTIVE, "creator incentive exceed 10%");
        require(_partnerIncentive >= MIN_SN_PARTNER_INCENTIVE && _partnerIncentive <= MAX_SN_PARTNER_INCENTIVE, "partner incentive is 40% - 50%");
        require(_voterIncentive >= MIN_SN_VOTER_INCENTIVE && _voterIncentive <= MAX_SN_VOTER_INCENTIVE, "creator incentive is 40% - 50%");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        create(_addr, lockID, msg.value, _name, _enode, _description, IncentivePlan(_creatorIncentive, _partnerIncentive, _voterIncentive));
        getAccountManager().setRecordFreezeInfo(lockID, msg.sender, _addr, _lockDay); // creator's lock id can't register other supernode again
        emit SNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable override {
        require(exist(_addr), "non-existent supernode");
        require(msg.value >= getPropertyValue("supernode_append_min_amount") * COIN, "less than min append lock amount");
        require(_lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        append(_addr, lockID, msg.value);
        getAccountManager().setRecordFreezeInfo(lockID, msg.sender, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public override {
        require(exist(_addr), "non-existent supernode");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(block.number < record.unlockHeight, "record isn't locked");
        require(record.amount >= getPropertyValue("supernode_append_min_amount") * COIN, "less than min append lock amount");
        require(record.lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight, "record is freezen");
        append(_addr, _lockID, record.amount);
        getAccountManager().setRecordFreezeInfo(_lockID, msg.sender, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable override onlySystemRewardContract {
        require(exist(_addr), "non-existent supernode");
        require(msg.value > 0, "invalid reward");
        SuperNodeInfo memory info = supernodes[_addr];
        uint creatorReward = msg.value * info.incentivePlan.creator / MAX_INCENTIVE;
        uint partnerReward = msg.value * info.incentivePlan.partner / MAX_INCENTIVE;
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
            tempRewardTypes[count] = REWARD_CREATOR;
            count++;
        }

        uint minAmount = getPropertyValue("supernode_min_amount") * COIN;
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
        // reward to voter
        if(voterReward != 0) {
            if(info.voteInfo.voters.length > 0) {
                for(uint i = 0; i < info.voteInfo.voters.length; i++) {
                    MemberInfo memory voter = info.voteInfo.voters[i];
                    uint tempAmount = voterReward * voter.amount / info.voteInfo.totalAmount;
                    if(tempAmount != 0) {
                        int pos = ArrayUtil.find(tempAddrs, voter.addr);
                        if(pos == -1) {
                            tempAddrs[count] = voter.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = REWARD_VOTER;
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
        emit SystemReward(_addr, REWARD_SN, tempAddrs, tempRewardTypes, tempAmounts);
        supernodes[_addr].lastRewardHeight = block.number;
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(exist(_addr), "non-existent supernode");
        require(_newAddr != address(0), "invalid new address");
        require(!existNodeAddress(_newAddr), "existent new address");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        supernodes[_newAddr] = supernodes[_addr];
        supernodes[_newAddr].addr = _newAddr;
        supernodes[_newAddr].updateHeight = 0;
        delete supernodes[_addr];
        snID2addr[supernodes[_newAddr].id] = _newAddr;
        snEnode2addr[supernodes[_newAddr].enode] = _newAddr;
    }

    function changeName(address _addr, string memory _name) public override {
        require(exist(_addr), "non-existent supernode");
        require(bytes(_name).length > 0 && bytes(_name).length <= MAX_SN_NAME_LEN, "invalid name");
        require(!existName(_name), "existent name");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        string memory oldName = supernodes[_addr].name;
        supernodes[_addr].name = _name;
        supernodes[_addr].updateHeight = block.number;
        snName2addr[_name] = _addr;
        delete snName2addr[oldName];
    }

    function changeEnode(address _addr, string memory _enode) public override {
        require(exist(_addr), "non-existent supernode");
        require(bytes(_enode).length >= MIN_NODE_ENODE_LEN, "invalid enode");
        require(!existNodeEnode(_enode), "existent enode");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        string memory oldEnode = supernodes[_addr].enode;
        supernodes[_addr].enode = _enode;
        supernodes[_addr].updateHeight = block.number;
        snEnode2addr[_enode] = _addr;
        delete snEnode2addr[oldEnode];
    }

    function changeDescription(address _addr, string memory _description) public override {
        require(exist(_addr), "non-existent supernode");
        require(bytes(_description).length > 0 && bytes(_description).length <= MAX_NODE_DESCRIPTION_LEN, "invalid description");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        supernodes[_addr].description = _description;
        supernodes[_addr].updateHeight = block.number;
    }

    function changeIsOfficial(address _addr, bool _flag) public override onlyOwner {
        require(exist(_addr), "non-existent supernode");
        supernodes[_addr].isOfficial = _flag;
        supernodes[_addr].updateHeight = block.number;
    }

    function changeState(uint _id, uint _state) public override onlySuperNodeStateContract {
        address addr = snID2addr[_id];
        if(snID2addr[_id] == address(0)) {
            return;
        }
        uint oldState = supernodes[addr].stateInfo.state;
        supernodes[addr].stateInfo = StateInfo(_state, block.number);
        emit SNStateUpdate(supernodes[addr].addr, _state, oldState);
    }

    function changeVoteInfo(address _addr, address _voter, uint _recordID, uint _amount, uint _num, uint _type) public override onlySNVoteContract {
        SuperNodeInfo storage info = supernodes[_addr];
        if(supernodes[_addr].id == 0) {
            return;
        }
        VoteInfo storage voteInfo = info.voteInfo;
        uint pos = 0;
        bool flag = false;
        for(uint i = 0; i < voteInfo.voters.length; i++) {
            if(_voter == voteInfo.voters[i].addr && _recordID == voteInfo.voters[i].lockID) {
                pos = i;
                flag = true;
                break;
            }
        }

        if(_type == 0) { // reduce vote
            if(flag) {
                voteInfo.voters[pos] = voteInfo.voters[voteInfo.voters.length - 1];
                voteInfo.voters.pop();
            }
            if(voteInfo.totalAmount <= _amount) {
                voteInfo.totalAmount = 0;
            } else {
                voteInfo.totalAmount -= _amount;
            }
            if(voteInfo.totalNum <= _num) {
                voteInfo.totalNum = 0;
            } else {
                voteInfo.totalNum -= _num;
            }
        } else { // increase vote
            if(!flag) {
                voteInfo.voters.push(MemberInfo(_recordID, _voter, _amount, block.number));
            }
            voteInfo.totalAmount += _amount;
            voteInfo.totalNum += _num;
            voteInfo.height = block.number;
        }
    }

    function getInfo(address _addr) public view override returns (SuperNodeInfo memory) {
        require(exist(_addr), "non-existent supernode");
        return supernodes[_addr];
    }

    function getInfoByID(uint _id) public view override returns (SuperNodeInfo memory) {
        require(existID(_id), "non-existent supernode");
        return supernodes[snID2addr[_id]];
    }

    function getAll() public view override returns (SuperNodeInfo[] memory) {
        SuperNodeInfo[] memory ret = new SuperNodeInfo[](snIDs.length);
        for(uint i = 0; i < snIDs.length; i++) {
            ret[i] = supernodes[snID2addr[snIDs[i]]];
        }
        return ret;
    }

    function getTops() public view override returns (SuperNodeInfo[] memory) {
        uint minAmount = getPropertyValue("supernode_min_amount") * COIN;
        uint num = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= minAmount && supernodes[addr].stateInfo.state == NODE_STATE_START) {
                num++;
            }
        }

        address[] memory snAddrs = new address[](num);
        uint k = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= minAmount && supernodes[addr].stateInfo.state == NODE_STATE_START) {
                snAddrs[k++] = addr;
            }
        }

        // sort by vote number
        sortByVoteNum(snAddrs, 0, snAddrs.length - 1);

        // get top, max: MAX_NUM
        num = getPropertyValue("supernode_max_num");
        if(snAddrs.length < num) {
            num = snAddrs.length;
        }
        SuperNodeInfo[] memory ret = new SuperNodeInfo[](num);
        for(uint i = 0; i < num; i++) {
            ret[i] = supernodes[snAddrs[i]];
        }
        return ret;
    }

    function getOfficials() public view override returns (SuperNodeInfo[] memory) {
        uint count;
        for(uint i = 0; i < snIDs.length; i++) {
            if(supernodes[snID2addr[snIDs[i]]].isOfficial) {
                count++;
            }
        }
        SuperNodeInfo[] memory ret = new SuperNodeInfo[](count);
        uint index = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            if(supernodes[snID2addr[snIDs[i]]].isOfficial) {
                ret[index++] = supernodes[snID2addr[snIDs[i]]];
            }
        }
        return ret;
    }

    function getNum() public view override returns (uint) {
        uint minAmount = getPropertyValue("supernode_min_amount") * COIN;
        uint maxNum = getPropertyValue("supernode_max_num");
        uint num = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= minAmount) {
                num++;
            }
        }
        if(num >= maxNum) {
            return maxNum;
        }
        return num;
    }

    function exist(address _addr) public view override returns (bool) {
        return supernodes[_addr].id != 0;
    }

    function existID(uint _id) public view override returns (bool) {
        return snID2addr[_id] != address(0);
    }

    function existName(string memory _name) public view override returns (bool) {
        return snName2addr[_name] != address(0);
    }

    function existEnode(string memory _enode) public view override returns (bool) {
        return snEnode2addr[_enode] != address(0);
    }

    function existLockID(address _addr, uint _lockID) public view override returns (bool) {
        for(uint i = 0; i < supernodes[_addr].founders.length; i++) {
            if(supernodes[_addr].founders[i].lockID == _lockID) {
                return true;
            }
        }
        return false;
    }

    function create(address _addr, uint _lockID, uint _amount, string memory _name, string memory _enode, string memory _description, IncentivePlan memory _incentivePlan) internal {
        SuperNodeInfo storage sn = supernodes[_addr];
        sn.id = ++sn_no;
        sn.name = _name;
        sn.addr = _addr;
        sn.creator = msg.sender;
        sn.amount = _amount;
        sn.enode = _enode;
        sn.description = _description;
        sn.isOfficial = false;
        sn.stateInfo = StateInfo(NODE_STATE_INIT, block.number);
        sn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        sn.incentivePlan = _incentivePlan;
        sn.lastRewardHeight = 0;
        sn.createHeight = block.number;
        sn.updateHeight = 0;
        snIDs.push(sn.id);
        snID2addr[sn.id] = _addr;
        snName2addr[sn.name] = _addr;
        snEnode2addr[sn.enode] = _addr;
    }

    function append(address _addr, uint _lockID, uint _amount) internal {
        supernodes[_addr].founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        supernodes[_addr].amount += _amount;
        supernodes[_addr].updateHeight = block.number;
    }

    function sortByVoteNum(address[] memory _arr, uint _left, uint _right) internal view {
        uint i = _left;
        uint j = _right;
        if (i == j) return;
        address middle = _arr[_left + (_right - _left) / 2];
        while(i <= j) {
            while(supernodes[_arr[i]].voteInfo.totalNum > supernodes[middle].voteInfo.totalNum) i++;
            while(supernodes[middle].voteInfo.totalNum > supernodes[_arr[j]].voteInfo.totalNum && j > 0) j--;
            if(i <= j) {
                (_arr[i], _arr[j]) = (_arr[j], _arr[i]);
                i++;
                if(j != 0) j--;
            }
        }
        if(_left < j)
            sortByVoteNum(_arr, _left, j);
        if(i < _right)
            sortByVoteNum(_arr, i, _right);
    }
}