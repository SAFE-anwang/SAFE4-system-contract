// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccountManager {
    struct AccountRecord {
        uint id;
        address addr;
        uint amount;
        uint lockDay;
        uint startHeight; // start height
        uint unlockHeight; // unlocked height
        uint freezeHeight; // freeze height: for vote or regist
        uint unfreezeHeight; // unfree height
        uint createHeight;
        uint updateHeight;
    }

    function deposit(address _to, uint _lockDay) external payable returns (uint);
    function withdraw() external returns (uint);
    function withdraw(uint[] memory _ids) external returns(uint);
    function transfer(address _to, uint _amount, uint _lockDay) external returns (uint);
    function reward(address _to) external payable returns (uint);
    function freeze(uint _id, uint _day) external;
    function getTotalAmount() external view returns (uint, uint[] memory); 
    function getAvailableAmount() external view returns (uint, uint[] memory);
    function getLockAmount() external view returns (uint, uint[] memory);
    function getFreezeAmount() external view returns (uint, uint[] memory);
    function getRecords() external view returns (AccountRecord[] memory);
    function getRecordByID(uint _id) external view returns (AccountRecord memory);
}