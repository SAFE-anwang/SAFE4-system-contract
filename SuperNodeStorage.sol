// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/ArrayUtil.sol";

contract SuperNodeStorage is ISuperNodeStorage, System {
    uint sn_no; // supernode no.
    mapping(address => SuperNodeInfo) supernodes;
    uint[] snIDs;
    mapping(uint => address) snID2addr;
    mapping(string => address) snName2addr;
    mapping(string => address) snEnode2addr;

    function create(address _addr, uint _lockID, uint _amount, string memory _name, string memory _enode, string memory _description, IncentivePlan memory _incentivePlan) public override onlySuperNodeLogic {
        SuperNodeInfo storage sn = supernodes[_addr];
        sn.id = ++sn_no;
        sn.name = _name;
        sn.addr = _addr;
        sn.creator = msg.sender;
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

    function append(address _addr, uint _lockID, uint _amount) public override onlySuperNodeLogic {
        supernodes[_addr].founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        supernodes[_addr].updateHeight = block.number;
    }

    function updateAddress(address _addr, address _newAddr) public override onlySuperNodeLogic {
        supernodes[_newAddr] = supernodes[_addr];
        supernodes[_newAddr].addr = _newAddr;
        supernodes[_newAddr].updateHeight = 0;
        delete supernodes[_addr];
        snID2addr[supernodes[_newAddr].id] = _newAddr;
        snEnode2addr[supernodes[_newAddr].enode] = _newAddr;
    }

    function updateName(address _addr, string memory _name) public override onlySuperNodeLogic {
        string memory oldName = supernodes[_addr].name;
        supernodes[_addr].name = _name;
        supernodes[_addr].updateHeight = block.number;
        snName2addr[_name] = _addr;
        delete snName2addr[oldName];
    }

    function updateEnode(address _addr, string memory _enode) public override onlySuperNodeLogic {
        string memory oldEnode = supernodes[_addr].enode;
        supernodes[_addr].enode = _enode;
        supernodes[_addr].updateHeight = block.number;
        snEnode2addr[_enode] = _addr;
        delete snEnode2addr[oldEnode];
    }

    function updateDescription(address _addr, string memory _description) public override onlySuperNodeLogic {
        supernodes[_addr].description = _description;
        supernodes[_addr].updateHeight = block.number;
    }

    function updateIsOfficial(address _addr, bool _flag) public override onlySuperNodeLogic {
        if(tx.origin != owner()) {
            return;
        }
        supernodes[_addr].isOfficial = _flag;
        supernodes[_addr].updateHeight = block.number;
    }

    function updateState(address _addr, uint _state) public override onlySuperNodeLogic {
        supernodes[_addr].stateInfo = StateInfo(_state, block.number);
    }

    function removeMember(address _addr, uint _index) public override onlySuperNodeLogic {
        if(_index == 0) {
            dissolve(_addr);
        } else {
            SuperNodeInfo storage info = supernodes[_addr];
            for(uint i = _index; i < info.founders.length - 1; i++) { // by order
                info.founders[i] = info.founders[i + 1];
            }
            info.founders.pop();
        }
    }

    function dissolve(address _addr) public override onlySuperNodeLogic {
        SuperNodeInfo storage info = supernodes[_addr];
        // unfreeze partner
        for(uint k = 1; k < info.founders.length; k++) {
            getAccountManager().setRecordFreezeInfo(info.founders[k].lockID, _addr, address(0), 0);
        }
        // release voter
        for(uint k = 0; k < info.voteInfo.voters.length; k++) {
            getAccountManager().setRecordVoteInfo(info.voteInfo.voters[k].lockID, info.voteInfo.voters[k].addr, address(0), 0);
        }
        // remove id
        uint pos;
        for(uint k = 0; k < snIDs.length; k++) {
            if(snIDs[k] == info.id) {
                pos = k;
                break;
            }
        }
        for(; pos < snIDs.length - 1; pos++) {
            snIDs[pos] = snIDs[pos + 1];
        }
        snIDs.pop();
        // remove id2addr
        delete snID2addr[info.id];
        // remove enode2addr
        delete snName2addr[info.name];
        // remove enode2addr
        delete snEnode2addr[info.enode];
        // remove sn
        delete supernodes[_addr];
    }

    function reduceVote(address _addr, address _voter, uint _recordID, uint _amount, uint _num) public override onlySuperNodeLogic {
        VoteInfo storage voteInfo = supernodes[_addr].voteInfo;
        uint i;
        for(; i < voteInfo.voters.length; i++) {
            if(_voter == voteInfo.voters[i].addr && _recordID == voteInfo.voters[i].lockID) {
                break;
            }
        }
        if(i == voteInfo.voters.length) {
            return;
        }
        voteInfo.voters[i] = voteInfo.voters[voteInfo.voters.length - 1];
        voteInfo.voters.pop();

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
    }

    function increaseVote(address _addr, address _voter, uint _recordID, uint _amount, uint _num) public override onlySuperNodeLogic {
        VoteInfo storage voteInfo = supernodes[_addr].voteInfo;
        voteInfo.voters.push(MemberInfo(_recordID, _voter, _amount, block.number));
        voteInfo.totalAmount += _amount;
        voteInfo.totalNum += _num;
        voteInfo.height = block.number;
    }

    function updateLastRewardHeight(address _addr, uint _height) public override onlySuperNodeLogic {
        supernodes[_addr].lastRewardHeight = _height;
    }

    function getInfo(address _addr) public view override returns (SuperNodeInfo memory) {
        return supernodes[_addr];
    }

    function getInfoByID(uint _id) public view override returns (SuperNodeInfo memory) {
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
        address[] memory snAddrs = new address[](snIDs.length);
        uint num = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            SuperNodeInfo memory info = supernodes[addr];
            if(info.stateInfo.state != NODE_STATE_START) {
                continue;
            }
            uint lockAmount;
            // check creator
            IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(info.founders[0].lockID);
            if(block.number >= record.unlockHeight) { // creator must be locked
                continue;
            }
            lockAmount += record.amount;
            // check partner
            for(uint k = 1; k < info.founders.length; k++) {
                record = getAccountManager().getRecordByID(info.founders[k].lockID);
                if(block.number < record.unlockHeight) {
                    lockAmount += record.amount;
                }
            }
            if(lockAmount < minAmount) {
                continue;
            }
            snAddrs[num++] = addr;
        }
        if(num > 1) {
            // sort by vote number
            sortByVoteNum(snAddrs, 0, num - 1);
        }

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
        return getTops().length;
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

    function isValid(address _addr) public view override returns (bool) {
        SuperNodeInfo memory info = supernodes[_addr];
        if(info.id == 0) {
            return false;
        }
        IAccountManager.AccountRecord memory record;
        uint lockAmount;
        for(uint i = 0; i < info.founders.length; i++) {
            record = getAccountManager().getRecordByID(info.founders[i].lockID);
            if(record.unlockHeight > block.number) {
                lockAmount += record.amount;
            }
        }
        if(lockAmount < getPropertyValue("supernode_min_amount") * COIN) {
            return false;
        }
        return true;
    }

    function isFormal(address _addr) public view override returns (bool) {
        if(!isValid(_addr)) {
            return false;
        }
        SuperNodeInfo[] memory tops = getTops();
        for(uint i = 0; i < tops.length; i++) {
            if(_addr == tops[i].addr) {
                return true;
            }
        }
        return false;
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