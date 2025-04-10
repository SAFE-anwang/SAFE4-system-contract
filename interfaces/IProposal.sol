// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProposal {
    struct ProposalInfo {
        uint id;
        address creator;
        string title;
        uint payAmount;
        uint payTimes;
        uint startPayTime;
        uint endPayTime;
        string description;
        uint state;
        uint createHeight;
        uint updateHeight;
    }

    struct VoteInfo {
        address voter;
        uint voteResult;
    }

    function reward() external payable;
    function getBalance() external view returns (uint);
    function getImmatureBalance() external view returns (uint);
    function create(string memory _title, uint _payAmount, uint _payTimes, uint _startPayTime, uint _endPayTime, string memory _description) external payable returns (uint);
    function vote(uint _id, uint _voteResult) external;
    function changeTitle(uint _id, string memory _title) external;
    function changePayAmount(uint _id, uint _payAmount) external;
    function changePayTimes(uint _id, uint _payTimes) external;
    function changeStartPayTime(uint _id, uint _startPayTime) external;
    function changeEndPayTime(uint _id, uint _endPayTime) external;
    function changeDescription(uint _id, string memory _description) external;

    function getInfo(uint _id) external view returns (ProposalInfo memory);

    function getVoterNum(uint _id) external view returns (uint);
    function getVoteInfo(uint _id, uint _start, uint _count) external view returns (VoteInfo[] memory);

    function getNum() external view returns (uint);
    function getAll(uint _start, uint _count) external view returns (uint[] memory);

    function getMineNum(address _creator) external view returns (uint);
    function getMines(address _creator, uint _start, uint _count) external view returns (uint[] memory);

    function exist(uint _id) external view returns (bool);
}