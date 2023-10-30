// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISNVote {
    struct VoteDetail {
        address addr; // supernode or proxy for voter; voterAddr for supernode or proxy
        uint totalAmount; // total voter amount
        uint totalNum; // total vote number
        uint[] recordIDs; // record id list
    }

    struct VoteRecord {
        address voterAddr; // voter address
        address dstAddr; // supernode or proxy
        uint amount; // voter amount
        uint num; // vote number
        uint height; // block height
    }

    function voteOrApproval(bool _isVote, address _dstAddr, uint[] memory _recordIDs) external;
    function removeVoteOrApproval(uint[] memory _recordIDs) external;
    function removeVoteOrApproval2(address _voterAddr, uint _recordID) external;
    function proxyVote(address _snAddr) external;
    function getSuperNodes4Voter(address _voterAddr) external view returns (address[] memory, uint[] memory);
    function getRecordIDs4Voter(address _voterAddr) external view returns (uint[] memory);
    function getVoters4SN(address _snAddr) external view returns (address[] memory, uint[] memory);
    function getVoteNum4SN(address _snAddr) external view returns (uint);
    function getProxies4Voter(address _voterAddr) external view returns (address[] memory, uint[] memory);
    function getProxiedRecordIDs4Voter(address _voterAddr) external view returns (uint[] memory);
    function getVoters4Proxy(address _proxyAddr) external view returns (address[] memory, uint[] memory);
    function getVoteNum4Proxy(address _proxyAddr) external view returns (uint);
}