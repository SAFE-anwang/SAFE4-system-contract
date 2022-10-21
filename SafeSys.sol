// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeProperty.sol";
import "supermasternode/SuperMasterNode.sol";
import "./utils/BytesUtil.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SafeSys is Initializable, OwnableUpgradeable, SafeProperty {
    /**************************************** system property ****************************************/

    constructor() {
        initProperty();
    }

    function initProperty() public {
        addProperty("block_space", BytesUtil.toBytes(30), "block space");
        addProperty("mn_lock_amount", BytesUtil.toBytes(2000), "min masternode lock amount");
        addProperty("mn_lock_month", BytesUtil.toBytes(6), "min masternode lock month");
        addProperty("smn_lock_amount", BytesUtil.toBytes(20000), "min supermasternode lock amount");
        addProperty("smn_lock_month", BytesUtil.toBytes(24), "min supermasternode lock month");
        addProperty("smn_unverify_height", BytesUtil.toBytes(1051200), "supermasternode don't need verify util blockchain height more than it");
    }

    /**************************************** upgradeable ****************************************/
    function initialize() public initializer {
        __Ownable_init();
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }
}