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

    function batchRedeemAvailable(bytes[] memory _pubkeys, bytes[] memory _sigs) external;
    function batchRedeemLocked(bytes[] memory _pubkeys, bytes[] memory _sigs) external;
    function batchRedeemMasterNode(bytes[] memory _pubkeys, bytes[] memory _sigs, string[] memory _enodes) external;

    function applyRedeemSpecial(bytes memory _pubkey, bytes memory _sig) external;
    function vote4Special(string memory _safe3Addr, uint _voteResult) external;

    function getAllAvailableNum() external view returns (uint);
    function getAvailableInfos(uint _start, uint _count) external view returns (AvailableSafe3Info[] memory);
    function getAvailableInfo(string memory _safe3Addr) external view returns (AvailableSafe3Info memory);

    function getAllLockedNum() external view returns (uint);
    function getLockedAddrNum() external view returns (uint);
    function getLockedAddrs(uint _start, uint _count) external view returns (string[] memory);
    function getLockedNum(string memory _safe3Addr) external view returns (uint);
    function getLockedInfo(string memory _safe3Addr, uint _start, uint _count) external view returns (LockedSafe3Info[] memory);

    function getAllSpecialNum() external view returns (uint);
    function getSpecialInfos(uint _start, uint _count) external view returns (SpecialSafe3Info[] memory);
    function getSpecialInfo(string memory _safe3Addr) external view returns (SpecialSafe3Info memory);

    function existAvailableNeedToRedeem(string memory _safe3Addr) external view returns (bool);
    function existLockedNeedToRedeem(string memory _safe3Addr) external view returns (bool);
    function existMasterNodeNeedToRedeem(string memory _safe3Addr) external view returns (bool);
}