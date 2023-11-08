// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeState {
    struct StateEntry {
        address caller;
        uint state;
    }

    function upload(uint[] memory _ids, uint[] memory _states) external;
    function get(uint _id) external view returns (StateEntry[] memory);
}