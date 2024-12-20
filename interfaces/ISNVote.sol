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
    function voteOrApprovalWithAmount(bool _isVote, address _dstAddr) external payable;
    function removeVoteOrApproval(uint[] memory _recordIDs) external; // delete vote by recordIDs
    function removeVoteOrApproval2(address _voterAddr, uint _recordID) external; // delete vote by voteAddr & recordID
    function clearVoteOrApproval(address _dstAddr) external; // clear vote by dstAddr
    function proxyVote(address _snAddr) external;

    // get voter's total amount
    function getAmount4Voter(address _voterAddr) external view returns (uint);
    // get voter's total voteNum
    function getVoteNum4Voter(address _voterAddr) external view returns (uint);

    // get voter's supernode number
    function getSNNum4Voter(address _voterAddr) external view returns (uint);
    // get voter's supernodes & voteNums
    function getSNs4Voter(address _voterAddr, uint _start, uint _count) external view returns (address[] memory, uint[] memory);

    // get voter's proxy number
    function getProxyNum4Voter(address _voterAddr) external view returns (uint);
    // get voter's proxies & voteNums
    function getProxies4Voter(address _voterAddr, uint _start, uint _count) external view returns (address[] memory, uint[] memory);

    // get voter's voted record number
    function getVotedIDNum4Voter(address _voterAddr) external view returns (uint);
    // get voter's voted record ids
    function getVotedIDs4Voter(address _voterAddr, uint _start, uint _count) external view returns (uint[] memory);

    // get voter's proxied record number
    function getProxiedIDNum4Voter(address _voterAddr) external view returns(uint);
    // get voter's proxied record ids
    function getProxiedIDs4Voter(address _voterAddr, uint _start, uint _count) external view returns (uint[] memory);

    // get supernode's/proxy's total amount
    function getTotalAmount(address _addr) external view returns (uint);
    // get supernodes's/proxy's total voteNum
    function getTotalVoteNum(address _addr) external view returns (uint);

    // get supernode's/proxy's voter number
    function getVoterNum(address _addr) external view returns (uint);
    // get supernode's/proxy's voters & voteNums
    function getVoters(address _addr, uint _start, uint _count) external view returns (address[] memory, uint[] memory);

    // get supernode's/proxy's voter record id number
    function getIDNum(address _addr) external view returns (uint);
    // get supernode's/proxy's voter record ids
    function getIDs(address _addr, uint _start, uint _count) external view returns (uint[] memory);

    // get all supernodes received amount
    function getAllAmount() external view returns (uint);
    // get all supernodes received voteNum
    function getAllVoteNum() external view returns (uint);
    // get all proxies received amount
    function getAllProxiedAmount() external view returns (uint);
    // get all proxies received voteNum
    function getAllProxiedVoteNum() external view returns (uint);

}