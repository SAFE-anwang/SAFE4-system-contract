// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node/Node.sol";
import "../interfaces/IMasterNode.sol";

contract MasterNode is Node, IMasterNode {

    using MasterNodeInfo for MasterNodeInfo.Data;

    uint id; // global masternode id
    mapping(address => MasterNodeInfo.Data) masternodes;
    mapping(uint => address) id2masternode;

    function registe(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) public payable override {
        require(!exist(msg.sender), "existent masternode");
        require(msg.value >= 1000, "masternode need lock 1000 SAFE at least");
        require(_day >= 180, "masternode need lock 6 month at least");
        uint lockID = _am.deposit(_day * 86400 / _blockspace);
        if(lockID == 0) {
            emit MNRegiste(msg.sender, msg.value, _day, "registe failed, please check");
            return;
        }
        MasterNodeInfo.Data memory info;
        info.create(++id, lockID, msg.sender, msg.value, _ip, _pubkey, _description);
        masternodes[msg.sender] = info;
        id2masternode[id] = msg.sender;
        emit MNRegiste(msg.sender, msg.value, _day, "registe successfully");
    }

    function unionRegiste(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) public payable override {
        require(!exist(msg.sender), "existent masternode");
        require(msg.value >= 200, "you need lock 200 SAFE when you create a union masternode");
        require(_day >= 360, "you need lock 1 year when you create a union masternode");
        uint lockID = _am.deposit(_day * 86400 / _blockspace);
        if(id == 0) {
            emit MNUnionRegiste(msg.sender, msg.value, _day, "registe failed, please check");
            return;
        }
        MasterNodeInfo.Data memory info;
        info.create(++id, lockID, msg.sender, msg.value, _ip, _pubkey, _description);
        masternodes[msg.sender] = info;
        emit MNUnionRegiste(msg.sender, msg.value, _day, "registe successfully");
    }

    function appendRegiste(address _addr, AccountManager _am, uint _day, uint _blockspace) public payable override {
        require(exist(_addr), "non-existent masternode");
        require(msg.value >= 50, "need append 50 SAFE at least");
        require(_day >= 360, "need lock 1 year at least");
        require(msg.value + masternodes[_addr].amount < 1000, "masternode has enough amount, can't append");
        uint lockID = _am.deposit(_day * 86400 / _blockspace);
        if(lockID == 0) {
            emit MNAppendRegiste(msg.sender, msg.value, _day, "append registe failed, please check");
            return;
        }
        masternodes[_addr].appendLock(lockID, msg.value);
        emit MNAppendRegiste(msg.sender, msg.value, _day, "append registe failed, please check");
    }

    function vote4SMN(SMNVote _smnVote, address _to) public override {
        super.vote4SMN(_smnVote, _to);
        _smnVote.proxyVote(_to);
    }

    function applyProposal() public pure override returns (uint) {
        return 0;
    }

    function vote4proposal(uint _proposalID, uint _result) public override {
    }

    function changeAddress(address _addr) public override {
        masternodes[msg.sender].setAddress(_addr);
    }

    function changeIP(string memory _ip) public override {
        masternodes[msg.sender].setIP(_ip);
    }

    function changePubkey(string memory _pubkey) public override {
        masternodes[msg.sender].setPubkey(_pubkey);
    }

    function changeDescription(string memory _description) public override {
        masternodes[msg.sender].setDescription(_description);
    }

    function getApprovalVote4SMN(SMNVote _smnVote) public view override returns (SMNVote.ProxyInfo[] memory) {
        return _smnVote.getApprovals();
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