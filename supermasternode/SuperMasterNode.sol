// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISuperMasterNode.sol";
import "../utils/Owner.sol";
import "../utils/SafeMath.sol";
import "../utils/BytesUtil.sol";

contract SuperMasterNode is ISuperMasterNode, Owner {
    using SafeMath for uint;
    using BytesUtil for bytes;
    using SuperMasterNodeInfo for SuperMasterNodeInfo.Data;

    uint internal counter;
    AccountManager internal am;
    SafeProperty internal property;

    mapping(address => SuperMasterNodeInfo.Data) internal supermasternodes;
    mapping(address => SuperMasterNodeInfo.Data) internal unconfirmedSupermasternodes;
    mapping(bytes20 => address) internal id2address;
    bytes20[] internal ids;

    constructor(SafeProperty _property, AccountManager _am) {
        counter = 1;
        am = _am;
        property = _property;
    }

    function registe(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable override {
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
            supermasternodes[_addr].create(id, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
        } else { // need verify
            unconfirmedSupermasternodes[_addr].create(id, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
        }
        id2address[id] = _addr;
        ids.push(id);
        am.setUseHeight(lockID, block.number);
        emit SMNRegiste(_addr, _ip, _pubkey, "registe supermasternode successfully");
    }

    function unionRegiste(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable override {
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
            supermasternodes[_addr].create(id, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
        } else { // need verify
            unconfirmedSupermasternodes[_addr].create(id, lockID, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
        }
        id2address[id] = _addr;
        ids.push(id);
        am.setUseHeight(lockID, block.number);
        emit SMNRegiste(_addr, _ip, _pubkey, "registe union supermasternode successfully");
    }

    function appendRegiste(uint _lockDay, address _addr) public payable override {
        require(msg.value >= 1000, "supermasternode need append lock 1000 SAFE at least");
        require(_lockDay >= 365, "supermasternode need lock 1 year at least");
        require(exist(_addr), "non-existent supermasternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit SMNAppendRegiste(_addr, lockID, "append registe union supermasternode failed: lock failed");
            return;
        }

        uint leaveHeight = block.number.add(uint(90 * 86400).div(property.getProperty("block_space").value.toUint()));
        if(isConfirmed(_addr)) {
            supermasternodes[_addr].appendLock(lockID, msg.sender, msg.value, leaveHeight);
        } else {
            unconfirmedSupermasternodes[_addr].appendLock(lockID, msg.sender, msg.value, leaveHeight);
        }
        am.setUseHeight(lockID, block.number);
        emit SMNAppendRegiste(_addr, lockID, "append registe supermasternode successfully");
    }

    function appendRegiste(bytes20 _lockID, address _addr) public override {
        AccountRecord.Data memory record = am.getRecordByID(msg.sender, _lockID);
        require(record.useHeight == 0, "lock id is used, can't append");
        require(record.addr == msg.sender, "lock address isn't caller");
        require(record.amount >= 1000, "lock amout need 1000 SAFE at least");
        require(record.lockDay >= 365, "lock day less 1 year");

        uint leaveHeight = block.number.add(uint(90 * 86400).div(property.getProperty("block_space").value.toUint()));
        if(isConfirmed(_addr)) {
            supermasternodes[_addr].appendLock(_lockID, record.addr, record.amount, leaveHeight);
        } else {
            unconfirmedSupermasternodes[_addr].appendLock(_lockID, record.addr, record.amount, leaveHeight);
        }
        am.setUseHeight(_lockID, block.number);
        emit SMNAppendRegiste(_addr, _lockID, "append registe supermasternode successfully");
    }

    function verify(address _addr) public isOwner override {
        require(isUnconfirmed(_addr), "non-existent unconfirmed supermasternode");
        require(!isConfirmed(_addr), "existent confirmed supermasternode");
        supermasternodes[_addr] = unconfirmedSupermasternodes[_addr];
        delete unconfirmedSupermasternodes[_addr];
    }

    function reward(address _addr, uint _amount) public override {
        SuperMasterNodeInfo.Data memory info = supermasternodes[_addr];
        uint creatorReward = _amount.mul(info.incentivePlan.creator).div(100);
        uint partnerReward = _amount.mul(info.incentivePlan.partner).div(100);
        uint voterReward = _amount.sub(creatorReward).sub(partnerReward);
        // reward to creator
        am.reward(info.creator, creatorReward);
        // reward to partner
        uint total = 0;
        for(uint i = 0; i < info.founders.length; i++) {
            total = info.founders[i].amount.add(total);
            if(total >= 20000) {
                break;
            }
            am.reward(info.founders[i].addr, partnerReward.mul(info.founders[i].amount).div(20000 - info.founders[0].amount));
        }
        // reward to voter
        for(uint i = 0; i < info.voters.length; i++) {
            am.reward(info.founders[i].addr, voterReward.mul(info.voters[i].amount).div(info.totalVoterAmount));
        }
    }

    function applyUpdateProperty(SafeProperty _property, string memory _name, bytes memory _value, string memory _reason) public override {
        _property.applyUpdateProperty(_name, _value, _reason);
    }

    function vote4UpdateProperty(SafeProperty _property, string memory _name, uint _result) public override {
        _property.vote4UpdateProperty(_name, _result, getTop().length);
    }

    function uploadMasternodeState(uint[] memory _ids, uint8[] memory _states) public override {
    }

    function uploadSuperMasternodeState(bytes20[] memory _ids, uint8[] memory _states) public override {
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(isConfirmed(_addr), "unconfirmed supermasternode can't change address");
        require(!exist(_newAddr), "new masternode address has exist");
        require(_newAddr != address(0), "invalid address");
        supermasternodes[_newAddr] = supermasternodes[_addr];
        id2address[supermasternodes[_newAddr].id] = _newAddr;
    }

    function changeIP(address _addr, string memory _newIP) public override {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(bytes(_newIP).length > 0, "invalid ip");
        supermasternodes[_addr].setIP(_newIP);
    }

    function changePubkey(address _addr, string memory _newPubkey) public override {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(bytes(_newPubkey).length > 0, "invalid pubkey");
        supermasternodes[_addr].setPubkey(_newPubkey);
    }

    function changeDescription(address _addr, string memory _newDescription) public override {
        require(msg.sender == supermasternodes[_addr].creator, "caller isn't supermasternode creator");
        require(bytes(_newDescription).length > 0, "invalid description");
        supermasternodes[_addr].setDescription(_newDescription);
    }

    function getInfo(address _addr) public view override returns (SuperMasterNodeInfo.Data memory) {
        require(exist(_addr), "non-existent masternode");
        return supermasternodes[_addr];
    }

    function getTop() public view override returns (SuperMasterNodeInfo.Data[] memory) {
        uint num = 0;
        for(uint i = 0; i < ids.length; i++) {
            address addr = id2address[ids[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= 20000) {
                    num++;
                }
            }
        }

        SuperMasterNodeInfo.Data[] memory temp = new SuperMasterNodeInfo.Data[](num);
        uint k = 0;
        for(uint i = 0; i < ids.length; i++) {
            address addr = id2address[ids[i]];
            if(isConfirmed(addr)) {
                if(supermasternodes[addr].amount >= 20000) {
                    temp[k++] = supermasternodes[addr];
                }
            }
        }

        // TODO: sort
        // TODO: return top 21
        return temp;
    }

    /************************************************** internal **************************************************/
    function getCounter() internal returns (uint) {
        return counter++;
    }

    function exist(address _addr) internal view returns (bool) {
        return isConfirmed(_addr) || isUnconfirmed(_addr);
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
}