// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../account/AccountManager.sol";
import "../supermasternode/SMNVote.sol";

interface INode {
    function lock(AccountManager _am, uint _lockHeight) external payable;
    function lock(AccountManager _am, uint _day, uint _blockspace) external payable;
    function sendLock(AccountManager _am, address _to, uint _lockHeight) external payable;
    function sendLock(AccountManager _am, address _to, uint _day, uint _blockspace) external payable;

    function withdraw(AccountManager _am) external;
    function withdraw(AccountManager _am, uint _amount) external;

    function getTotalAmount(AccountManager _am) external view returns (uint, uint[] memory);
    function getAvailableAmount(AccountManager _am) external view returns (uint, uint[] memory);
    function getLockAmount(AccountManager _am) external view returns (uint, uint[] memory);
    function getAccount(AccountManager _am) external view returns(AccountRecord.Data[] memory);

    function vote4SMN(SMNVote _smnVote, address _to) external;
    function removeVote4SMN(SMNVote _smnVote) external;
    function approvalVote4SMN(SMNVote _smnVote, address _to) external;
    function removeApprovalVote4SMN(SMNVote _smnVote) external;
}