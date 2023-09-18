// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./utils/SafeMath.sol";
import "./utils/NodeUtil.sol";

contract SuperNode is ISuperNode, System {
    using SafeMath for uint256;

    uint internal constant COIN = 1000000000000000000;

    uint8 internal constant STATE_INIT   = 0;
    uint8 internal constant STATE_START  = 1;
    uint8 internal constant STATE_STOP   = 2;

    uint sn_no; // supernode no.
    mapping(address => SuperNodeInfo) supernodes;
    uint[] snIDs;
    mapping(uint => address) snID2addr;
    mapping(string => address) snName2addr;
    mapping(string => address) snIP2addr;

    receive() external payable {}
    fallback() external payable {}

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable {
        require(_addr != msg.sender, "address can't be caller");
        require(!existNodeAddress(_addr), "existent address");
        if(!_isUnion) {
            require(msg.value >= getPropertyValue("supernode_min_amount") * COIN, "less than min lock amount");
        } else {
            require(msg.value >= getPropertyValue("supernode_union_min_amount") * COIN, "less than min union lock amount");
        }
        require(_lockDay >= getPropertyValue("supernode_min_lockday"), "less than min lock day");
        require(bytes(_name).length > 0 && bytes(_name).length <= 1024, "invalid name");
        require(!existName(_name), "existent name");
        string memory ip = NodeUtil.check(2, _isUnion, _addr, _enode, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
        require(!existNodeIP(ip), "existent ip");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        IncentivePlan memory plan = IncentivePlan(_creatorIncentive, _partnerIncentive, _voterIncentive);
        create(_addr, lockID, msg.value, _name, _enode, ip, _description, plan);
        getAccountManager().setRecordFreeze(lockID, msg.sender, _addr, _lockDay); // creator's lock id can't register other supernode again
        emit SNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable {
        require(exist(_addr), "non-existent supernode");
        require(msg.value >= getPropertyValue("supernode_append_min_amount") * COIN, "less than min append lock amount");
        require(_lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        uint lockID = getAccountManager().deposit{value: msg.value}(msg.sender, _lockDay);
        append(_addr, lockID, msg.value);
        getAccountManager().setRecordFreeze(lockID, msg.sender, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public {
        require(exist(_addr), "non-existent supernode");
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(block.number < record.unlockHeight, "record isn't locked");
        require(record.amount >= getPropertyValue("supernode_append_min_amount") * COIN, "less than min append lock amount");
        require(record.lockDay >= getPropertyValue("supernode_append_min_lockday"), "less than min append lock day");
        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight, "record is freezen");
        append(_addr, _lockID, record.amount);
        getAccountManager().setRecordFreeze(_lockID, msg.sender, _addr, getPropertyValue("record_supernode_freezeday")); // partner's lock id can't register other supernode until unfreeze it
        emit SNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable onlySystemRewardContract {
        require(msg.value > 0, "invalid reward");
        SuperNodeInfo memory info = supernodes[_addr];
        uint creatorReward = msg.value.mul(info.incentivePlan.creator).div(100);
        uint partnerReward = msg.value.mul(info.incentivePlan.partner).div(100);
        uint voterReward = msg.value.sub(creatorReward).sub(partnerReward);

        uint maxCount = info.founders.length + info.voteInfo.voters.length;
        address[] memory tempAddrs = new address[](maxCount);
        uint[] memory tempAmounts = new uint[](maxCount);
        uint[] memory tempRewardTypes = new uint[](maxCount);
        uint count = 0;
        // reward to creator
        if(creatorReward != 0) {
            tempAddrs[count] = info.creator;
            tempAmounts[count] = creatorReward;
            tempRewardTypes[count] = 1;
            count++;
        }

        uint minAmount = getPropertyValue("supernode_min_amount") * COIN;
        // reward to partner
        if(partnerReward != 0) {
            uint total = 0;
            for(uint i = 0; i < info.founders.length; i++) {
                MemberInfo memory partner = info.founders[i];
                if(total.add(partner.amount) <= minAmount) {
                    uint tempAmount = partnerReward.mul(partner.amount).div(minAmount);
                    if(tempAmount != 0) {
                        int pos = NodeUtil.find(tempAddrs, partner.addr);
                        if(pos == -1) {
                            tempAddrs[count] = partner.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = 2;
                            count++;
                        } else {
                            tempAmounts[uint(pos)] += tempAmount;
                        }
                    }
                    total = total.add(partner.amount);
                    if(total == minAmount) {
                        break;
                    }
                } else {
                    uint tempAmount = partnerReward.mul(minAmount.sub(total)).div(minAmount);
                    if(tempAmount != 0) {
                        int pos = NodeUtil.find(tempAddrs, partner.addr);
                        if(pos == -1) {
                            tempAddrs[count] = partner.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = 2;
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
                    uint tempAmount = voterReward.mul(voter.amount).div(info.voteInfo.totalAmount);
                    if(tempAmount != 0) {
                        int pos = NodeUtil.find(tempAddrs, voter.addr);
                        if(pos == -1) {
                            tempAddrs[count] = voter.addr;
                            tempAmounts[count] = tempAmount;
                            tempRewardTypes[count] = 3;
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

        for(uint i = 0; i < count; i++) {
            getAccountManager().reward{value: tempAmounts[i]}(tempAddrs[i]);
            emit SystemReward(_addr, 1, tempAddrs[i], tempRewardTypes[i], tempAmounts[i]);
        }
        supernodes[_addr].lastRewardHeight = block.number + 1;
    }

    function changeAddress(address _addr, address _newAddr) public {
        require(exist(_addr), "non-existent supernode");
        require(!existNodeAddress(_newAddr), "existent new address");
        require(_newAddr != address(0), "invalid new address");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        SuperNodeInfo storage newSN = supernodes[_newAddr];
        newSN = supernodes[_addr];
        newSN.addr = _newAddr;
        newSN.updateHeight = 0;
        snID2addr[newSN.id] = _newAddr;
        snIP2addr[newSN.ip] = _newAddr;
        delete supernodes[_addr];
    }

    function changeName(address _addr, string memory _name) public {
        require(exist(_addr), "non-existent supernode");
        require(!existName(_name), "existent name");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        string memory oldName = supernodes[_addr].name;
        supernodes[_addr].name = _name;
        supernodes[_addr].updateHeight = block.number + 1;
        snName2addr[_name] = _addr;
        delete snName2addr[oldName];
    }

    function changeEnode(address _addr, string memory _enode) public {
        require(exist(_addr), "non-existent supernode");
        string memory ip = NodeUtil.checkEnode(_enode);
        require(!existNodeIP(ip), "existent ip of new enode");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        string memory oldIP = supernodes[_addr].ip;
        supernodes[_addr].ip = ip;
        supernodes[_addr].updateHeight = block.number + 1;
        snIP2addr[ip] = _addr;
        delete snIP2addr[oldIP];
    }

    function changeDescription(address _addr, string memory _description) public {
        require(exist(_addr), "non-existent supernode");
        require(bytes(_description).length > 0, "invalid description");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        supernodes[_addr].description = _description;
        supernodes[_addr].updateHeight = block.number + 1;
    }

    function changeOfficial(address _addr, bool _flag) public onlyOwner {
        require(exist(_addr), "non-existent supernode");
        supernodes[_addr].isOfficial = _flag;
        supernodes[_addr].updateHeight = block.number + 1;
    }

    function changeState(uint _id, uint8 _state) public onlySuperNodeStateContract {
        address addr = snID2addr[_id];
        if(snID2addr[_id] == address(0)) {
            return;
        }
        SuperNodeInfo storage sn = supernodes[addr];
        uint8 oldState = sn.stateInfo.state;
        sn.stateInfo = StateInfo(_state, block.number + 1);
        emit SNStateUpdate(sn.addr, _state, oldState);
    }

    function changeVoteInfo(address _addr, address _voter, uint _recordID, uint _amount, uint _num, uint _type) public onlySNVoteContract {
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
                voteInfo.voters.push(MemberInfo(_recordID, _voter, _amount, block.number + 1));
            }
            voteInfo.totalAmount += _amount;
            voteInfo.totalNum += _num;
            voteInfo.height = block.number + 1;
        }
    }

    function getInfo(address _addr) public view returns (SuperNodeInfo memory) {
        require(exist(_addr), "non-existent supernode");
        return supernodes[_addr];
    }

    function getInfoByID(uint _id) public view returns (SuperNodeInfo memory) {
        return supernodes[snID2addr[_id]];
    }

    function getAll() public view returns (SuperNodeInfo[] memory) {
        SuperNodeInfo[] memory ret = new SuperNodeInfo[](snIDs.length);
        for(uint i = 0; i < snIDs.length; i++) {
            ret[i] = supernodes[snID2addr[snIDs[i]]];
        }
        return ret;
    }

    function getTop() public view returns (SuperNodeInfo[] memory) {
        uint minAmount = getPropertyValue("supernode_min_amount") * COIN;
        uint num = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= minAmount) {
                num++;
            }
        }

        address[] memory snAddrs = new address[](num);
        uint k = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= minAmount) {
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

    function getOfficials() public view returns (SuperNodeInfo[] memory) {
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

    function getNum() public view returns (uint) {
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

    function exist(address _addr) public view returns (bool) {
        return supernodes[_addr].id != 0;
    }

    function existID(uint _id) public view returns (bool) {
        return snID2addr[_id] != address(0);
    }

    function existIP(string memory _ip) public view returns (bool) {
        return snIP2addr[_ip] != address(0);
    }

    function existName(string memory _name) public view returns (bool) {
        return snName2addr[_name] != address(0);
    }

    function existLockID(address _addr, uint _lockID) public view returns (bool) {
        for(uint i = 0; i < supernodes[_addr].founders.length; i++) {
            if(supernodes[_addr].founders[i].lockID == _lockID) {
                return true;
            }
        }
        return false;
    }

    function create(address _addr, uint _lockID, uint _amount, string memory _name, string memory _enode, string memory _ip, string memory _description, IncentivePlan memory _incentivePlan) internal {
        SuperNodeInfo storage sn = supernodes[_addr];
        sn.id = ++sn_no;
        sn.name = _name;
        sn.addr = _addr;
        sn.creator = msg.sender;
        sn.amount = _amount;
        sn.enode = _enode;
        sn.ip = _ip;
        sn.description = _description;
        sn.isOfficial = false;
        sn.stateInfo = StateInfo(STATE_INIT, block.number + 1);
        sn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number + 1));
        sn.incentivePlan = _incentivePlan;
        sn.lastRewardHeight = 0;
        sn.createHeight = block.number + 1;
        sn.updateHeight = 0;
        snIDs.push(sn.id);
        snID2addr[sn.id] = _addr;
        snIP2addr[sn.ip] = _addr;
        snName2addr[sn.name] = _addr;
    }

    function append(address _addr, uint _lockID, uint _amount) internal {
        supernodes[_addr].founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number + 1));
        supernodes[_addr].amount += _amount;
        supernodes[_addr].updateHeight = block.number + 1;
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