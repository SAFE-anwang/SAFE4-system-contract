// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeState {
    function uploadState(uint[] memory _ids, uint8[] memory _states) external;
}