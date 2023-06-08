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
        address freezeTarget; // freeze target address
    }

    event SafeDeposit(address _addr, uint _amount, uint _lockDay, uint _id);
    event SafeWithdraw(address _addr, uint _amount, uint[] _ids);
    event SafeTransfer(address _from, address _to, uint _amount, uint _lockDay, uint _id);
    event SafeFreeze(uint _id, address _target, uint _day);
    event SafeUnfreeze(uint _id);
    event SafeAddLockDay(uint _id, uint _oldLockDay, uint _newLockDay);

    function deposit(address _to, uint _lockDay) external payable returns (uint);
    function withdraw() external returns (uint);
    function withdraw(uint[] memory _ids) external returns(uint);
    function transfer(address _to, uint _amount, uint _lockDay) external returns (uint);
    function reward(address _to) external payable returns (uint);
    function freeze(uint _id, address _target, uint _day) external;
    function addLockDay(uint _id, uint _day) external;
    function getTotalAmount(address _addr) external view returns (uint, uint[] memory); 
    function getAvailableAmount(address _addr) external view returns (uint, uint[] memory);
    function getLockAmount(address _addr) external view returns (uint, uint[] memory);
    function getFreezeAmount(address _addr) external view returns (uint, uint[] memory);
    function getRecords(address _addr) external view returns (AccountRecord[] memory);
    function getRecordByID(uint _id) external view returns (AccountRecord memory);
}