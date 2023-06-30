// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/IMasterNode.sol";
import "./interfaces/IAccountManager.sol";
import "./utils/SafeMath.sol";
import "./utils/NodeUtil.sol";

contract MasterNode is IMasterNode, System {
    using SafeMath for uint256;

    uint internal constant TOTAL_CREATE_AMOUNT  = 1000000000000000000000;
    uint internal constant UNION_CREATE_AMOUNT  = 200000000000000000000; // 20%
    uint internal constant APPEND_AMOUNT        = 100000000000000000000; // 10%

    uint mn_no; // masternode no.
    mapping(address => MasterNodeInfo) masternodes;
    uint[] mnIDs;
    mapping(uint => address) mnID2addr;
    mapping(string => address) mnIP2addr;

    receive() external payable {}
    fallback() external payable {}

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive) public payable {
        if(!_isUnion) {
            require(msg.value >= TOTAL_CREATE_AMOUNT, "masternode need lock 1000 SAFE at least");
        } else {
            require(msg.value >= UNION_CREATE_AMOUNT, "masternode need lock 200 SAFE at least");
        }
        string memory ip = NodeUtil.check(1, _isUnion, _addr, _lockDay, _enode, _description, _creatorIncentive, _partnerIncentive, 0);
        require(!existNodeAddress(_addr), "existent address");
        require(!existNodeIP(ip), "existent ip");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        uint lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        create(_addr, lockID, msg.value, _enode, ip, _description, IncentivePlan(_creatorIncentive, _partnerIncentive, 0));
        am.setRecordFreeze(lockID, _addr, _lockDay); // creator's lock id can't register other masternode again
        emit MNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable {
        require(msg.value >= APPEND_AMOUNT, "masternode need append lock 100 SAFE at least");
        require(exist(_addr), "non-existent masternode");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        uint lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        append(_addr, lockID, msg.value);
        am.setRecordFreeze(lockID, _addr, 30); // partner's lock id can register other masternode after 30 days
        emit MNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function turnRegister(address _addr, uint _lockID) public {
        require(exist(_addr), "non-existent masternode");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        IAccountManager.AccountRecord memory record = am.getRecordByID(_lockID);
        require(record.addr == msg.sender, "you aren't record owner");
        require(record.amount >= APPEND_AMOUNT, "masternode need append lock 100 SAFE at least");
        require(block.number < record.unlockHeight, "record isn't locked");
        IAccountManager.RecordUseInfo memory useinfo = am.getRecordUseInfo(_lockID);
        require(block.number >= useinfo.unfreezeHeight, "record is freezen");
        append(_addr, _lockID, record.lockDay);
        am.setRecordFreeze(_lockID, _addr, 30); // partner's lock id can register other masternode after 30 days
        emit MNAppendRegister(_addr, msg.sender, record.amount, record.lockDay, _lockID);
    }

    function reward(address _addr) public payable {
        require(msg.value > 0, "invalid reward");
        MasterNodeInfo memory info = masternodes[_addr];
        uint creatorReward = msg.value.mul(info.incentivePlan.creator).div(100);
        uint partnerReward = msg.value.mul(info.incentivePlan.partner).div(100);

        uint maxCount = info.founders.length;
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
        // reward to partner
        if(partnerReward != 0) {
            uint total = 0;
            for(uint i = 0; i < info.founders.length; i++) {
                MemberInfo memory partner = info.founders[i];
                if(total.add(partner.amount) <= TOTAL_CREATE_AMOUNT) {
                    uint tempAmount = partnerReward.mul(partner.amount).div(TOTAL_CREATE_AMOUNT);
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
                    if(total == TOTAL_CREATE_AMOUNT) {
                        break;
                    }
                } else {
                    uint tempAmount = partnerReward.mul(TOTAL_CREATE_AMOUNT.sub(total)).div(TOTAL_CREATE_AMOUNT);
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
        // reward to address
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        for(uint i = 0; i < count; i++) {
            am.reward{value: tempAmounts[i]}(tempAddrs[i]);
            emit SystemReward(_addr, 2, tempAddrs[i], tempRewardTypes[i], tempAmounts[i]);
        }
    }

    function fromSafe3(address _addr, uint _amount, uint _lockDay, uint _lockID) public onlySafe3Contract {
        require(_amount >= TOTAL_CREATE_AMOUNT, "masternode need lock 1000 SAFE at least");
        require(!existNodeAddress(_addr), "existent address");
        create(_addr, _lockID, _amount, "", "", "", IncentivePlan(100, 0, 0));
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        am.setRecordFreeze(_lockID, _addr, _lockDay); // creator's lock id can't register other masternode again
        emit MNRegister(_addr, msg.sender, _amount, _lockDay, _lockID);
    }

    function changeAddress(address _addr, address _newAddr) public {
        require(exist(_addr), "non-existent masternode");
        require(existNodeAddress(_newAddr), "existent new address");
        require(_newAddr != address(0), "invalid new address");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        masternodes[_newAddr] = masternodes[_addr];
        masternodes[_newAddr].addr = _newAddr;
        masternodes[_newAddr].updateHeight = 0;
        delete masternodes[_addr];
        mnID2addr[masternodes[_newAddr].id] = _newAddr;
        mnIP2addr[masternodes[_newAddr].ip] = _newAddr;
    }

    function changeEnode(address _addr, string memory _newEnode) public {
        require(exist(_addr), "non-existent masternode");
        string memory ip = NodeUtil.checkEnode(_newEnode);
        require(!existNodeIP(ip), "existent ip of new enode");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        string memory oldIP = masternodes[_addr].ip;
        masternodes[_addr].ip = ip;
        masternodes[_addr].updateHeight = block.number;
        delete mnIP2addr[oldIP];
        mnIP2addr[ip] = _addr;
    }

    function changeDescription(address _addr, string memory _description) public {
        require(exist(_addr), "non-existent masternode");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_description).length > 0, "invalid description");
        masternodes[_addr].description = _description;
        masternodes[_addr].updateHeight = block.number;
    }

    function getInfo(address _addr) public view returns (MasterNodeInfo memory) {
        require(exist(_addr), "non-existent masternode");
        return masternodes[_addr];
    }

    function getNext() public view returns (address) {
        return mnID2addr[(block.number % mn_no).add(1)];
    }

    function getAll() public view returns (MasterNodeInfo[] memory) {
        MasterNodeInfo[] memory ret = new MasterNodeInfo[](mnIDs.length);
        for(uint i = 0; i < mnIDs.length; i++) {
            ret[i] = masternodes[mnID2addr[mnIDs[i]]];
        }
        return ret;
    }

    function getNum() public view returns (uint) {
        return mnIDs.length;
    }

    function exist(address _addr) public view returns (bool) {
        return masternodes[_addr].id != 0;
    }

    function existID(uint _id) public view returns (bool) {
        return mnID2addr[_id] != address(0);
    }

    function existIP(string memory _ip) public view returns (bool) {
        return mnIP2addr[_ip] != address(0);
    }

    function existLockID(address _addr, uint _lokcID) public view returns (bool) {
        MasterNodeInfo memory mn = masternodes[_addr];
        for(uint i = 0; i < mn.founders.length; i++) {
            if(mn.founders[i].lockID == _lokcID) {
                return true;
            }
        }
        return false;
    }

    function create(address _addr, uint _lockID, uint _amount, string memory _enode, string memory _ip, string memory _description, IncentivePlan memory plan) internal {
        MasterNodeInfo storage mn = masternodes[_addr];
        mn.id = ++mn_no;
        mn.addr = _addr;
        mn.creator = msg.sender;
        mn.amount = _amount;
        mn.enode = _enode;
        mn.ip = _ip;
        mn.description = _description;
        mn.state = 0;
        mn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        mn.incentivePlan = plan;
        mn.createHeight = block.number;
        mn.createHeight = 0;
        mnIDs.push(mn.id);
        mnID2addr[mn.id] = _addr;
        mnIP2addr[mn.ip] = _addr;
    }


    function append(address _addr, uint _lockID, uint _amount) internal {
        require(exist(_addr), "non-existent masternode");
        require(masternodes[_addr].amount >= 200, "need create first");
        require(!existLockID(_addr, _lockID), "lock ID has been used");
        require(_lockID != 0, "invalid lock id");
        require(_amount >= 100, "append lock 100 SAFE at least");
        masternodes[_addr].founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        masternodes[_addr].amount += _amount;
        masternodes[_addr].updateHeight = block.number;
    }
}