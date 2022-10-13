// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INode.sol";

contract Node is INode {
    event SafeLock(address _addr, uint _amount, string _err);
    event SafeWithdraw(address _addr, uint _amount, string _err);

    // self-lock with specified locked height
    function lock(AccountManager _am, uint _lockHeight) public payable override {
        uint id = _am.deposit(_lockHeight);
        if(id == 0) {
            emit SafeLock(msg.sender, msg.value, "lock successfully");
        } else {
            emit SafeLock(msg.sender, msg.value, "lock failed, please check");
        }
    }

    // self-lock with specified locked day, unlocked height is calculated by block space
    function lock(AccountManager _am, uint _day, uint _blockspace) public payable override {
        lock(_am, _day * 86400 / _blockspace);
    }

    // send locked safe to address by locked height
    function sendLock(AccountManager _am, address _to, uint _lockHeight) public payable override {
        uint id = _am.deposit(_lockHeight);
        if(id == 0) {
            emit SafeLock(_to, msg.value, "lock successfully");
        } else {
            emit SafeLock(_to, msg.value, "lock failed, please check");
        }
    }

    // send locked safe to address by locked month, unlocked height is calculated by block space
    function sendLock(AccountManager _am, address _to, uint _day, uint _blockspace) public payable override {
        sendLock(_am, _to, _day * 86400 / _blockspace);
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

    function getTotalAmount(AccountManager _am) public view override returns (uint, uint[] memory) {
        return _am.getTotalAmount();
    }

    function getAvailableAmount(AccountManager _am) public view override returns (uint, uint[] memory) {
        return _am.getAvailableAmount();
    }

    function getLockAmount(AccountManager _am) public view override returns (uint, uint[] memory) {
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