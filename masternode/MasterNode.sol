// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node/Node.sol";
import "../interfaces/IMasterNode.sol";
import "../utils/SafeMath.sol";
import "../utils/BytesUtil.sol";

contract MasterNode is IMasterNode {
    using SafeMath for uint;
    using BytesUtil for bytes;
    using MasterNodeInfo for MasterNodeInfo.Data;

    uint internal counter; // global masternode id

    mapping(address => MasterNodeInfo.Data) masternodes;
    mapping(uint => address) id2address;

    AccountManager internal am;
    SafeProperty internal property;

    constructor(SafeProperty _property, AccountManager _am) {
        counter = 1;
        property = _property;
        am = _am;
    }

    function registe(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description) public payable override {
        require(msg.value >= 1000, "masternode need lock 1000 SAFE at least");
        require(_lockDay >= 180, "masternode need lock 6 month at least");
        require(_addr != address(0), "invalid masternode address");
        require(bytes(_ip).length != 0, "invalid masternode ip");
        require(bytes(_pubkey).length != 0, "invalid masternode pubkey");
        require(bytes(_description).length != 0, "invalid masternode description");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit MNRegiste(_addr, _ip, _pubkey, "registe masternode failed: lock failed");
            return;
        }

        uint id = counter++;
        masternodes[_addr].create(id, lockID, _ip, _pubkey, _description);
        id2address[id] = _addr;
        am.setUseHeight(lockID, block.number);
        emit MNRegiste(_addr, _ip, _pubkey, "registe masternode successfully");
    }

    function unionRegiste(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description) public payable override {
        require(msg.value >= 200, "union masternode need lock 200 SAFE at least");
        require(_lockDay >= 365, "union masternode need lock 1 year at least");
        require(_addr != address(0), "invalid supermasternode address");
        require(bytes(_ip).length != 0, "invalid supermasternode ip");
        require(bytes(_pubkey).length != 0, "invalid supermasternode pubkey");
        require(bytes(_description).length != 0, "invalid supermasternode description");
        require(!exist(_addr), "existent masternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit MNUnionRegiste(_addr, _ip, _pubkey, "registe union masternode failed: lock failed");
            return;
        }

        uint id = counter++;
        masternodes[_addr].create(id, lockID, _ip, _pubkey, _description);
        id2address[id] = _addr;
        am.setUseHeight(lockID, block.number);
        emit MNRegiste(_addr, _ip, _pubkey, "registe union masternode successfully");
    }

    function appendRegiste(uint _lockDay, address _addr) public payable override {
        require(msg.value >= 50, "masternode need append lock 50 SAFE at least");
        require(_lockDay >= 180, "masternode need lock 6 month at least");
        require(exist(_addr), "non-existent masternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit MNAppendRegiste(_addr, lockID, "append registe union masternode failed: lock failed");
            return;
        }

        uint leaveHeight = block.number.add(uint(30 * 86400).div(property.getProperty("block_space").value.toUint()));
        masternodes[_addr].appendLock(lockID, msg.sender, msg.value, leaveHeight);
        am.setUseHeight(lockID, block.number);
        emit MNAppendRegiste(_addr, lockID, "append registe masternode successfully");
    }

    function appendRegiste(bytes20 _lockID, address _addr) public override {
        AccountRecord.Data memory record = am.getRecordByID(_lockID);
        require(record.useHeight == 0, "lock id is used, can't append");
        require(record.addr == msg.sender, "lock address isn't caller");
        require(record.amount >= 50, "lock amout need 50 SAFE at least");
        require(record.lockDay >= 180, "lock day less 6 month");

        uint blockspace = BytesUtil.toUint(property.getProperty("block_space").value);
        uint leaveHeight = block.number.add(uint(30 * 86400).div(blockspace));
        masternodes[_addr].appendLock(_lockID, record.addr, record.amount, leaveHeight);
        am.setUseHeight(_lockID, block.number);
        emit MNAppendRegiste(_addr, _lockID, "append registe masternode successfully");
    }

    function applyProposal() public pure override returns (bytes20) {
        return 0;
    }

    function vote4proposal(bytes20 _proposalID, uint _result) public override {
    }

    function changeAddress(address _addr, address _newAddr) public override {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(exist(_addr), "non-existent masternode");
        require(!exist(_newAddr), "new masternode address has exist");
        require(_newAddr != address(0), "invalid address");
        masternodes[_newAddr] = masternodes[_addr];
        id2address[masternodes[_newAddr].id] = _newAddr;
    }

    function changeIP(address _addr, string memory _newIP) public override {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_newIP).length > 0, "invalid ip");
        masternodes[_addr].setIP(_newIP);
    }

    function changePubkey(address _addr, string memory _newPubkey) public override {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_newPubkey).length > 0, "invalid pubkey");
        masternodes[_addr].setPubkey(_newPubkey);
    }

    function changeDescription(address _addr, string memory _newDescription) public override {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_newDescription).length > 0, "invalid description");
        masternodes[_addr].setDescription(_newDescription);
    }

    function getInfo(address _addr) public view override returns (MasterNodeInfo.Data memory) {
        require(exist(_addr), "non-existent masternode");
        return masternodes[_addr];
    }

    /************************************************** internal **************************************************/
    function exist(address _addr) internal view returns (bool) {
        return masternodes[_addr].createTime != 0;
    }
}