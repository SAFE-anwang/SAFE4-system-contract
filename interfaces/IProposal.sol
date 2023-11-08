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
        address[] voters;
        uint[] voteResults;
        uint state;
        uint createHeight;
        uint updateHeight;
    }

    function reward() external payable;
    function getBalance() external view returns (uint);
    function create(string memory _title, uint _payAmount, uint _payTimes, uint _startPayTime, uint _endPayTime, string memory _description) external payable returns (uint);
    function vote(uint _id, uint _voteResult) external;
    function changeTitle(uint _id, string memory _title) external;
    function changePayAmount(uint _id, uint _payAmount) external;
    function changePayTimes(uint _id, uint _payTimes) external;
    function changeStartPayTime(uint _id, uint _startPayTime) external;
    function changeEndPayTime(uint _id, uint _endPayTime) external;
    function changeDescription(uint _id, string memory _description) external;
    function getInfo(uint _id) external view returns (ProposalInfo memory);
    function getAll() external view returns (ProposalInfo[] memory);
    function getMines() external view returns (ProposalInfo[] memory);
    function exist(uint _id) external view returns (bool);
}