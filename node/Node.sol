// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INode.sol";

contract Node is INode {
    // self-lock with specified locked height
    function lock(AccountManager _am, uint _lockDay, uint _blockspace) public payable override {
        bytes20 lockID = _am.deposit(msg.sender, msg.value, _lockDay, _blockspace);
        if(lockID == 0) {
            emit SafeLock(msg.sender, msg.value, _lockDay, "lock successfully");
        } else {
            emit SafeLock(msg.sender, msg.value, _lockDay, "lock failed, please check");
        }
    }

    // send locked safe to address by locked height
    function sendLock(AccountManager _am, address _to, uint _lockDay, uint _blockspace) public payable override {
        bytes20 lockID = _am.deposit(_to, msg.value, _lockDay, _blockspace);
        if(lockID == 0) {
            emit SafeLock(_to, msg.value, _lockDay, "send lock successfully");
        } else {
            emit SafeLock(_to, msg.value, _lockDay, "send lock failed, please check");
        }
    }

    // withdraw
    function withdraw(AccountManager _am) public override {
        uint ret = _am.withdraw();
        if(ret == 0) {
            emit SafeWithdraw(msg.sender, 0, "insufficient amount");
        } else {
            emit SafeWithdraw(msg.sender, ret, "withdraw successfully");
        }
    }

    function withdraw(AccountManager _am, uint _amount) public override {
        uint ret = _am.withdraw(_amount);
        if(ret < _amount) {
            emit SafeWithdraw(msg.sender, ret, "insufficient amount");
        } else {
            emit SafeWithdraw(msg.sender, _amount, "withdraw successfully");
        }
    }

    function getTotalAmount(AccountManager _am) public view override returns (uint, bytes20[] memory) {
        return _am.getTotalAmount();
    }

    function getAvailableAmount(AccountManager _am) public view override returns (uint, bytes20[] memory) {
        return _am.getAvailableAmount();
    }

    function getLockAmount(AccountManager _am) public view override returns (uint, bytes20[] memory) {
        return _am.getLockAmount();
    }

    function getAccount(AccountManager _am) public view override returns(AccountRecord.Data[] memory) {
        return _am.getAccount();
    }

    function vote4SMN(SMNVote _smnVote, address _to) public virtual override {
        // require(isSuperMasterNode(_to), "target is not a supermasternode");
        _smnVote.vote(_to);
    }

    function removeVote4SMN(SMNVote _smnVote) public override {
        _smnVote.removeVote();
    }

    function approvalVote4SMN(SMNVote _smnVote, address _to) public override {
        //require(isMasterNode(_to), "target is not a masternode");
        _smnVote.approval(_to);
    }

    function removeApprovalVote4SMN(SMNVote _smnVote) public override {
        _smnVote.approval(address(0));
    }
}