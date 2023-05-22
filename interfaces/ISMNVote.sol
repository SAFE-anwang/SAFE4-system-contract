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

    function vote(address _snAddr, uint[] memory _recordIDs) external;
    function vote(address _snAddr, uint _recordID) external;
    function removeVote(uint[] memory _recordIDs) external;
    function removeVote(uint _recordID) external;
    function decreaseRecord(uint _recordID, uint _amount, uint _num) external;
    function proxyVote(address _snAddr) external;
    function approval(address _proxyAddr, uint[] memory _recordIDs) external;
    function approval(address _proxyAddr, uint _recordID) external;
    function removeApproval(uint[] memory _recordIDs) external;
    function removeApproval(uint _recordID) external;
    function getVotedSN4Voter() external view returns (address[] memory, uint[] memory);
    function getVotedRecords4Voter() external view returns (uint[] memory recordIDs);
    function getVoters4SN(address _snAddr) external view returns (address[] memory);
    function getVoteNum4SN(address _snAddr) external view returns (uint);
    function getProxies4Voter() external view returns (address[] memory, uint[] memory);
    function getProxiedRecords4Voter() external view returns (uint[] memory recordIDs);
    function getVoters4Proxy() external view returns (address[] memory);
    function getVoteNum4Proxy() external view returns (uint);
}