// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/ArrayUtil.sol";

contract MasterNodeStorage is IMasterNodeStorage, System {
    uint no; // masternode no.
    mapping(address => MasterNodeInfo) addr2info;
    uint[] ids;
    mapping(uint => address) id2addr;
    mapping(string => address) enode2addr;

    function create(address _addr, address _creator, uint _lockID, uint _amount, string memory _enode, string memory _description, IncentivePlan memory plan) public override onlyMasterNodeLogic {
        MasterNodeInfo storage info = addr2info[_addr];
        info.id = ++no;
        info.addr = _addr;
        info.creator = _creator;
        info.enode = _enode;
        info.description = _description;
        info.isOfficial = false;
        info.state = Constant.NODE_STATE_INIT;
        info.founders.push(MemberInfo(_lockID, _creator, _amount, block.number));
        info.incentivePlan = plan;
        info.lastRewardHeight = 0;
        info.createHeight = block.number;
        info.updateHeight = 0;
        ids.push(info.id);
        id2addr[info.id] = _addr;
        enode2addr[info.enode] = _addr;
    }

    function append(address _addr, uint _lockID, uint _amount) public override onlyMasterNodeLogic {
        addr2info[_addr].founders.push(MemberInfo(_lockID, tx.origin, _amount, block.number));
        addr2info[_addr].updateHeight = block.number;
    }

    function updateAddress(address _addr, address _newAddr) public override onlyMasterNodeLogic {
        addr2info[_newAddr] = addr2info[_addr];
        addr2info[_newAddr].addr = _newAddr;
        addr2info[_newAddr].updateHeight = 0;
        delete addr2info[_addr];
        id2addr[addr2info[_newAddr].id] = _newAddr;
        enode2addr[addr2info[_newAddr].enode] = _newAddr;
    }

    function updateEnode(address _addr, string memory _enode) public override onlyMasterNodeLogic {
        string memory oldEnode = addr2info[_addr].enode;
        addr2info[_addr].enode = _enode;
        addr2info[_addr].updateHeight = block.number;
        enode2addr[_enode] = _addr;
        delete enode2addr[oldEnode];
    }

    function updateDescription(address _addr, string memory _description) public override onlyMasterNodeLogic {
        addr2info[_addr].description = _description;
        addr2info[_addr].updateHeight = block.number;
    }

    function updateIsOfficial(address _addr, bool _flag) public override onlyMasterNodeLogic {
        if(tx.origin != owner()) {
            return;
        }
        addr2info[_addr].isOfficial = _flag;
        addr2info[_addr].updateHeight = block.number;
    }

    function updateState(address _addr, uint _state) public override onlyMasterNodeLogic {
        addr2info[_addr].state = _state;
        addr2info[_addr].updateHeight = block.number;
    }

    function removeMember(address _addr, uint _index) public override onlyMasterNodeLogic {
        if(_index == 0) {
            dissolve(_addr);
        } else {
            MasterNodeInfo storage info = addr2info[_addr];
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

    function dissolve(address _addr) public override onlyMasterNodeLogic {
        MasterNodeInfo memory info = addr2info[_addr];
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
        delete enode2addr[info.enode];
        // remove info
        delete addr2info[_addr];
    }

    function updateLastRewardHeight(address _addr, uint _height) public override onlyMasterNodeLogic {
        addr2info[_addr].lastRewardHeight = _height;
        addr2info[_addr].updateHeight = block.number;
    }

    function getInfo(address _addr) public view override returns (MasterNodeInfo memory) {
        return addr2info[_addr];
    }

    function getInfoByID(uint _id) public view override returns (MasterNodeInfo memory) {
        return addr2info[id2addr[_id]];
    }

    function getNext() public view override returns (address) {
        uint minAmount = getPropertyValue("masternode_min_amount") * Constant.COIN;
        uint count;
        MasterNodeInfo[] memory mns = new MasterNodeInfo[](ids.length);
        for(uint i; i < ids.length; i++) {
            MasterNodeInfo memory info = addr2info[id2addr[ids[i]]];
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
            mns[count++] = info;
        }
        if(count != 0) {
            return selectNext(mns, count).addr;
        }
        // select official addr2info
        // select official addr2info
        address[] memory officials = getOfficials();
        if(officials.length != 0) {
            return selectNext2(officials, officials.length);
        } else {
            return id2addr[(block.number % ids.length) + 1];
        }
    }

    function getNum() public view override returns (uint) {
        return ids.length;
    }

    function getAll(uint _start, uint _count) public view override returns (address[] memory) {
        require(_start < ids.length, "invalid _start, must be in [0, getNum())");
        require(_count > 0 && _count <= 100, "max return 100 masternodes");

        uint num = _count;
        if(_start + _count >= ids.length) {
            num = ids.length - _start;
        }
        address[] memory ret = new address[](num);
        for(uint i; i < num; i++) {
            ret[i] = id2addr[ids[i + _start]];
        }
        return ret;
    }

    function getAddrNum4Creator(address _creator) public view override returns (uint) {
        uint num;
        for(uint i; i < ids.length; i++) {
            if(addr2info[id2addr[ids[i]]].creator == _creator) {
                num++;
            }
        }
        return num;
    }

    function getAddrs4Creator(address _creator, uint _start, uint _count) public view override returns (address[] memory) {
        uint addrNum = getAddrNum4Creator(_creator);
        require(_start < addrNum, "invalid _start, must be in [0, getAddrNum4Creator())");
        require(_count > 0 && _count <= 100, "max return 100 masternodes");

        address[] memory temp = new address[](addrNum);
        uint index;
        for(uint i; i < ids.length; i++) {
            if(addr2info[id2addr[ids[i]]].creator == _creator) {
                temp[index++] = id2addr[ids[i]];
            }
        }

        uint num = _count;
        if(_start + _count >= addrNum) {
            num = addrNum - _start;
        }
        index = 0;
        address[] memory ret = new address[](num);
        for(uint i; i < num; i++) {
            ret[index++] = temp[_start + i];
        }
        return ret;
    }

    function getAddrNum4Partner(address _partner) public view override returns (uint) {
        uint num;
        for(uint i; i < ids.length; i++) {
            MasterNodeInfo memory info = addr2info[id2addr[ids[i]]];
            if(info.creator == _partner) {
                continue;
            }
            for(uint k; k < info.founders.length; k++) {
                if(info.founders[k].addr == _partner) {
                    num++;
                    break;
                }
            }
        }
        return num;
    }

    function getAddrs4Partner(address _partner, uint _start, uint _count) public view override returns (address[] memory) {
        uint addrNum = getAddrNum4Partner(_partner);
        require(_start < addrNum, "invalid _start, must be in [0, getAddrNum4Partner())");
        require(_count > 0 && _count <= 100, "max return 100 supernodes");

        address[] memory temp = new address[](addrNum);
        uint index;
        for(uint i; i < ids.length; i++) {
            MasterNodeInfo memory info = addr2info[id2addr[ids[i]]];
            if(info.creator == _partner) {
                continue;
            }
            for(uint k; k < info.founders.length; k++) {
                if(info.founders[k].addr == _partner) {
                    temp[index++] = info.addr;
                    break;
                }
            }
        }

        uint num = _count;
        if(_start + _count >= addrNum) {
            num = addrNum - _start;
        }
        index = 0;
        address[] memory ret = new address[](num);
        for(uint i; i < num; i++) {
            ret[index++] = temp[_start + i];
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

    function existEnode(string memory _enode) public view override returns (bool) {
        return enode2addr[_enode] != address(0);
    }

    function existLockID(address _addr, uint _lockID) public view override returns (bool) {
        MasterNodeInfo memory mn = addr2info[_addr];
        for(uint i; i < mn.founders.length; i++) {
            if(mn.founders[i].lockID == _lockID) {
                return true;
            }
        }
        return false;
    }

    function existFounder(address _founder) public view override returns (bool) {
        for(uint i; i < ids.length; i++) {
            MasterNodeInfo memory info = addr2info[id2addr[ids[i]]];
            for(uint k; k < info.founders.length; k++) {
                if(info.founders[k].addr == _founder) {
                    return true;
                }
            }
        }
        return false;
    }

    function isValid(address _addr) public view override returns (bool) {
        MasterNodeInfo memory info = addr2info[_addr];
        if(info.id == 0) {
            return false;
        }
        if(block.number >= getAccountManager().getRecordByID(info.founders[0].lockID).unlockHeight) { // creator must be locked
            return false;
        }
        uint lockAmount = info.founders[0].amount;
        for(uint i; i < info.founders.length; i++) {
            if(block.number < getAccountManager().getRecordByID(info.founders[i].lockID).unlockHeight) {
                lockAmount += info.founders[i].amount;
            }
        }
        if(lockAmount < getPropertyValue("masternode_min_amount") * Constant.COIN) {
            return false;
        }
        return true;
    }

    function existNodeAddress(address _addr) public view override returns (bool) {
        return exist(_addr) || getSuperNodeStorage().exist(_addr);
    }

    function existNodeEnode(string memory _enode) public view override returns (bool) {
        return existEnode(_enode) || getSuperNodeStorage().existEnode(_enode);
    }

    function existNodeFounder(address _founder) public view override returns (bool) {
        return existFounder(_founder) || getSuperNodeStorage().existFounder(_founder);
    }

    function selectNext(MasterNodeInfo[] memory _arr, uint len) internal pure returns (MasterNodeInfo memory) {
        uint pos;
        uint temp = _arr[pos].lastRewardHeight;
        for(uint i = 1; i < len; i++) {
            if(temp > _arr[i].lastRewardHeight) {
                pos = i;
                temp = _arr[i].lastRewardHeight;
            }
        }
        return _arr[pos];
    }

    function selectNext2(address[] memory _arr, uint len) internal view returns (address) {
        uint pos;
        uint temp = getInfo(_arr[pos]).lastRewardHeight;
        for(uint i = 1; i < len; i++) {
            if(temp > getInfo(_arr[i]).lastRewardHeight) {
                pos = i;
                temp = getInfo(_arr[i]).lastRewardHeight;
            }
        }
        return _arr[pos];
    }
}