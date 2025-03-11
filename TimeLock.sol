// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./MultisigWallet.sol";
import "./utils/Constant.sol";

contract TimeLock {
    event Schedule(bytes32 txId, address target, uint256 value, bytes data, uint256 timestamp);
    event Execute(bytes32 txId);

    
    modifier onlyMultiSigContract {
        require(msg.sender == Constant.MULTISIGWALLET_ADDR, "No multi-sig-wallet contract");
        _;
    }

    modifier onlyMultiSigOWner {
        require(MultiSigWallet(payable(Constant.MULTISIGWALLET_ADDR)).existOwner(msg.sender), "Caller isn't multi-sig-wallet owner");
        _;
    }

    struct Transaction {
        address target;
        uint256 value;
        bytes data;
        uint256 timestamp;
        bool executed;
    }

    uint256 public minDelay;
    mapping(bytes32 => Transaction) public transactions;

    constructor(uint256 _minDelay) {
        minDelay = _minDelay;
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 timestamp
    ) external onlyMultiSigContract {
        require(timestamp >= block.timestamp + minDelay, "Timestamp too early");

        bytes32 txId = keccak256(abi.encode(target, value, data, timestamp));
        require(transactions[txId].timestamp == 0, "Transaction already scheduled");

        transactions[txId] = Transaction({
            target: target,
            value: value,
            data: data,
            timestamp: timestamp,
            executed: false
        });

        emit Schedule(txId, target, value, data, timestamp);
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 timestamp
    ) external payable onlyMultiSigOWner {
        bytes32 txId = keccak256(abi.encode(target, value, data, timestamp));
        Transaction storage transaction = transactions[txId];

        require(transaction.timestamp != 0, "Transaction does not exist");
        require(block.timestamp >= transaction.timestamp, "Transaction not ready");
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;

        (bool success, ) = transaction.target.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed");

        emit Execute(txId);
    }

    function getTransaction(bytes32 txId)
        external
        view
        returns (
            address target,
            uint256 value,
            bytes memory data,
            uint256 timestamp,
            bool executed
        )
    {
        Transaction storage transaction = transactions[txId];
        return (
            transaction.target,
            transaction.value,
            transaction.data,
            transaction.timestamp,
            transaction.executed
        );
    }
}