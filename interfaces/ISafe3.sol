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

    function redeemAvailables(bytes[] memory _pubkeys, bytes[] memory _sigs) external;
    function redeemLockeds(bytes[] memory _pubkeys, bytes[] memory _sigs) external;
    function redeemMasterNodes(bytes[] memory _pubkeys, bytes[] memory _sigs, string[] memory _enodes) external;

    function applyRedeemSpecial(bytes memory _pubkey, bytes memory _sig) external;
    function vote4Special(string memory _safe3Addr, uint _voteResult) external;

    function getAvailable(string memory _safe3Addr) external view returns (AvailableSafe3Info memory);
    function getLocked(string memory _safe3Addr) external view returns (LockedSafe3Info[] memory);
    function getSpecial(string memory _safe3Addr) external view returns (SpecialSafe3Info memory);
    function getAllAvailable() external view returns (AvailableSafe3Info[] memory);
    function getAllLocked() external view returns (LockedSafe3Info[] memory);
    function getAllSpecial() external view returns (SpecialSafe3Info[] memory);
}