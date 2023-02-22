// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ProposalInfo {
    uint id;
    address creator;
    string title;
    uint payAmount;
    uint payTimes;
    uint startPayTime;
    uint endPayTime;
    string description;
    string detail;
    address[] voters;
    uint[] voteResults;
    uint state;
    uint createHeight;
    uint updateHeight;
}