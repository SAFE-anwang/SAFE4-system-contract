// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../account/AccountManager.sol";
import "../supermasternode/SMNVote.sol";

interface INode {
    event SafeLock(address _addr, uint _amount, uint _lockDay, string _msg);
    event SafeWithdraw(address _addr, uint _amount, string _msg);

    function lock(AccountManager _am, uint _lockDay, uint _blockspace) external payable;
    function sendLock(AccountManager _am, address _to, uint _lockDay, uint _blockspace) external payable;

    function withdraw(AccountManager _am) external;
    function withdraw(AccountManager _am, uint _amount) external;

    function getTotalAmount(AccountManager _am) external view returns (uint, bytes20[] memory);
    function getAvailableAmount(AccountManager _am) external view returns (uint, bytes20[] memory);
    function getLockAmount(AccountManager _am) external view returns (uint, bytes20[] memory);
    function getAccount(AccountManager _am) external view returns(AccountRecord.Data[] memory);

    function vote4SMN(SMNVote _smnVote, address _to) external;
    function removeVote4SMN(SMNVote _smnVote) external;
    function approvalVote4SMN(SMNVote _smnVote, address _to) external;
    function removeApprovalVote4SMN(SMNVote _smnVote) external;
}