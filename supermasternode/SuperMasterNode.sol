// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SuperMasterNodeInfo.sol";
import "./SMNVote.sol";
import "./MNState.sol";
import "./SMNState.sol";
import "../account/AccountManager.sol";
import "../utils/SafeMath.sol";
import "../utils/BytesUtil.sol";

contract SuperMasterNode {
    using SafeMath for uint;
    using BytesUtil for bytes;
    using SuperMasterNodeInfo for SuperMasterNodeInfo.Data;

    uint internal counter;
    AccountManager internal am;
    SafeProperty internal property;
    SMNVote internal smnVote;

    MNState internal mnState;
    SMNState internal smnState;

    mapping(address => SuperMasterNodeInfo.Data) internal supermasternodes;
    mapping(address => SuperMasterNodeInfo.Data) internal unconfirmedSupermasternodes;
    mapping(bytes20 => address) internal id2address;
    bytes20[] internal ids;

    event SMNRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event SMNUnionRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event SMNAppendRegiste(address _addr, bytes20 _lockID, string _msg);

    constructor(SafeProperty _property, AccountManager _am, SMNVote _smnVote) {
        counter = 1;
        am = _am;
        property = _property;
        smnVote = _smnVote;

        mnState = new MNState();
        smnState = new SMNState();
    }

    function registe(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable {
        require(msg.value >= 20000, "supermasternode need lock 20000 SAFE at least");
        require(_lockDay >= 365, "supermasternode need lock 1 year at least");
        require(_addr != address(0), "invalid supermasternode address");
        require(bytes(_ip).length != 0, "invalid supermasternode ip");
        require(bytes(_pubkey).length != 0, "invalid supermasternode pubkey");
        require(bytes(_description).length != 0, "invalid supermasternode description");
        require(_creatorIncentive.add(_partnerIncentive).add(_voterIncentive) == 100, "invalid incentive plan");
        require(!exist(_addr), "existent supermasternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit SMNRegiste(_addr, _ip, _pubkey, "registe supermasternode failed: lock failed");
            return;
        }

        bytes20 id = ripemd160(abi.encodePacked(getCounter(), msg.sender, _lockDay, _addr, _ip, _pubkey));
        if(block.number > property.getProperty("smn_unverify_height").value.toUint()) { // don't need verify
            supermasternodes[_addr].create(id, msg.sender, msg.value, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
            supermasternodes[_addr].addr = _addr;
        } else { // need verify
            unconfirmedSupermasternodes[_addr].create(id, msg.sender, msg.value, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
            unconfirmedSupermasternodes[_addr].addr = _addr;
        }
        id2address[id] = _addr;
        ids.push(id);
        am.setBindDay(lockID, _lockDay); // creator's lock id can't unbind util unlock it
        emit SMNRegiste(_addr, _ip, _pubkey, "registe supermasternode successfully");
    }

    function unionRegiste(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable {
        require(msg.value >= 4000, "union supermasternode need lock 4000 SAFE at least");
        require(_lockDay >= 730, "union supermasternode need lock 2 year at least");
        require(_addr != address(0), "invalid supermasternode address");
        require(bytes(_ip).length != 0, "invalid supermasternode ip");
        require(bytes(_pubkey).length != 0, "invalid supermasternode pubkey");
        require(bytes(_description).length != 0, "invalid supermasternode description");
        require(_creatorIncentive.add(_partnerIncentive).add(_voterIncentive) == 100, "invalid incentive plan");
        require(!exist(_addr), "existent supermasternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit SMNRegiste(_addr, _ip, _pubkey, "registe union supermasternode failed: lock failed");
            return;
        }

        bytes20 id = ripemd160(abi.encodePacked(getCounter(), msg.sender, _lockDay, _addr, _ip, _pubkey));
        if(block.number > property.getProperty("smn_unverify_height").value.toUint()) { // don't need verify
            supermasternodes[_addr].create(id, msg.sender, msg.value, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
            supermasternodes[_addr].addr = _addr;
        } else { // need verify
            unconfirmedSupermasternodes[_addr].create(id, msg.sender, msg.value, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
            unconfirmedSupermasternodes[_addr].addr = _addr;
        }
        id2address[id] = _addr;
        ids.push(id);
        am.setBindDay(lockID, _lockDay); // creator's lock id can't unbind util unlock it
        emit SMNRegiste(_addr, _ip, _pubkey, "registe union supermasternode successfully");
    }

    function appendRegiste(uint _lockDay, address _addr) public payable {
        require(msg.value >= 1000, "supermasternode need append lock 1000 SAFE at least");
        require(_lockDay >= 365, "supermasternode need lock 1 year at least");
        require(exist(_addr), "non-existent supermasternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit SMNAppendRegiste(_addr, lockID, "append registe union supermasternode failed: lock failed");
            return;
        }

        if(isConfirmed(_addr)) {
            supermasternodes[_addr].appendLock(lockID, msg.sender, msg.value);
        } else {
            unconfirmedSupermasternodes[_addr].appendLock(lockID, msg.sender, msg.value);
        }
        am.setBindDay(lockID, 90); // lock id can't be unbind util 90 days.
        emit SMNAppendRegiste(_addr, lockID, "append registe supermasternode successfully");
    }

    function appendRegiste(bytes20 _lockID, address _addr) public {
        AccountRecord.Data memory record = am.getRecordByID(msg.sender, _lockID);
        require(record.bindInfo.bindHeight == 0, "lock id is bind, can't append");
        require(record.addr == msg.sender, "lock address isn't caller");
        require(record.amount >= 1000, "lock amout need 1000 SAFE at least");
        require(record.lockDay >= 365, "lock day less 1 year");

        if(isConfirmed(_addr)) {
            supermasternodes[_addr].appendLock(_lockID, record.addr, record.amount);
        } else {
            unconfirmedSupermasternodes[_addr].appendLock(_lockID, record.addr, record.amount);
        }
        am.setBindDay(_lockID, 90); // lock id can't be unbind util 90 days.
        emit SMNAppendRegiste(_addr, _lockID, "append registe supermasternode successfully");
    }

    function verify(address _addr) public {
        require(isUnconfirmed(_addr), "non-existent unconfirmed supermasternode");
        require(!isConfirmed(_addr), "existent confirmed supermasternode");
        supermasternodes[_addr] = unconfirmedSupermasternodes[_addr];
        delete unconfirmedSupermasternodes[_addr];
    }

    function reward(address _addr, uint _amount) public {
        SuperMasterNodeInfo.Data memory info = supermasternodes[_addr];
        uint creatorReward = _amount.mul(info.incentivePlan.creator).div(100);
        uint partnerReward = _amount.mul(info.incentivePlan.partner).div(100);
        uint voterReward = _amount.sub(creatorReward).sub(partnerReward);
        // reward to creator
        am.reward(info.creator, creatorReward, 7);
        // reward to partner
        uint total = 0;
        for(uint i = 0; i < info.founders.length; i++) {
            if(total.add(info.founders[i].amount) <= 20000) {
                am.reward(info.founders[i].addr, partnerReward.mul(info.founders[i].amount).div(20000), 7);
                total = total.add(info.founders[i].amount);
                if(total == 20000) {
                    break;
                }
            } else {
                am.reward(info.founders[i].addr, partnerReward.mul(20000 - total).div(20000), 6);
                break;
            }
        }
        // reward to voter
        for(uint i = 0; i < info.voters.length; i++) {
            am.reward(info.founders[i].addr, voterReward.mul(info.voters[i].amount).div(info.totalVoterAmount), 7);
        }
    }

    function applyUpdateProperty(SafeProperty _property, string memory _name, bytes memory _value, string memory _reason) public {
        _property.applyUpdateProperty(_name, _value, _reason);
    }

    function vote4UpdateProperty(SafeProperty _property, string memory _name, uint _result) public {
        _property.vote4UpdateProperty(_name, _result, getNum());
    }

    function uploadMasterNodeState(uint[] memory _ids, uint8[] memory _states) public {
        mnState.uploadState(_ids, _states, getNum());
    }

    function uploadSuperMasterNodeState(bytes20[] memory _ids, uint8[] memory _states) public {
        smnState.uploadState(_ids, _states, getNum());
    }

    function changeAddress(address _addr, address _newAddr) public {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(isConfirmed(_addr), "unconfirmed supermasternode can't change address");
        require(!exist(_newAddr), "new masternode address has exist");
        require(_newAddr != address(0), "invalid address");
        supermasternodes[_newAddr] = supermasternodes[_addr];
        supermasternodes[_newAddr].setAddress(_newAddr);
        id2address[supermasternodes[_newAddr].id] = _newAddr;
    }

    function changeIP(address _addr, string memory _newIP) public {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(bytes(_newIP).length > 0, "invalid ip");
        supermasternodes[_addr].setIP(_newIP);
    }

    function changePubkey(address _addr, string memory _newPubkey) public {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(bytes(_newPubkey).length > 0, "invalid pubkey");
        supermasternodes[_addr].setPubkey(_newPubkey);
    }

    function changeDescription(address _addr, string memory _newDescription) public {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(bytes(_newDescription).length > 0, "invalid description");
        supermasternodes[_addr].setDescription(_newDescription);
    }

    function getInfo(address _addr) public view returns (SuperMasterNodeInfo.Data memory) {
        require(exist(_addr), "non-existent masternode");
        return supermasternodes[_addr];
    }

    function getTop() public view returns (SuperMasterNodeInfo.Data[] memory) {
        uint num = 0;
        for(uint i = 0; i < ids.length; i++) {
            address addr = id2address[ids[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= 20000) {
                    num++;
                }
            }
        }

        address[] memory smnAddrs = new address[](num);
        uint k = 0;
        for(uint i = 0; i < ids.length; i++) {
            address addr = id2address[ids[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= 20000) {
                    smnAddrs[k++] = addr;
                }
            }
        }

        // sort by vote number
        sortByVote(smnAddrs, 0, smnAddrs.length - 1);

        // get top, max: 21
        num = 21;
        if(smnAddrs.length < 21) {
            num = smnAddrs.length;
        }
        SuperMasterNodeInfo.Data[] memory ret = new SuperMasterNodeInfo.Data[](num);
        for(uint i = 0; i < num; i++) {
            ret[i] = supermasternodes[smnAddrs[i]];
        }
        return ret;
    }

    /************************************************** internal **************************************************/
    function getCounter() internal returns (uint) {
        return counter++;
    }

    function exist(address _addr) internal view returns (bool) {
        return isConfirmed(_addr) || isUnconfirmed(_addr);
    }

    function exist(bytes20 _id) public view returns (bool) {
        return id2address[_id] != address(0);
    }

    function isConfirmed(address _addr) public view returns (bool) {
        return supermasternodes[_addr].createTime != 0;
    }

    function isUnconfirmed(address _addr) internal view returns (bool) {
        return unconfirmedSupermasternodes[_addr].createTime != 0;
    }

    function checkUnionTime(address _addr) internal view returns (bool) {
        if(block.timestamp - supermasternodes[_addr].createTime >= 180 * 86400) {
            return false;
        }
        return true;
    }

    function sortByVote(address[] memory _arr, uint _left, uint _right) internal view {
        uint i = _left;
        uint j = _right;
        if (i == j) return;
        address middle = _arr[_left + (_right - _left) / 2];
        while(i <= j) {
            while(smnVote.getVoteNum(_arr[i]) > smnVote.getVoteNum(middle)) i++;
            while(smnVote.getVoteNum(middle) > smnVote.getVoteNum(_arr[j]) && j > 0) j--;
            if(i <= j) {
                (_arr[i], _arr[j]) = (_arr[j], _arr[i]);
                i++;
                if(j != 0) j--;
            }
        }
        if(_left < j)
            sortByVote(_arr, _left, j);
        if(i < _right)
            sortByVote(_arr, i, _right);
    }

    function getNum() internal view returns (uint) {
        uint num = 0;
        for(uint i = 0; i < ids.length; i++) {
            address addr = id2address[ids[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= 20000) {
                    num++;
                }
            }
        }
        if(num >= 21) {
            return 21;
        }
        return num;
    }
}