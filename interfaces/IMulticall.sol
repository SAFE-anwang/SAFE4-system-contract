// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IMulticall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) external returns (uint256 blockNumber, bytes[] memory returnData);

    function getEthBalance(address addr) external view returns (uint256 balance);

    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

    function getLastBlockHash() external view returns (bytes32 blockHash);

    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

    function getCurrentBlockCoinbase() external view returns (address coinbase);
}