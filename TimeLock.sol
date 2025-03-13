// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./MultisigWallet.sol";
import "./utils/Constant.sol";

contract TimeLock {
    event Schedule(uint txid, address target, uint value, bytes data, uint timestamp);
    event Execute(uint txid, address target, uint value, bytes data, uint timestamp);
    
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
        uint value;
        bytes data;
        uint timestamp;
        bool executed;
    }

    uint minDelay;
    uint transactionCount;
    mapping(uint => Transaction) transactions;

    constructor(uint _minDelay) {
        minDelay = _minDelay;
    }

    function schedule(
        address target,
        uint value,
        bytes calldata data,
        uint timestamp
    ) public onlyMultiSigContract {
        require(timestamp >= block.timestamp + minDelay, "Timestamp too early");

        uint txid = transactionCount;
        transactions[txid] = Transaction({
            target: target,
            value: value,
            data: data,
            timestamp: timestamp,
            executed: false
        });
        transactionCount += 1;

        emit Schedule(txid, target, value, data, timestamp);
    }

    function execute(
        uint txid
    ) public payable onlyMultiSigOWner {
        Transaction storage transaction = transactions[txid];
        require(transaction.target != address(0), "non-existent transaction");
        require(block.timestamp >= transaction.timestamp, "Transaction not ready");
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;

        (bool success, ) = transaction.target.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed");

        emit Execute(txid, transaction.target, transaction.value, transaction.data, transaction.timestamp);
    }

    function getMinDelay()
        public
        view
        returns (uint)
    {
        return minDelay;
    }

    function getTransactionCount()
        public
        view
        returns (uint)
    {
        return transactionCount;
    }

    function getTransaction(uint txid)
        public
        view
        returns (
            address target,
            uint value,
            bytes memory data,
            uint timestamp,
            bool executed
        )
    {
        Transaction storage transaction = transactions[txid];
        return (
            transaction.target,
            transaction.value,
            transaction.data,
            transaction.timestamp,
            transaction.executed
        );
    }
}