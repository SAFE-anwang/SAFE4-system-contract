// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PropertyInfo {
    string name;
    uint value;
    string description;
    uint createHeight;
    uint updateHeight;
}

struct UnconfirmedPropertyInfo {
    string name;
    uint value;
    address applicant;
    address[] voters;
    uint[] voteResults;
    string reason;
    uint applyHeight;
}