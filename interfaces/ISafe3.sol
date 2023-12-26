// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISafe3 {
    struct Safe3Info {
        string safe3Addr;
        uint amount;
        address safe4Addr;
        uint redeemHeight;
    }

    struct Safe3LockInfo {
        string safe3Addr;
        uint amount;
        string txid;
        uint lockHeight;
        uint unlockHeight;
        uint lockDay;
        uint remainLockHeight;
        bool isMN;
        uint mnState;
        address safe4Addr;
        uint redeemHeight;
    }

    struct SpecialSafe3Info {
        string safe3Addr;
        uint amount;
        address safe4Addr;
        uint applyHeight;
        address[] voters;
        uint[] voteResults;
        uint redeemHeight;
    }

    function redeemAvailable(bytes memory _pubkey, bytes memory _sig) external;
    function redeemLocked(bytes memory _pubkey, bytes memory _sig, string memory _enode) external;

    function applyRedeemSpecial(bytes memory _pubkey, bytes memory _sig) external;
    function vote4Special(string memory _safe3Addr, uint _voteResult) external;

    function getAvailable(string memory _safe3Addr) external view returns (Safe3Info memory);
    function getLocked(string memory _safe3Addr) external view returns (Safe3LockInfo[] memory);
    function getSpecial(string memory _safe3Addr) external view returns (SpecialSafe3Info memory);
    function getAllAvailable() external view returns (Safe3Info[] memory);
    function getAllLocked() external view returns (Safe3LockInfo[] memory);
    function getAllSpecial() external view returns (SpecialSafe3Info[] memory);
}