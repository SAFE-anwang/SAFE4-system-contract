// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccountManager {
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

    function deposit(address _to, uint _lockDay) external payable returns (bytes20);
    function withdraw() external returns (uint);
    function withdraw(bytes20[] memory _recordIDs) external returns(uint);
    function transfer(address _to, uint _amount, uint _lockDay) external returns (bytes20);
    function reward(address _to) external payable returns (bytes20);
    function setBindDay(bytes20 _recordID, uint _bindDay) external;
    function getTotalAmount() external view returns (uint, bytes20[] memory);
    function getAvailableAmount() external view returns (uint, bytes20[] memory);
    function getLockAmount() external view returns (uint, bytes20[] memory);
    function getBindAmount() external view returns (uint, bytes20[] memory);
    function getRecords() external view returns (AccountRecord[] memory);
    function getRecordByID(bytes20 _recordID) external view returns (AccountRecord memory);
}