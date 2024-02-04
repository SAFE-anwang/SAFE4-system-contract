// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/ArrayUtil.sol";

contract SuperNodeStorage is ISuperNodeStorage, System {
    uint no; // supernode no.
    mapping(address => SuperNodeInfo) addr2info;
    uint[] ids;
    mapping(uint => address) id2addr;
    mapping(string => address) name2addr;
    mapping(string => address) enode2addr;

    function create(address _addr, uint _lockID, uint _amount, string memory _name, string memory _enode, string memory _description, IncentivePlan memory _incentivePlan) public override onlySuperNodeLogic {
        SuperNodeInfo storage info = addr2info[_addr];
        info.id = ++no;
        info.name = _name;
        info.addr = _addr;
        info.creator = tx.origin;
        info.enode = _enode;
        info.description = _description;
        info.isOfficial = false;
        info.state = Constant.NODE_STATE_INIT;
        info.founders.push(MemberInfo(_lockID, tx.origin, _amount, block.number));
        info.incentivePlan = _incentivePlan;
        info.lastRewardHeight = 0;
        info.createHeight = block.number;
        info.updateHeight = 0;
        ids.push(info.id);
        id2addr[info.id] = _addr;
        name2addr[info.name] = _addr;
        enode2addr[info.enode] = _addr;
    }

    function append(address _addr, uint _lockID, uint _amount) public override onlySuperNodeLogic {
        addr2info[_addr].founders.push(MemberInfo(_lockID, tx.origin, _amount, block.number));
        addr2info[_addr].updateHeight = block.number;
    }

    function updateAddress(address _addr, address _newAddr) public override onlySuperNodeLogic {
        addr2info[_newAddr] = addr2info[_addr];
        addr2info[_newAddr].addr = _newAddr;
        addr2info[_newAddr].updateHeight = 0;
        delete addr2info[_addr];
        id2addr[addr2info[_newAddr].id] = _newAddr;
        enode2addr[addr2info[_newAddr].enode] = _newAddr;
    }

    function updateName(address _addr, string memory _name) public override onlySuperNodeLogic {
        string memory oldName = addr2info[_addr].name;
        addr2info[_addr].name = _name;
        addr2info[_addr].updateHeight = block.number;
        name2addr[_name] = _addr;
        delete name2addr[oldName];
    }

    function updateEnode(address _addr, string memory _enode) public override onlySuperNodeLogic {
        string memory oldEnode = addr2info[_addr].enode;
        addr2info[_addr].enode = _enode;
        addr2info[_addr].updateHeight = block.number;
        enode2addr[_enode] = _addr;
        delete enode2addr[oldEnode];
    }

    function updateDescription(address _addr, string memory _description) public override onlySuperNodeLogic {
        addr2info[_addr].description = _description;
        addr2info[_addr].updateHeight = block.number;
    }

    function updateIsOfficial(address _addr, bool _flag) public override onlySuperNodeLogic {
        if(tx.origin != owner()) {
            return;
        }
        addr2info[_addr].isOfficial = _flag;
        addr2info[_addr].updateHeight = block.number;
    }

    function updateState(address _addr, uint _state) public override onlySuperNodeLogic {
        addr2info[_addr].state = _state;
        addr2info[_addr].updateHeight = block.number;
    }

    function removeMember(address _addr, uint _index) public override onlySuperNodeLogic {
        if(_index == 0) {
            dissolve(_addr);
        } else {
            SuperNodeInfo storage info = addr2info[_addr];
            if(_index >= info.founders.length) {
                return;
            }
            for(uint i = _index; i < info.founders.length - 1; i++) { // by order
                info.founders[i] = info.founders[i + 1];
            }
            info.founders.pop();
            info.updateHeight = block.number;
        }
    }

    function dissolve(address _addr) public override onlySuperNodeLogic {
        SuperNodeInfo memory info = addr2info[_addr];
        // remove id
        uint pos;
        for(uint i; i < ids.length; i++) {
            if(ids[i] == info.id) {
                pos = i;
                break;
            }
        }
        for(; pos < ids.length - 1; pos++) {
            ids[pos] = ids[pos + 1];
        }
        ids.pop();
        // remove id2addr
        delete id2addr[info.id];
        // remove enode2addr
        delete name2addr[info.name];
        // remove enode2addr
        delete enode2addr[info.enode];
        // remove info
        delete addr2info[_addr];
    }

    function updateLastRewardHeight(address _addr, uint _height) public override onlySuperNodeLogic {
        addr2info[_addr].lastRewardHeight = _height;
        addr2info[_addr].updateHeight = block.number;
    }

    function getInfo(address _addr) public view override returns (SuperNodeInfo memory) {
        return addr2info[_addr];
    }

    function getInfoByID(uint _id) public view override returns (SuperNodeInfo memory) {
        return addr2info[id2addr[_id]];
    }

    function getNum() public view override returns (uint) {
        return ids.length;
    }

    function getAll(uint _start, uint _count) public view override returns (address[] memory) {
        require(_start < ids.length, "invalid _start, exceed supernode number");
        require(_count > 0 && _count <= 100, "return 1-100 supernodes");

        address[] memory addrs = new address[](ids.length);
        for(uint i; i < ids.length; i++) {
            addrs[i] = id2addr[ids[i]];
        }
        sortByVoteNum(addrs, 0, ids.length - 1);

        uint num = _count;
        if(_start + _count >= ids.length) {
            num = ids.length - _start;
        }
        address[] memory ret = new address[](num);
        for(uint i; i < num; i++) {
            ret[i] = addrs[i + _start];
        }
        return ret;
    }

    function getTops() public view override returns (address[] memory) {
        uint minAmount = getPropertyValue("supernode_min_amount") * Constant.COIN;
        address[] memory addrs = new address[](ids.length);
        uint num;
        for(uint i; i < ids.length; i++) {
            address addr = id2addr[ids[i]];
            SuperNodeInfo memory info = addr2info[addr];
            if(info.state != Constant.NODE_STATE_START) {
                continue;
            }
            uint lockAmount;
            // check creator
            if(block.number >= getAccountManager().getRecordByID(info.founders[0].lockID).unlockHeight) { // creator must be locked
                continue;
            }
            lockAmount += info.founders[0].amount;
            // check partner
            for(uint k = 1; k < info.founders.length; k++) {
                if(block.number < getAccountManager().getRecordByID(info.founders[k].lockID).unlockHeight) {
                    lockAmount += info.founders[k].amount;
                }
            }
            if(lockAmount < minAmount) {
                continue;
            }
            addrs[num++] = addr;
        }

        if(num == 0) {
            return getOfficials();
        }

        if(num > 1) {
            // sort by vote number
            sortByVoteNum(addrs, 0, num - 1);
        }

        // get top, max: MAX_NUM
        uint maxNum = getPropertyValue("supernode_max_num");
        if(num > maxNum) {
            num = maxNum;
        }
        address[] memory ret = new address[](num);
        for(uint i; i < num; i++) {
            ret[i] = addrs[i];
        }
        return ret;
    }

    function getOfficials() public view override returns (address[] memory) {
        uint num;
        for(uint i; i < ids.length; i++) {
            if(addr2info[id2addr[ids[i]]].isOfficial) {
                num++;
            }
        }
        address[] memory ret = new address[](num);
        uint index;
        for(uint i; i < ids.length; i++) {
            if(addr2info[id2addr[ids[i]]].isOfficial) {
                ret[index++] = id2addr[ids[i]];
            }
        }
        return ret;
    }

    function exist(address _addr) public view override returns (bool) {
        return addr2info[_addr].id != 0;
    }

    function existID(uint _id) public view override returns (bool) {
        return id2addr[_id] != address(0);
    }

    function existName(string memory _name) public view override returns (bool) {
        return name2addr[_name] != address(0);
    }

    function existEnode(string memory _enode) public view override returns (bool) {
        return enode2addr[_enode] != address(0);
    }

    function existLockID(address _addr, uint _lockID) public view override returns (bool) {
        for(uint i; i < addr2info[_addr].founders.length; i++) {
            if(addr2info[_addr].founders[i].lockID == _lockID) {
                return true;
            }
        }
        return false;
    }

    function isValid(address _addr) public view override returns (bool) {
        SuperNodeInfo memory info = addr2info[_addr];
        if(info.id == 0) {
            return false;
        }
        if(block.number >= getAccountManager().getRecordByID(info.founders[0].lockID).unlockHeight) { // creator must be locked
            return false;
        }
        uint lockAmount = info.founders[0].amount;
        for(uint i = 1; i < info.founders.length; i++) {
            if(block.number < getAccountManager().getRecordByID(info.founders[i].lockID).unlockHeight) {
                lockAmount += info.founders[i].amount;
            }
        }
        if(lockAmount < getPropertyValue("supernode_min_amount") * Constant.COIN) {
            return false;
        }
        return true;
    }

    function isFormal(address _addr) public view override returns (bool) {
        if(!isValid(_addr)) {
            return false;
        }
        address[] memory tops = getTops();
        for(uint i; i < tops.length; i++) {
            if(_addr == tops[i]) {
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
            while(getSNVote().getTotalVoteNum(_arr[i]) > getSNVote().getTotalVoteNum(middle)) i++;
            while(getSNVote().getTotalVoteNum(middle) > getSNVote().getTotalVoteNum(_arr[j]) && j > 0) j--;
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