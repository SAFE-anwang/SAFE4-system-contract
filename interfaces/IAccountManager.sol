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
    }

    struct RecordUseInfo {
        address specialAddr; // created target address(mn or sn)
        uint freezeHeight; // freeze height for create target address
        uint unfreezeHeight; // unfreeze height after create target address
        address votedAddr; // voted target address
        uint voteHeight; // vote height for vote target address
        uint releaseHeight; // release height after vote
    }

    function deposit(address _to, uint _lockDay) external payable returns (uint);
    function deposit2(address _to, uint _lockSecond) external payable returns (uint);
    function withdraw() external returns (uint);
    function withdrawByID(uint[] memory _ids) external returns(uint);
    function transfer(address _to, uint _amount, uint _lockDay) external returns (uint);
    function reward(address[] memory _addrs, uint[] memory _amounts) external payable;
    function moveID0(address _addr) external returns (uint);
    function fromSafe3(address _addr, uint _amount, uint _lockDay, uint _remainLockHeight) external returns (uint);
    function setRecordFreeze(uint _id, address _addr, address _target, uint _day) external;
    function setRecordVote(uint _id, address _addr, address _target, uint _day) external;
    function addLockDay(uint _id, uint _day) external;
    function getTotalAmount(address _addr) external view returns (uint, uint[] memory); 
    function getAvailableAmount(address _addr) external view returns (uint, uint[] memory);
    function getLockAmount(address _addr) external view returns (uint, uint[] memory);
    function getFreezeAmount(address _addr) external view returns (uint, uint[] memory);
    function getRecords(address _addr) external view returns (AccountRecord[] memory);
    function getRecordByID(uint _id) external view returns (AccountRecord memory);
    function getRecordUseInfo(uint _id) external view returns (RecordUseInfo memory);
}