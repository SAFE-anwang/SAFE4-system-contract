// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./interfaces/IProperty.sol";
import "./interfaces/IMasterNode.sol";
import "./interfaces/ISuperMasterNode.sol";

contract System is Initializable, OwnableUpgradeable{
    address internal constant PROPERTY_ADDR = 0x0000000000000000000000000000000000001000;
    address internal constant PROPERTY_ADMIN_ADDR = 0x0000000000000000000000000000000000001001;
    address internal constant PROPERTY_PROXY_ADDR= 0x0000000000000000000000000000000000001002;

    address internal constant ACCOUNT_MANAGER_ADDR = 0x0000000000000000000000000000000000001010;
    address internal constant ACCOUNT_MANAGER_ADMIN_ADDR = 0x0000000000000000000000000000000000001011;
    address internal constant ACCOUNT_MANAGER_PROXY_ADDR= 0x0000000000000000000000000000000000001012;

    address internal constant MASTERNODE_ADDR = 0x0000000000000000000000000000000000001020;
    address internal constant MASTERNODE_ADMIN_ADDR = 0x0000000000000000000000000000000000001021;
    address internal constant MASTERNODE_PROXY_ADDR= 0x0000000000000000000000000000000000001022;

    address internal constant SUPERMASTERNODE_ADDR = 0x0000000000000000000000000000000000001030;
    address internal constant SUPERMASTERNODE_ADMIN_ADDR = 0x0000000000000000000000000000000000001031;
    address internal constant SUPERMASTERNODE_PROXY_ADDR= 0x0000000000000000000000000000000000001032;

    address internal constant SMNVOTE_ADDR = 0x0000000000000000000000000000000000001040;
    address internal constant SMNVOTE_ADMIN_ADDR = 0x0000000000000000000000000000000000001041;
    address internal constant SMNVOTE_PROXY_ADDR= 0x0000000000000000000000000000000000001042;

    address internal constant MASTERNODE_STATE_ADDR = 0x0000000000000000000000000000000000001050;
    address internal constant MASTERNODE_STATE_ADMIN_ADDR = 0x0000000000000000000000000000000000001051;
    address internal constant MASTERNODE_STATE_PROXY_ADDR= 0x0000000000000000000000000000000000001052;

    address internal constant SUPERMASTERNODE_STATE_ADDR = 0x0000000000000000000000000000000000001060;
    address internal constant SUPERMASTERNODE_STATE_ADMIN_ADDR = 0x0000000000000000000000000000000000001061;
    address internal constant SUPERMASTERNODE_STATE_PROXY_ADDR= 0x0000000000000000000000000000000000001062;

    function initialize() public initializer {
        __Ownable_init();
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    function getPropertyValue(string memory _name) internal view returns (uint) {
        IProperty p = IProperty(PROPERTY_PROXY_ADDR);
        return p.getValue(_name);
    }

    function isMN(address _addr) internal view returns (bool) {
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        return mn.exist(_addr);
    }

    function isSMN(address _addr) internal view returns (bool) {
        ISuperMasterNode smn = ISuperMasterNode(SUPERMASTERNODE_PROXY_ADDR);
        return smn.exist(_addr);
    }

    modifier onlyMN {
        require(isMN(msg.sender), "No masternode");
        _;
    }

    modifier onlySMN {
        require(isSMN(msg.sender), "No supermasternode");
        _;
    }

    function getSMNNum() internal view returns (uint) {
        ISuperMasterNode smn = ISuperMasterNode(SUPERMASTERNODE_PROXY_ADDR);
        return smn.getNum();
    }

    function existNodeAddress(address _addr) internal view returns (bool) {
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        ISuperMasterNode smn = ISuperMasterNode(SUPERMASTERNODE_PROXY_ADDR);
        return mn.exist(_addr) || smn.exist(_addr);
    }

    function existNodeIP(string memory _ip) internal view returns (bool) {
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        ISuperMasterNode smn = ISuperMasterNode(SUPERMASTERNODE_PROXY_ADDR);
        return mn.existIP(_ip) || smn.existIP(_ip);
    }

    function existNodePubkey(string memory _pubkey) internal view returns (bool) {
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        ISuperMasterNode smn = ISuperMasterNode(SUPERMASTERNODE_PROXY_ADDR);
        return mn.existPubkey(_pubkey) || smn.existPubkey(_pubkey);
    }
}