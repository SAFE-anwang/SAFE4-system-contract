// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISNVote {
    struct SNVoteDetail {
        address[] dstAddrs; // supernodes or proxy
        uint[] totalAmounts; // total voter amounts
        uint[] totalNums; // total vote numbers
        SNVoteEntry[][] entries;
    }

    struct SNVoteEntry {
        uint recordID; // record id
        uint amount; // voter amount
        uint num; // vote number
        uint height; // vote height
    }

    struct SNVoteRecord {
        address voterAddr; // voter address
        address dstAddr; // supernode or proxy
        uint index; // index of vote entry
        uint height; // block height
    }

    event SNVOTE_VOTE(address _voterAddr, address _snAddr, uint _recordID, uint _voteNum);
    event SNVOTE_APPROVAL(address _voterAddr, address _proxyAddr, uint _recordID, uint _voteNum);
    event SNVOTE_REMOVE_VOTE(address _voterAddr, address _snAddr, uint _recordID, uint _voteNum);
    event SNVOTE_REMOVE_APPROVAL(address _voterAddr, address _proxyAddr, uint _recordID, uint _voteNum);

    function voteOrApproval(bool _isVote, address _dstAddr, uint[] memory _recordIDs) external;
    function voteOrApproval(bool _isVote, address _dstAddr, uint _recordID) external;
    function removeVoteOrApproval(uint[] memory _recordIDs) external;
    function removeVoteOrApproval(uint _recordID) external;
    function proxyVote(address _snAddr) external;
    function getVotedSN4Voter(address _voterAddr) external view returns (address[] memory, uint[] memory);
    function getVotedRecords4Voter(address _voterAddr) external view returns (uint[] memory recordIDs);
    function getVoters4SN(address _snAddr) external view returns (address[] memory);
    function getVoteNum4SN(address _snAddr) external view returns (uint);
    function getProxies4Voter(address _voterAddr) external view returns (address[] memory, uint[] memory);
    function getProxiedRecords4Voter(address _voterAddr) external view returns (uint[] memory recordIDs);
    function getVoters4Proxy(address _proxyAddr) external view returns (address[] memory);
    function getVoteNum4Proxy(address _proxyAddr) external view returns (uint);
}