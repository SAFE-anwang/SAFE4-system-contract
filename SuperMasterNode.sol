// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/ISuperMasterNode.sol";
import "./interfaces/IAccountManager.sol";
import "./utils/SafeMath.sol";

contract SuperMasterNode is ISuperMasterNode, System {
    using SafeMath for uint256;

    uint internal constant TOTAL_CREATE_AMOUNT  = 5000;
    uint internal constant UNION_CREATE_AMOUNT  = 1000; // 20%
    uint internal constant APPEND_AMOUNT        = 500; // 10%
    uint internal constant MAX_NUM              = 49;

    uint smn_no; // supermasternode no.
    mapping(address => SuperMasterNodeInfo) supermasternodes;
    mapping(address => SuperMasterNodeInfo) unconfirmedSupermasternodes;
    uint[] smnIDs;
    mapping(uint => address) smnID2addr;
    mapping(string => address) smnIP2addr;
    mapping(string => address) smnPubkey2addr;

    event SMNRegister(address _addr, address _operator, uint _amount, uint _lockDay, bytes20 _reocrdID);
    event SMNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, bytes20 _recordID);

    function register(address _addr, bool _isUnion, uint _lockDay, string memory _name, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable {
        if(!_isUnion) {
            require(msg.value >= TOTAL_CREATE_AMOUNT, "supermasternode need lock 5000 SAFE at least");
        } else {
            require(msg.value >= UNION_CREATE_AMOUNT, "supermasternode need lock 1000 SAFE at least");
        }
        checkInfo(_addr, _lockDay, _name, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
        require(!existNodeAddress(_addr), "target address has been used");
        require(!existNodeIP(_ip), "target ip has been used");
        require(!existNodePubkey(_pubkey), "target pubkey has been used");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        bytes20 lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        create(_addr, lockID, msg.value, _name, _ip, _pubkey, _description, IncentivePlan(_creatorIncentive, _partnerIncentive, _voterIncentive));
        am.setBindDay(lockID, _lockDay); // creator's lock id can't unbind util unlock it
        emit SMNRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function appendRegister(address _addr, uint _lockDay) public payable {
        require(msg.value >= APPEND_AMOUNT, "supermasternode need append lock 500 SAFE at least");
        require(exist(_addr), "non-existent supermasternode");
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        bytes20 lockID = am.deposit{value: msg.value}(msg.sender, _lockDay);
        append(_addr, lockID, msg.value);
        am.setBindDay(lockID, _lockDay);
        emit SMNAppendRegister(_addr, msg.sender, msg.value, _lockDay, lockID);
    }

    function verify(address _addr) public onlyOwner {
        require(isUnconfirmed(_addr), "non-existent unconfirmed supermasternode");
        supermasternodes[_addr] = unconfirmedSupermasternodes[_addr];
        delete unconfirmedSupermasternodes[_addr];
    }

    function reward(address _addr) public payable {
        require(msg.value > 0, "invalid reward");
        SuperMasterNodeInfo memory info = supermasternodes[_addr];
        uint creatorReward = msg.value.mul(info.incentivePlan.creator).div(100);
        uint partnerReward = msg.value.mul(info.incentivePlan.partner).div(100);
        uint voterReward = msg.value.sub(creatorReward).sub(partnerReward);
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        // reward to creator
        if(creatorReward != 0) {
            am.reward{value: creatorReward}(info.creator, 7);
        }
        // reward to partner
        uint total = 0;
        for(uint i = 0; i < info.founders.length; i++) {
            if(total.add(info.founders[i].amount) <= TOTAL_CREATE_AMOUNT) {
                uint temp = partnerReward.mul(info.founders[i].amount).div(TOTAL_CREATE_AMOUNT);
                if(temp != 0) {
                    am.reward{value: temp}(info.founders[i].addr, 7);
                }
                total = total.add(info.founders[i].amount);
                if(total == TOTAL_CREATE_AMOUNT) {
                    break;
                }
            } else {
                uint temp = partnerReward.mul(TOTAL_CREATE_AMOUNT.sub(total)).div(TOTAL_CREATE_AMOUNT);
                if(temp != 0) {
                    am.reward{value: temp}(info.founders[i].addr, 7);
                }
                break;
            }
        }
        // reward to voter
        for(uint i = 0; i < info.voters.length; i++) {
            uint temp = voterReward.mul(info.voters[i].amount).div(info.totalVoterAmount);
            if(temp != 0) {
                am.reward{value: temp}(info.founders[i].addr, 7);
            }
        }
    }

    function changeAddress(address _addr, address _newAddr) public {
        require(exist(_addr), "non-existent supermasternode");
        require(!existNodeAddress(_newAddr), "target address has existed");
        require(_newAddr != address(0), "invalid new address");
        SuperMasterNodeInfo storage smn = isConfirmed(_addr) ? supermasternodes[_addr] : unconfirmedSupermasternodes[_addr];
        require(msg.sender == smn.creator, "caller isn't creator");
        SuperMasterNodeInfo storage newSMN = isConfirmed(_addr) ? supermasternodes[_newAddr] : unconfirmedSupermasternodes[_newAddr];
        newSMN = smn;
        newSMN.addr = _newAddr;
        newSMN.updateHeight = 0;
        smnID2addr[newSMN.id] = _newAddr;
        smnIP2addr[newSMN.ip] = _newAddr;
        smnPubkey2addr[newSMN.pubkey] = _newAddr;
        if(isConfirmed(_addr)) {
            delete supermasternodes[_addr];
        } else {
            delete unconfirmedSupermasternodes[_addr];
        }
    }

    function changeIP(address _addr, string memory _newIP) public {
        require(exist(_addr), "non-existent supermasternode");
        require(!existNodeIP(_newIP), "target ip has existed");
        require(bytes(_newIP).length > 0, "invalid ip");
        SuperMasterNodeInfo storage smn = isConfirmed(_addr) ? supermasternodes[_addr] : unconfirmedSupermasternodes[_addr];
        require(msg.sender == smn.creator, "caller isn't creator");
        string memory oldIP = smn.ip;
        smn.ip = _newIP;
        smn.updateHeight = block.number;
        smnIP2addr[_newIP] = _addr;
        delete smnIP2addr[oldIP];
    }

    function changePubkey(address _addr, string memory _newPubkey) public {
        require(exist(_addr), "non-existent supermasternode");
        require(!existNodePubkey(_newPubkey), "target pubkey has existed");
        require(bytes(_newPubkey).length > 0, "invalid pubkey");
        SuperMasterNodeInfo storage smn = isConfirmed(_addr) ? supermasternodes[_addr] : unconfirmedSupermasternodes[_addr];
        require(msg.sender == smn.creator, "caller isn't creator");
        string memory oldPubkey = smn.pubkey;
        smn.pubkey = _newPubkey;
        smn.updateHeight = block.number;
        smnPubkey2addr[_newPubkey] = _addr;
        delete smnPubkey2addr[oldPubkey];
    }

    function changeDescription(address _addr, string memory _newDescription) public {
        require(exist(_addr), "non-existent supermasternode");
        require(bytes(_newDescription).length > 0, "invalid description");
        SuperMasterNodeInfo storage smn = isConfirmed(_addr) ? supermasternodes[_addr] : unconfirmedSupermasternodes[_addr];
        require(msg.sender == smn.creator, "caller isn't creator");
        smn.description = _newDescription;
        smn.updateHeight = block.number;
    }

    function getInfo(address _addr) public view returns (SuperMasterNodeInfo memory) {
        require(exist(_addr), "non-existent supermasternode");
        return supermasternodes[_addr];
    }

    function getTop() public view returns (SuperMasterNodeInfo[] memory) {
        uint num = 0;
        for(uint i = 0; i < smnIDs.length; i++) {
            address addr = smnID2addr[smnIDs[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= TOTAL_CREATE_AMOUNT) {
                    num++;
                }
            }
        }

        address[] memory smnAddrs = new address[](num);
        uint k = 0;
        for(uint i = 0; i < smnIDs.length; i++) {
            address addr = smnID2addr[smnIDs[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= TOTAL_CREATE_AMOUNT) {
                    smnAddrs[k++] = addr;
                }
            }
        }

        // sort by vote number
        sortByVoteNum(smnAddrs, 0, smnAddrs.length - 1);

        // get top, max: MAX_NUM
        num = MAX_NUM;
        if(smnAddrs.length < MAX_NUM) {
            num = smnAddrs.length;
        }
        SuperMasterNodeInfo[] memory ret = new SuperMasterNodeInfo[](num);
        for(uint i = 0; i < num; i++) {
            ret[i] = supermasternodes[smnAddrs[i]];
        }
        return ret;
    }

    function getNum() public view returns (uint) {
        uint num = 0;
        for(uint i = 0; i < smnIDs.length; i++) {
            address addr = smnID2addr[smnIDs[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= 5000) {
                    num++;
                }
            }
        }
        if(num >= 49) {
            return 49;
        }
        return num;
    }

    function exist(address _addr) public view returns (bool) {
        return isConfirmed(_addr) || isUnconfirmed(_addr);
    }

    function existID(uint _id) public view returns (bool) {
        return smnID2addr[_id] != address(0);
    }

    function existIP(string memory _ip) public view returns (bool) {
        return smnIP2addr[_ip] != address(0);
    }

    function existPubkey(string memory _pubkey) public view returns (bool) {
        return smnPubkey2addr[_pubkey] != address(0);
    }

    function existLockID(address _addr, bytes20 _lockID) public view returns (bool) {
        SuperMasterNodeInfo memory smn = supermasternodes[_addr];
        for(uint i = 0; i < smn.founders.length; i++) {
            if(smn.founders[i].lockID == _lockID) {
                return true;
            }
        }
        smn = unconfirmedSupermasternodes[_addr];
        for(uint i = 0; i < smn.founders.length; i++) {
            if(smn.founders[i].lockID == _lockID) {
                return true;
            }
        }
        return false;
    }

    function checkInfo(address _addr, uint _lockDay, string memory _name, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) internal view {
        require(!exist(_addr), "existent address");
        require(_addr != address(0), "invalid address");
        require(_lockDay >= 720, "lock 2 years at least");
        require(bytes(_name).length != 0, "invalid name");
        require(bytes(_ip).length != 0, "invalid ip");
        require(bytes(_pubkey).length != 0, "invalid pubkey");
        require(bytes(_description).length != 0, "invalid description");
        require(_creatorIncentive.add(_partnerIncentive).add(_voterIncentive) == 100, "invalid incentive plan");
    }

    function create(address _addr, bytes20 _lockID, uint _amount, string memory _name, string memory _ip, string memory _pubkey, string memory _description, IncentivePlan memory _incentivePlan) internal {
        SuperMasterNodeInfo storage smn = block.number > getPropertyValue("unverify_height") ? supermasternodes[_addr] : unconfirmedSupermasternodes[_addr];
        smn.id = ++smn_no;
        smn.name = _name;
        smn.addr = _addr;
        smn.creator = msg.sender;
        smn.amount = _amount;
        smn.ip = _ip;
        smn.pubkey = _pubkey;
        smn.description = _description;
        smn.state = 0;
        smn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        smn.incentivePlan = _incentivePlan;
        smn.createHeight = block.number;
        smn.updateHeight = 0;
        smnIDs.push(smn.id);
        smnID2addr[smn.id] = _addr;
        smnIP2addr[smn.ip] = _addr;
        smnPubkey2addr[smn.pubkey] = _addr;
    }

    function append(address _addr, bytes20 _lockID, uint _amount) internal {
        require(exist(_addr), "non-existent supermasternode");
        require(supermasternodes[_addr].amount >= 1000, "need create first");
        require(!existLockID(_addr, _lockID), "lock ID has been used");
        require(_lockID != 0, "invalid lock id");
        require(_amount >= 500, "append lock 500 SAFE at least");
        SuperMasterNodeInfo storage smn = isConfirmed(_addr) ? supermasternodes[_addr] : unconfirmedSupermasternodes[_addr];
        smn.founders.push(MemberInfo(_lockID, msg.sender, _amount, block.number));
        smn.amount += _amount;
        smn.updateHeight = block.number;
    }

    function isConfirmed(address _addr) internal view returns (bool) {
        return supermasternodes[_addr].createHeight != 0;
    }

    function isUnconfirmed(address _addr) internal view returns (bool) {
        return unconfirmedSupermasternodes[_addr].createHeight != 0;
    }

    function sortByVoteNum(address[] memory _arr, uint _left, uint _right) internal view {
        uint i = _left;
        uint j = _right;
        if (i == j) return;
        address middle = _arr[_left + (_right - _left) / 2];
        while(i <= j) {
            while(supermasternodes[_arr[i]].totalVoteNum > supermasternodes[middle].totalVoteNum) i++;
            while(supermasternodes[middle].totalVoteNum > supermasternodes[_arr[j]].totalVoteNum && j > 0) j--;
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