// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AccountRecord {
    bytes20 id;
    address addr;
    uint amount;
    uint lockDay;
    uint startHeight; // start height
    uint unlockHeight; // unlocked height
    BindInfo bindInfo; // for voting or regist
    uint createHeight;
    uint updateHeight;
}

struct BindInfo {
    uint bindHeight;
    uint unbindHeight;
}

uint8 constant UNKNOW_TYPE = 0;
uint8 constant DEPOSIT_TYPE = 1;
uint8 constant DEPOSIT_LOCK_TYPE = 2;
uint8 constant WITHDRAW_TYPE = 3;
uint8 constant TRANSFER_IN_TYPE = 4;
uint8 constant TRANSFER_IN_LOCK_TYPE = 5;
uint8 constant TRANSFER_OUT_TYPE = 6;
uint8 constant MN_REWARD_TYPE = 7;
uint8 constant SMN_REWARD_TYPE = 8;