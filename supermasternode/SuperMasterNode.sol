// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node/Node.sol";
import "../interfaces/ISuperMasterNode.sol";

contract SuperMasterNode is Node, ISuperMasterNode {

    using SuperMasterNodeInfo for SuperMasterNodeInfo.Data;

    uint id; // global masternode id
    mapping(address => SuperMasterNodeInfo.Data) supermasternodes;
    mapping(uint => address) id2supermasternode;

    function registe(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) public payable override {
        require(!exist(msg.sender), "existent supermasternode");
        require(msg.value >= 20000, "supermasternode need lock 20000 SAFE at least");
        require(_day >= 180, "supermasternode need lock 6 month at least");
        uint lockID = _am.deposit(_day * 86400 / _blockspace);
        if(lockID == 0) {
            emit SMNRegiste(msg.sender, msg.value, _day, "registe failed, please check");
            return;
        }
        SuperMasterNodeInfo.Data memory info;
        info.create(++id, lockID, msg.sender, msg.value, _ip, _pubkey, _description);
        supermasternodes[msg.sender] = info;
        id2supermasternode[id] = msg.sender;
        emit SMNRegiste(msg.sender, msg.value, _day, "registe successfully");
    }

    function unionRegiste(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) public payable override {
        require(!exist(msg.sender), "existent supermasternode");
        require(msg.value >= 4000, "you need lock 4000 SAFE when you create a union supermasternode");
        require(_day >= 360, "you need lock 1 year when you create a union supermasternode");
        uint lockID = _am.deposit(_day * 86400 / _blockspace);
        if(id == 0) {
            emit SMNUnionRegiste(msg.sender, msg.value, _day, "registe failed, please check");
            return;
        }
        SuperMasterNodeInfo.Data memory info;
        info.create(++id, lockID, msg.sender, msg.value, _ip, _pubkey, _description);
        supermasternodes[msg.sender] = info;
        id2supermasternode[id] = msg.sender;
        emit SMNUnionRegiste(msg.sender, msg.value, _day, "registe successfully");
    }

    function appendRegiste(address _addr, AccountManager _am, uint _day, uint _blockspace) public payable override {
        require(exist(_addr), "non-existent supermasternode");
        require(msg.value >= 200, "need append 200 SAFE at least");
        require(_day >= 360, "need lock 1 year at least");
        require(supermasternodes[_addr].amount < 1000, "union supermasternode has enough amount, can't append");
        require(checkUnionTime(_addr), "union supermasternode time is not enough, can't append");
        uint lockID = _am.deposit(_day * 86400 / _blockspace);
        if(lockID == 0) {
            emit SMNAppendRegiste(msg.sender, msg.value, _day, "append registe failed, please check");
            return;
        }
        supermasternodes[_addr].appendLock(lockID, msg.value);
        emit SMNAppendRegiste(msg.sender, msg.value, _day, "append registe failed, please check");
    }

    function reward(uint _amount) public override {

    }
    
    function modifyProperty(string memory _name) public override {

    }

    function uploadMasterNodeState(uint8[] memory _ids, uint8[] memory _states) public override {

    }

    function uploadState(uint8[] memory _ids, uint8[] memory _states) public override {

    }

    function changeAddress(address _addr) public override {
        supermasternodes[msg.sender].setAddress(_addr);
    }

    function changeIP(string memory _ip) public override {
        supermasternodes[msg.sender].setIP(_ip);
    }

    function changePubkey(string memory _pubkey) public override {
        supermasternodes[msg.sender].setPubkey(_pubkey);
    }

    function changeDescription(string memory _description) public override {
        supermasternodes[msg.sender].setDescription(_description);
    }

    function getInfo(address _addr) public view override returns (SuperMasterNodeInfo.Data memory) {
        require(exist(_addr), "non-existent masternode");
        return supermasternodes[_addr];
    }

    /************************************************** internal **************************************************/
    function exist(address _addr) internal view returns (bool) {
        return supermasternodes[_addr].createTime != 0;
    }

    function checkUnionTime(address _addr) internal view returns (bool) {
        if(block.timestamp - supermasternodes[_addr].createTime >= 180 * 86400) {
            return false;
        }
        return true;
    }
}