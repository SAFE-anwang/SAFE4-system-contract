// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../types/ProposalType.sol";

interface IProposal {
    function create(string memory _title, uint _payAmount, uint _payTimes, uint _startPayTime, uint _endPayTime, string memory _description, string memory _detail) external payable returns (uint);
    function vote(uint _id, uint _voteResult) external;
    function changTitile(uint _id, string memory _title) external;
    function changePayAmount(uint _id, uint _payAmount) external;
    function changePayTimes(uint _id, uint _payTimes) external;
    function changeStartPayTimes(uint _id, uint _startPayTime) external;
    function changeEndPayTime(uint _id, uint _endPayTime) external;
    function changeDescription(uint _id, string memory _description) external;
    function changeDetail(uint _id, string memory _detail) external;
    function getInfo(uint _id) external view returns (ProposalInfo memory);
    function getAll() external view returns (ProposalInfo[] memory);
    function getMine() external view returns (ProposalInfo[] memory);
}