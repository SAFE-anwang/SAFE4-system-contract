// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SMNVoteDetail {
    address[] smnAddrs; // supermasternodes
    uint[] totalAmounts; // total voter amounts
    uint[] totalNums; // total vote numbers
    SMNVoteEntry[][] entries;
}

struct SMNVoteEntry {
    bytes20 recordID; // record id
    uint amount; // voter amount
    uint num; // vote number
    uint height; // block height
}

struct SMNVoteRecord {
    address voterAddr; // voter address
    address smnAddr; // smn address
    uint index; // index of vote entry
    uint height; // block height
}

struct SMNVoteProxyDetail {
    address[] proxyAddrs; // supermasternodes
    uint[] totalAmounts; // total voter amounts
    uint[] totalNums; // total vote numbers
    SMNVoteProxyEntry[][] entries;
}

struct SMNVoteProxyEntry {
    bytes20 recordID; // record id
    uint amount; // voter amount
    uint num; // vote number
    uint height; // block height
}

struct SMNVoteProxyRecord {
    address voterAddr; // voter address
    address proxyAddr; // smn address
    uint index; // index of proxy entry
    uint height; // block height
}