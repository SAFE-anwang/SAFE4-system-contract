// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../types/SMNVoteType.sol";

interface ISMNVote {
    function vote(address _smnAddr, bytes20[] memory _recordIDs) external;
    function vote(address _smnAddr, bytes20 _recordID) external;
    function removeVote(bytes20[] memory _recordIDs) external;
    function removeVote(bytes20 _recordID) external;
    function decreaseRecord(bytes20 _recordID, uint _amount, uint _num) external;
    function proxyVote(address _smnAddr) external;
    function approval(address _proxyAddr, bytes20[] memory _recordIDs) external;
    function approval(address _proxyAddr, bytes20 _recordID) external;
    function removeApproval(bytes20[] memory _recordIDs) external;
    function removeApproval(bytes20 _recordID) external;
    function getVotedSMN4Voter() external view returns (address[] memory, uint[] memory);
    function getVotedRecords4Voter() external view returns (bytes20[] memory recordIDs);
    function getVoters4SMN(address _smnAddr) external view returns (address[] memory);
    function getVoteNum4SMN(address _smnAddr) external view returns (uint);
    function getProxies4Voter() external view returns (address[] memory, uint[] memory);
    function getProxiedRecords4Voter() external view returns (bytes20[] memory recordIDs);
    function getVoters4Proxy() external view returns (address[] memory);
    function getVoteNum4Proxy() external view returns (uint);
}