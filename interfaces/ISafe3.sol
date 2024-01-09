// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISafe3 {
    struct AvailableSafe3Info {
        string safe3Addr;
        uint amount;
        address safe4Addr;
        uint redeemHeight;
    }

    struct LockedSafe3Info {
        string safe3Addr;
        uint amount;
        string txid;
        uint lockHeight;
        uint unlockHeight;
        uint remainLockHeight;
        uint lockDay;
        bool isMN;
        address safe4Addr;
        uint redeemHeight;
    }

    struct SpecialSafe3Info {
        string safe3Addr;
        uint amount;
        uint applyHeight;
        address[] voters;
        uint[] voteResults;
        address safe4Addr;
        uint redeemHeight;
    }

    function redeemAvailable(bytes memory _pubkey, bytes memory _sig) external;
    function redeemLocked(bytes memory _pubkey, bytes memory _sig) external;
    function redeemMasterNode(bytes memory _pubkey, bytes memory _sig, string memory _enode) external;

    function applyRedeemSpecial(bytes memory _pubkey, bytes memory _sig) external;
    function vote4Special(string memory _safe3Addr, uint _voteResult) external;

    function getAvailableNum() external view returns (uint);
    function getAvailables(uint _start, uint _count) external view returns (AvailableSafe3Info[] memory);
    function getAvailable(string memory _safe3Addr) external view returns (AvailableSafe3Info memory);

    function getAllLockedNum() external view returns (uint);
    function getLockeds(uint _start, uint _count) external view returns (LockedSafe3Info[] memory);

    function getLockedNum(string memory _safe3Addr) external view returns (uint);
    function getLocked(string memory _safe3Addr, uint _start, uint _count) external view returns (LockedSafe3Info[] memory);

    function getAllSpecial() external view returns (SpecialSafe3Info[] memory);
    function getSpecial(string memory _safe3Addr) external view returns (SpecialSafe3Info memory);
}