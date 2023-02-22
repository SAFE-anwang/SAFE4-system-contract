// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../types/SMNVoteType.sol";

interface ISMNVote {
    function vote(address _smnAddr, bytes20[] memory _recordIDs) external;
    function vote(address _smnAddr, bytes20 _recordID) external;
    function removeVote(bytes20[] memory _recordIDs) external;
    function removeVote(bytes20 _recordID) external;
    function DecreaseVoteNum(bytes20 _recordID, uint _amount, uint _num) external;
    function proxyVote(address _smnAddr) external;
    function approval(address _proxyAddr, bytes20[] memory _recordIDs) external;
    function approval(address _proxyAddr, bytes20 _recordID) external;
    function removeApproval(bytes20[] memory _recordIDs) external;
    function removeApproval(bytes20 _recordID) external;
    function DecreaseApprovalNum(bytes20 _recordID,  uint _amount, uint _num) external;
    function getVotedSMN() external view returns (address[] memory, uint[] memory);
    function getVotedRecords() external view returns (bytes20[] memory recordIDs);
    function getVoters(address _smnAddr) external view returns (address[] memory);
    function getVoteNum(address _smnAddr) external view returns (uint);
    function getApproval() external view returns (address[] memory, uint[] memory);
    function getApprovalRecords() external view returns (bytes20[] memory recordIDs);
    function getProxiedVoters() external view returns (address[] memory);
    function getProxiedVoteNum() external view returns (uint);
}