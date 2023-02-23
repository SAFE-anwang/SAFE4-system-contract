// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SMNVoteDetail {
    address[] dstAddrs; // supermasternodes or proxy
    uint[] totalAmounts; // total voter amounts
    uint[] totalNums; // total vote numbers
    SMNVoteEntry[][] entries;
}

struct SMNVoteEntry {
    bytes20 recordID; // record id
    uint amount; // voter amount
    uint num; // vote number
    uint height; // vote height
}

struct SMNVoteRecord {
    address voterAddr; // voter address
    address dstAddr; // supermasternode or proxy
    uint index; // index of vote entry
    uint height; // block height
}