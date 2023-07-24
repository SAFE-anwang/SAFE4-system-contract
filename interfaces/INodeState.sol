// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeState {
    struct StateEntry {
        address caller;
        uint8 state;
    }

    struct StateInfo {
        address addr;
        uint id;
        uint8 state;
    }

    function uploadState(uint[] memory _ids, uint8[] memory _states) external;
    function getAllState() external view returns (StateInfo[] memory);
    function getEntries(uint _id) external view returns (StateEntry[] memory);
}