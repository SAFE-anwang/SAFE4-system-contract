// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./interfaces/IProperty.sol";
import "./interfaces/IMasterNode.sol";
import "./interfaces/ISuperNode.sol";

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

    address internal constant SUPERNODE_ADDR = 0x0000000000000000000000000000000000001030;
    address internal constant SUPERNODE_ADMIN_ADDR = 0x0000000000000000000000000000000000001031;
    address internal constant SUPERNODE_PROXY_ADDR= 0x0000000000000000000000000000000000001032;

    address internal constant SNVOTE_ADDR = 0x0000000000000000000000000000000000001040;
    address internal constant SNVOTE_ADMIN_ADDR = 0x0000000000000000000000000000000000001041;
    address internal constant SNVOTE_PROXY_ADDR= 0x0000000000000000000000000000000000001042;

    address internal constant MASTERNODE_STATE_ADDR = 0x0000000000000000000000000000000000001050;
    address internal constant MASTERNODE_STATE_ADMIN_ADDR = 0x0000000000000000000000000000000000001051;
    address internal constant MASTERNODE_STATE_PROXY_ADDR= 0x0000000000000000000000000000000000001052;

    address internal constant SUPERNODE_STATE_ADDR = 0x0000000000000000000000000000000000001060;
    address internal constant SUPERNODE_STATE_ADMIN_ADDR = 0x0000000000000000000000000000000000001061;
    address internal constant SUPERNODE_STATE_PROXY_ADDR= 0x0000000000000000000000000000000000001062;

    address internal constant PROPOSAL_ADDR = 0x0000000000000000000000000000000000001070;
    address internal constant PROPOSAL_ADMIN_ADDR = 0x0000000000000000000000000000000000001071;
    address internal constant PROPOSAL_PROXY_ADDR = 0x0000000000000000000000000000000000001072;

    address internal constant SYSTEM_REWARD_ADDR = 0x0000000000000000000000000000000000001080;
    address internal constant SYSTEM_REWARD_ADMIN_ADDR = 0x0000000000000000000000000000000000001081;
    address internal constant SYSTEM_REWARD_PROXY_ADDR = 0x0000000000000000000000000000000000001082;

    address internal constant SAFE3_ADDR = 0x0000000000000000000000000000000000001090;
    address internal constant SAFE3_ADMIN_ADDR = 0x0000000000000000000000000000000000001091;
    address internal constant SAFE3_PROXY_ADDR = 0x0000000000000000000000000000000000001092;

    address internal constant MULTICALL_ADDR = 0x0000000000000000000000000000000000001100;
    address internal constant MULTICALL_ADMIN_ADDR = 0x0000000000000000000000000000000000001101;
    address internal constant MULTICALL_PROXY_ADDR = 0x0000000000000000000000000000000000001102;

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

    function isSN(address _addr) internal view returns (bool) {
        ISuperNode sn = ISuperNode(SUPERNODE_PROXY_ADDR);
        return sn.exist(_addr);
    }

    modifier onlyMN {
        require(isMN(msg.sender), "No masternode");
        _;
    }

    modifier onlySN {
        require(isSN(msg.sender), "No supernode");
        _;
    }

    modifier onlyMnOrSnContract {
        require(msg.sender == MASTERNODE_PROXY_ADDR || msg.sender == SUPERNODE_PROXY_ADDR, "No masternode and supernode contract");
        _;
    }

    modifier onlySafe3Contract {
        require(msg.sender == SAFE3_PROXY_ADDR, "No SAFE3 contract");
        _;
    }

    function getSNNum() internal view returns (uint) {
        ISuperNode sn = ISuperNode(SUPERNODE_PROXY_ADDR);
        return sn.getNum();
    }

    function existNodeAddress(address _addr) internal view returns (bool) {
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        ISuperNode sn = ISuperNode(SUPERNODE_PROXY_ADDR);
        return mn.exist(_addr) || sn.exist(_addr);
    }

    function existNodeIP(string memory _ip) internal view returns (bool) {
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        ISuperNode sn = ISuperNode(SUPERNODE_PROXY_ADDR);
        return mn.existIP(_ip) || sn.existIP(_ip);
    }
}