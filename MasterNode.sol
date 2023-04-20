// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/IMasterNode.sol";
import "./interfaces/IAccountManager.sol";
import "./utils/SafeMath.sol";

contract MasterNode is IMasterNode, System {
    using SafeMath for uint256;

    uint internal constant TOTAL_CREATE_AMOUNT  = 1000;
    uint internal constant UNION_CREATE_AMOUNT  = 200; // 20%
    uint internal constant APPEND_AMOUNT        = 100; // 10%

    uint mn_no; // masternode no.
    mapping(address => MasterNodeInfo) masternodes;
    mapping(uint => address) mnID2addr;
    mapping(string => address) mnIP2addr;
    mapping(string => address) mnPubkey2addr;

    event MNRegister(address _addr, address _operator, uint _amount, uint _lockDay, bytes20 _reocrdID);
    event MNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, bytes20 _recordID);

    function register(address _addr, bool _isUnion, uint _lockDay, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive) public payable {
        if(!_isUnion) {
            require(msg.value >= TOTAL_CREATE_AMOUNT, "masternode need lock 1000 SAFE at least");
        } else {
            require(msg.value >= UNION_CREATE_AMOUNT, "masternode need lock 200 SAFE at least");
        }
        checkInfo(_addr, _lockDay, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive);
        require(!existNodeAddress(_addr), "target address has been used");
        require(!existNodeIP(_ip), "target ip has been used");
        require(!existNodePubkey(_pubkey), "target pubkey has been used");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        bytes20 lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        create(_addr, lockID, msg.value, _ip, _pubkey, _description, 100, 0);
        am.setBindDay(lockID, _lockDay); // creator's lock id can't unbind util unlock it
        emit MNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable {
        require(msg.value >= APPEND_AMOUNT, "masternode need append lock 100 SAFE at least");
        require(exist(_addr), "non-existent masternode");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        bytes20 lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        append(_addr, lockID, msg.value);
        am.setBindDay(lockID, 30);
        emit MNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function reward(address _addr) public payable {
        require(msg.value > 0, "invalid reward");
        MasterNodeInfo memory info = masternodes[_addr];
        uint creatorReward = msg.value.mul(info.incentivePlan.creator).div(100);
        uint partnerReward = msg.value.mul(info.incentivePlan.partner).div(100);
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        // reward to creator
        if(creatorReward != 0) {
            am.reward{value: creatorReward}(info.creator, 6);
        }
        // reward to partner
        uint total = 0;
        for(uint i = 0; i < info.founders.length; i++) {
            if(total.add(info.founders[i].amount) <= TOTAL_CREATE_AMOUNT) {
                uint temp = partnerReward.mul(info.founders[i].amount).div(TOTAL_CREATE_AMOUNT);
                if(temp != 0) {
                    am.reward{value: temp}(info.founders[i].addr, 6);
                }
                total = total.add(info.founders[i].amount);
                if(total == TOTAL_CREATE_AMOUNT) {
                    break;
                }
            } else {
                uint temp = partnerReward.mul(TOTAL_CREATE_AMOUNT.sub(total)).div(TOTAL_CREATE_AMOUNT);
                if(temp != 0) {
                    am.reward{value: temp}(info.founders[i].addr, 6);
                }
                break;
            }
        }
    }

    function changeAddress(address _addr, address _newAddr) public {
        require(exist(_addr), "non-existent masternode");
        require(existNodeAddress(_newAddr), "target address has existed");
        require(_newAddr != address(0), "invalid new address");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        masternodes[_newAddr] = masternodes[_addr];
        masternodes[_newAddr].addr = _newAddr;
        masternodes[_newAddr].updateHeight = 0;
        delete masternodes[_addr];
        mnID2addr[masternodes[_newAddr].id] = _newAddr;
        mnIP2addr[masternodes[_newAddr].ip] = _newAddr;
        mnPubkey2addr[masternodes[_newAddr].pubkey] = _newAddr;
    }

    function changeIP(address _addr, string memory _ip) public {
        require(exist(_addr), "non-existent masternode");
        require(!existNodeIP(_ip), "target ip has existed");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_ip).length > 0, "invalid ip");
        string memory oldIP = masternodes[_addr].ip;
        masternodes[_addr].ip = _ip;
        masternodes[_addr].updateHeight = block.number;
        delete mnIP2addr[oldIP];
        mnIP2addr[_ip] = _addr;
    }

    function changePubkey(address _addr, string memory _pubkey) public {
        require(exist(_addr), "non-existent masternode");
        require(!existNodePubkey(_pubkey), "target pubkey has existed");
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_pubkey).length > 0, "invalid pubkey");
        string memory oldPubkey = masternodes[_addr].pubkey;
        masternodes[_addr].pubkey = _pubkey;
        masternodes[_addr].updateHeight = block.number;
        delete mnPubkey2addr[oldPubkey];
        mnPubkey2addr[_pubkey] = _addr;
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

    function exist(address _addr) public view returns (bool) {
        return masternodes[_addr].id != 0;
    }

    function existID(uint _id) public view returns (bool) {
        return mnID2addr[_id] != address(0);
    }

    function existIP(string memory _ip) public view returns (bool) {
        return mnIP2addr[_ip] != address(0);
    }

    function existPubkey(string memory _pubkey) public view returns (bool) {
        return mnPubkey2addr[_pubkey] != address(0);
    }

    function existLockID(address _addr, bytes20 _lokcID) public view returns (bool) {
        MasterNodeInfo memory mn = masternodes[_addr];
        for(uint i = 0; i < mn.founders.length; i++) {
            if(mn.founders[i].lockID == _lokcID) {
                return true;
            }
        }
        return false;
    }

    function checkInfo(address _addr, uint _lockDay, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive) internal view {
        require(!exist(_addr), "existent address");
        require(_addr != address(0), "invalid address");
        require(_lockDay >= 720, "lock 2 years at least");
        require(bytes(_ip).length != 0, "invalid ip");
        require(bytes(_pubkey).length != 0, "invalid pubkey");
        require(bytes(_description).length != 0, "invalid description");
        require(_creatorIncentive.add(_partnerIncentive) == 100, "invalid incentive plan");
    }

    function create(address _addr, bytes20 _lockID, uint _amount, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive) internal {
        MasterNodeInfo storage mn = masternodes[_addr];
        mn.id = ++mn_no;
        mn.addr = _addr;
        mn.creator = msg.sender;
        mn.amount = _amount;
        mn.ip = _ip;
        mn.pubkey = _pubkey;
        mn.description = _description;
        mn.state = 0;
        mn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        mn.incentivePlan = IncentivePlan(_creatorIncentive, _partnerIncentive, 0);
        mn.createHeight = block.number;
        mn.createHeight = 0;
        mnID2addr[mn.id] = _addr;
        mnIP2addr[mn.ip] = _addr;
        mnPubkey2addr[mn.pubkey] = _addr;
    }


    function append(address _addr, bytes20 _lockID, uint _amount) internal {
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