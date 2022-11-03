// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SMNVoteLib {
    struct Entry {
        bytes20 recordID;
        uint num;
        uint height;
    }

    struct Detail {
        address[] dstAddrs;
        uint[] totals;
        Entry[][] entries;
    }

    struct RecordInfo {
        address voterAddr;
        address dstAddr; // smn or proxy address
        uint index; // index of entry
        uint height;
    }
}