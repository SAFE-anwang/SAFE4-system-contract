// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemReward {
    function reward(address _snAddr, uint _snAmount, address _mnAddr, uint _mnAmount, address _ppAddr, uint _ppAmount) external payable;
}