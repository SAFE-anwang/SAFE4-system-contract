// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/ISuperNode.sol";
import "./interfaces/IAccountManager.sol";
import "./utils/SafeMath.sol";
import "./utils/NodeUtil.sol";

contract SuperNode is ISuperNode, System {
    using SafeMath for uint256;

    uint internal constant TOTAL_CREATE_AMOUNT  = 5000;
    uint internal constant UNION_CREATE_AMOUNT  = 1000; // 20%
    uint internal constant APPEND_AMOUNT        = 500; // 10%
    uint internal constant MAX_NUM              = 49;

    uint sn_no; // supernode no.
    mapping(address => SuperNodeInfo) supernodes;
    uint[] snIDs;
    mapping(uint => address) snID2addr;
    mapping(string => address) snIP2addr;

    event SNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _reocrdID);
    event SNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _recordID);

    receive() external payable {}
    fallback() external payable {}

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable {
        if(!_isUnion) {
            require(msg.value >= TOTAL_CREATE_AMOUNT, "supernode need lock 5000 SAFE at least");
        } else {
            require(msg.value >= UNION_CREATE_AMOUNT, "supernode need lock 1000 SAFE at least");
        }
        require(bytes(_name).length > 0 && bytes(_name).length <= 1024, "invalid name");
        string memory ip = NodeUtil.check(2, _isUnion, _addr, _lockDay, _enode, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
        require(!existNodeAddress(_addr), "existent address");
        require(!existNodeIP(ip), "existent ip");

        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        uint lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        IncentivePlan memory plan = IncentivePlan(_creatorIncentive, _partnerIncentive, _voterIncentive);
        create(_addr, lockID, msg.value, _name, _enode, ip, _description, plan);
        am.freeze(lockID, _lockDay); // creator's lock id can't unbind util unlock it
        emit SNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable {
        require(msg.value >= APPEND_AMOUNT, "supernode need append lock 500 SAFE at least");
        require(exist(_addr), "non-existent supernode");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        uint lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        append(_addr, lockID, msg.value);
        am.freeze(lockID, 90);
        emit SNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function reward(address _addr) public payable {
        require(msg.value > 0, "invalid reward");
        SuperNodeInfo memory info = supernodes[_addr];
        uint creatorReward = msg.value.mul(info.incentivePlan.creator).div(100);
        uint partnerReward = msg.value.mul(info.incentivePlan.partner).div(100);
        uint voterReward = msg.value.sub(creatorReward).sub(partnerReward);
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        // reward to creator
        if(creatorReward != 0) {
            am.reward{value: creatorReward}(info.creator);
        }
        // reward to partner
        if(partnerReward != 0) {
            uint total = 0;
            for(uint i = 0; i < info.founders.length; i++) {
                if(total.add(info.founders[i].amount) <= TOTAL_CREATE_AMOUNT) {
                    uint temp = partnerReward.mul(info.founders[i].amount).div(TOTAL_CREATE_AMOUNT);
                    if(temp != 0) {
                        am.reward{value: temp}(info.founders[i].addr);
                    }
                    total = total.add(info.founders[i].amount);
                    if(total == TOTAL_CREATE_AMOUNT) {
                        break;
                    }
                } else {
                    uint temp = partnerReward.mul(TOTAL_CREATE_AMOUNT.sub(total)).div(TOTAL_CREATE_AMOUNT);
                    if(temp != 0) {
                        am.reward{value: temp}(info.founders[i].addr);
                    }
                    break;
                }
            }
        }
        // reward to voter
        if(voterReward != 0) {
            if(info.voters.length > 0) {
                for(uint i = 0; i < info.voters.length; i++) {
                    uint temp = voterReward.mul(info.voters[i].amount).div(info.totalVoterAmount);
                    if(temp != 0) {
                        am.reward{value: temp}(info.voters[i].addr);
                    }
                }
            } else {
                if(voterReward != 0) {
                    am.reward{value: voterReward}(info.creator);
                }
            }
        }
    }

    function changeAddress(address _addr, address _newAddr) public {
        require(exist(_addr), "non-existent supernode");
        require(!existNodeAddress(_newAddr), "target address has existed");
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

    function changeEnode(address _addr, string memory _newEnode) public {
        require(exist(_addr), "non-existent supernode");
        string memory ip = NodeUtil.checkEnode(_newEnode);
        require(!existNodeIP(ip), "existent ip of new enode");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        string memory oldIP = supernodes[_addr].ip;
        supernodes[_addr].ip = ip;
        supernodes[_addr].updateHeight = block.number;
        snIP2addr[ip] = _addr;
        delete snIP2addr[oldIP];
    }

    function changeDescription(address _addr, string memory _newDescription) public {
        require(exist(_addr), "non-existent supernode");
        require(bytes(_newDescription).length > 0, "invalid description");
        require(msg.sender == supernodes[_addr].creator, "caller isn't creator");
        supernodes[_addr].description = _newDescription;
        supernodes[_addr].updateHeight = block.number;
    }

    function getInfo(address _addr) public view returns (SuperNodeInfo memory) {
        require(exist(_addr), "non-existent supernode");
        return supernodes[_addr];
    }

    function getAll() public view returns (SuperNodeInfo[] memory) {
        SuperNodeInfo[] memory ret = new SuperNodeInfo[](snIDs.length);
        for(uint i = 0; i < snIDs.length; i++) {
            ret[i] = supernodes[snID2addr[snIDs[i]]];
        }
        return ret;
    }

    function getTop() public view returns (SuperNodeInfo[] memory) {
        uint num = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= TOTAL_CREATE_AMOUNT) {
                num++;
            }
        }

        address[] memory snAddrs = new address[](num);
        uint k = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= TOTAL_CREATE_AMOUNT) {
                snAddrs[k++] = addr;
            }
        }

        // sort by vote number
        sortByVoteNum(snAddrs, 0, snAddrs.length - 1);

        // get top, max: MAX_NUM
        num = MAX_NUM;
        if(snAddrs.length < MAX_NUM) {
            num = snAddrs.length;
        }
        SuperNodeInfo[] memory ret = new SuperNodeInfo[](num);
        for(uint i = 0; i < num; i++) {
            ret[i] = supernodes[snAddrs[i]];
        }
        return ret;
    }

    function getNum() public view returns (uint) {
        uint num = 0;
        for(uint i = 0; i < snIDs.length; i++) {
            address addr = snID2addr[snIDs[i]];
            if(supernodes[addr].amount >= TOTAL_CREATE_AMOUNT) {
                num++;
            }
        }
        if(num >= MAX_NUM) {
            return MAX_NUM;
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
        sn.state = 0;
        sn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        sn.incentivePlan = _incentivePlan;
        sn.createHeight = block.number;
        sn.updateHeight = 0;
        snIDs.push(sn.id);
        snID2addr[sn.id] = _addr;
        snIP2addr[sn.ip] = _addr;
    }

    function append(address _addr, uint _lockID, uint _amount) internal {
        require(exist(_addr), "non-existent supernode");
        require(supernodes[_addr].amount >= 1000, "need create first");
        require(!existLockID(_addr, _lockID), "lock ID has been used");
        require(_lockID != 0, "invalid lock id");
        require(_amount >= APPEND_AMOUNT, "append lock 500 SAFE at least");
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
            while(supernodes[_arr[i]].totalVoteNum > supernodes[middle].totalVoteNum) i++;
            while(supernodes[middle].totalVoteNum > supernodes[_arr[j]].totalVoteNum && j > 0) j--;
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