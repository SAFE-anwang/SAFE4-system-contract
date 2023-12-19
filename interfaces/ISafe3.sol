// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISafe3 {
    struct Safe3Info {
        string addr;
        uint amount;
        uint redeemHeight;
    }

    struct Safe3LockInfo {
        string addr;
        uint amount;
        uint lockHeight;
        uint unlockHeight;
        string txid;
        bool isMN;
        uint mnState;
        uint redeemHeight;
    }

    function redeemAvailable(bytes memory _pubkey, bytes memory _sig) external;
    function redeemLocked(bytes memory _pubkey, bytes memory _sig, string memory _enode) external;

    function getAvailable(string memory _safe3Addr) external view returns (Safe3Info memory);
    function getLocked(string memory _safe3Addr) external view returns (Safe3LockInfo[] memory);
    function getAllAvailable() external view returns (Safe3Info[] memory);
    function getAllLocked() external view returns (Safe3LockInfo[] memory);
}