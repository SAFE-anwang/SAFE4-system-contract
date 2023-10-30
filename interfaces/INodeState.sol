// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeState {
    struct StateEntry {
        address caller;
        uint state;
    }

    struct StateInfo {
        address addr;
        uint id;
        uint state;
    }

    function uploadState(uint[] memory _ids, uint[] memory _states) external;
    function getAllState() external view returns (StateInfo[] memory);
    function getEntries(uint _id) external view returns (StateEntry[] memory);
}