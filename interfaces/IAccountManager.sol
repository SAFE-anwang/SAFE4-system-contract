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
        address frozenAddr; // created target address(mn or sn)
        uint freezeHeight; // freeze height for create target address
        uint unfreezeHeight; // unfreeze height after create target address
        address votedAddr; // voted target address
        uint voteHeight; // vote height for vote target address
        uint releaseHeight; // release height after vote
    }

    function deposit(address _to, uint _lockDay) external payable returns (uint);
    function depositWithSecond(address _to, uint _lockSecond) external payable returns (uint);
    function depositReturnNewID(address _to) external payable returns (uint);

    function withdraw() external returns (uint);
    function withdrawByID(uint[] memory _ids) external returns(uint);

    function transfer(address _to, uint _amount, uint _lockDay) external returns (uint);
    function reward(address[] memory _addrs, uint[] memory _amounts) external payable;
    function moveID0(address _addr) external returns (uint);
    function fromSafe3(address _addr, uint _lockDay, uint _remainLockHeight) external payable returns (uint);

    function setRecordFreezeInfo(uint _id, address _target, uint _day) external;
    function setRecordVoteInfo(uint _id, address _target, uint _day) external;

    function updateRecordFreezeAddr(uint _id, address _target) external;
    function updateRecordVoteAddr(uint _id, address _target) external;

    function addLockDay(uint _id, uint _day) external;

    function getTotalAmount(address _addr) external view returns (uint, uint);
    function getTotalIDs(address _addr, uint _start, uint _count) external view returns (uint[] memory);

    function getAvailableAmount(address _addr) external view returns (uint, uint);
    function getAvailableIDs(address _addr, uint _start, uint _count) external view returns (uint[] memory);

    function getLockedAmount(address _addr) external view returns (uint, uint);
    function getLockedIDs(address _addr, uint _start, uint _count) external view returns (uint[] memory);

    function getUsedAmount(address _addr) external view returns (uint, uint);
    function getUsedIDs(address _addr, uint _start, uint _count) external view returns (uint[] memory);

    function getRecord0(address _addr) external view returns (AccountRecord memory);
    function getRecordByID(uint _id) external view returns (AccountRecord memory);
    function getRecordUseInfo(uint _id) external view returns (RecordUseInfo memory);
}