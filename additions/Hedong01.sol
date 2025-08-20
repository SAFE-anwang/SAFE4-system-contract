// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IProperty {
    function getValue(string memory _name) external view returns (uint);
}

contract Hedong001 is Initializable, OwnableUpgradeable {
    uint record_no; // record no.
    mapping(address => uint[]) addr2ids;
    mapping(uint => AccountRecord) id2record;
    mapping(uint => uint) id2index;

    event SafeDeposit(address _addr, uint _amount, uint _lockDay, uint _id);
    event SafeWithdraw(address _addr, uint _amount, uint[] _ids);

    bool internal lock; // re-entrant lock
    modifier noReentrant() {
        require(!lock, "Error: reentrant call");
        lock = true;
        _;
        lock = false;
    }

    struct AccountRecord {
        uint id;
        address addr;
        uint amount;
        uint lockDay;
        uint startHeight; // start height
        uint unlockHeight; // unlocked height
    }

    function initialize() public initializer {
        __Ownable_init();
        transferOwnership(0x0000000000000000000000000000000000001102);
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    // deposit
    function batchDeposit4One(address _to, uint _times, uint _spaceDay, uint _startDay) public payable returns (uint[] memory) {
        require(msg.value > 0, "invalid value");
        require(_to != address(0), "invalid target address");
        require(_times > 0, "invalid times");
        require(msg.value / _times >= 100000000000000000 && msg.value / _times < 1000000000000000000, "amount/times need in range of [0.1, 1)");
        require(_spaceDay + _startDay != 0, "invalid space and start day");

        uint[] memory ids = new uint[](_times);
        uint batchValue = msg.value / _times;
        uint i;
        for(; i < _times - 1; i++) {
            ids[i] = addRecord(_to, batchValue, _startDay + (i + 1) * _spaceDay);
            emit SafeDeposit(_to, batchValue, _startDay + (i + 1) * _spaceDay, ids[i]);
        }
        ids[i] = addRecord(_to, batchValue + msg.value % _times, _startDay + (i + 1) * _spaceDay);
        emit SafeDeposit(_to, batchValue + msg.value % _times, _startDay + (i + 1) * _spaceDay, ids[i]);
        return ids;
    }

    // withdraw
    function withdrawByID(uint[] memory _ids) public noReentrant returns (uint) {
        require(_ids.length > 0, "invalid record ids");
        uint amount;
        AccountRecord memory record;
        for(uint i; i < _ids.length; i++) {
            record = id2record[_ids[i]];
            if(record.amount == 0 || record.addr != msg.sender || block.number < record.unlockHeight) {
                continue;
            }
            amount += record.amount;
            delRecord(_ids[i]);
        }
        if(amount != 0) {
            payable(msg.sender).transfer(amount);
        }
        emit SafeWithdraw(msg.sender, amount, _ids);
        return amount;
    }

    // get total amount and total record number
    function getTotalAmount(address _addr) public view returns (uint, uint) {
        uint amount;
        for(uint i; i < addr2ids[_addr].length; i++) {
            amount += id2record[addr2ids[_addr][i]].amount;
        }
        return (amount, addr2ids[_addr].length);
    }

    function getTotalIDs(address _addr, uint _start, uint _count) public view returns (uint[] memory) {
        uint totalNum = addr2ids[_addr].length;
        require(totalNum > 0, "insufficient quantity");
        require(_start < totalNum, "invalid _start, must be in [0, totalNum)");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint num = _count;
        if(_start + _count >= totalNum) {
            num = totalNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = addr2ids[_addr][i + _start];
        }
        return ret;
    }

    // get available amount and available record number
    function getAvailableAmount(address _addr) public view returns (uint, uint) {
        uint amount;
        uint num;
        uint id;
        for(uint i; i < addr2ids[_addr].length; i++) {
            id = addr2ids[_addr][i];
            if(block.number >= id2record[id].unlockHeight) {
                amount += id2record[id].amount;
                num++;
            }
        }
        return (amount, num);
    }

    function getAvailableIDs(address _addr, uint _start, uint _count) public view returns (uint[] memory) {
        uint availableNum;
        uint id;
        for(uint i; i < addr2ids[_addr].length; i++) {
            id = addr2ids[_addr][i];
            if(block.number >= id2record[id].unlockHeight) {
                availableNum++;
            }
        }

        require(availableNum > 0, "insufficient quantity");
        require(_start < availableNum, "invalid _start, must be in [0, availableNum)");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](availableNum);
        uint index;
        for(uint i; i < addr2ids[_addr].length; i++) {
            id = addr2ids[_addr][i];
            if(block.number >= id2record[id].unlockHeight) {
                temp[index++] = id;
            }
        }

        uint num = _count;
        if(_start + _count >= availableNum) {
            num = availableNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
        }
        return ret;
    }

    // get locked amount and locked record number
    function getLockedAmount(address _addr) public view returns (uint, uint) {
        uint amount;
        uint num;
        uint id;
        for(uint i; i < addr2ids[_addr].length; i++) {
            id = addr2ids[_addr][i];
            if(block.number < id2record[id].unlockHeight) {
                amount += id2record[id].amount;
                num++;
            }
        }
        return (amount, num);
    }

    function getLockedIDs(address _addr, uint _start, uint _count) public view returns (uint[] memory) {
        uint lockedNum;
        uint id;
        for(uint i; i < addr2ids[_addr].length; i++) {
            id = addr2ids[_addr][i];
            if(block.number < id2record[id].unlockHeight) {
                lockedNum++;
            }
        }

        require(lockedNum > 0, "insufficient quantity");
        require(_start < lockedNum, "invalid _start, must be in [0, lockedNum)");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](lockedNum);
        uint index;
        for(uint i; i < addr2ids[_addr].length; i++) {
            id = addr2ids[_addr][i];
            if(block.number < id2record[id].unlockHeight) {
                temp[index++] = id;
            }
        }

        uint num = _count;
        if(_start + _count >= lockedNum) {
            num = lockedNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
        }
        return ret;
    }

    // get record by id
    function getRecordByID(uint _id) public view returns (AccountRecord memory) {
        return id2record[_id];
    }

    // add record
    function addRecord(address _addr, uint _amount, uint _lockDay) internal returns (uint) {
        require(_lockDay != 0, "invalid lock day");
        uint unlockHeight = block.number + _lockDay * 86400 / IProperty(0x0000000000000000000000000000000000001000).getValue("block_space");
        uint id = ++record_no;
        addr2ids[_addr].push(id);
        id2record[id] = AccountRecord(id, _addr, _amount, _lockDay, block.number, unlockHeight);
        id2index[id] = addr2ids[_addr].length - 1;
        return id;
    }

    // delete record
    function delRecord(uint _id) internal {
        require(id2record[_id].addr == msg.sender, "invalid record id");
        uint[] storage ids = addr2ids[msg.sender];
        uint pos = id2index[_id];
        ids[pos] = ids[ids.length - 1];
        id2index[ids[pos]] = pos;
        ids.pop();
        delete id2record[_id];
        delete id2index[_id];
    }
}