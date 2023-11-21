// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./Constant.sol";
import "./interfaces/IProperty.sol";
import "./interfaces/IAccountManager.sol";
import "./interfaces/IMasterNode.sol";
import "./interfaces/ISuperNode.sol";
import "./interfaces/ISNVote.sol";
import "./interfaces/INodeState.sol";
import "./interfaces/IProposal.sol";
import "./interfaces/ISystemReward.sol";
import "./interfaces/ISafe3.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract System is Initializable, OwnableUpgradeable, Constant {
    function initialize() public initializer {
        __Ownable_init();
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    modifier onlySN {
        require(isFormalSN(msg.sender), "No formal supernode");
        _;
    }

    modifier onlyAccountManagerContract {
        require(msg.sender == ACCOUNT_MANAGER_PROXY_ADDR, "No account manager contract");
        _;
    }

    modifier onlyMnOrSnContract {
        require(msg.sender == MASTERNODE_PROXY_ADDR || msg.sender == SUPERNODE_PROXY_ADDR, "No masternode and supernode contract");
        _;
    }

    modifier onlySnOrSNVoteContract {
        require(msg.sender == SUPERNODE_PROXY_ADDR || msg.sender == SNVOTE_PROXY_ADDR, "No supernode and snvote contract");
        _;
    }

    modifier onlySNVoteContract {
        require(msg.sender == SNVOTE_PROXY_ADDR, "No snvote contract");
        _;
    }

    modifier onlyMasterNodeStateContract {
        require(msg.sender == MASTERNODE_STATE_PROXY_ADDR, "No masternode-state contract");
        _;
    }

    modifier onlySuperNodeStateContract {
        require(msg.sender == SUPERNODE_STATE_PROXY_ADDR, "No supernode-state contract");
        _;
    }

    modifier onlySafe3Contract {
        require(msg.sender == SAFE3_PROXY_ADDR, "No SAFE3 contract");
        _;
    }

    modifier onlySystemRewardContract {
        require(msg.sender == SYSTEM_REWARD_PROXY_ADDR, "No system reward contract");
        _;
    }

    modifier onlyProposalContract {
        require(msg.sender == PROPOSAL_PROXY_ADDR, "No proposal contract");
        _;
    }

    function getProperty() internal pure returns (IProperty) {
        return IProperty(PROPERTY_PROXY_ADDR);
    }

    function getAccountManager() internal pure returns (IAccountManager) {
        return IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
    }

    function getMasterNode() internal pure returns (IMasterNode) {
        return IMasterNode(MASTERNODE_PROXY_ADDR);
    }

    function getSuperNode() internal pure returns (ISuperNode) {
        return ISuperNode(SUPERNODE_PROXY_ADDR);
    }

    function getSNVote() internal pure returns (ISNVote) {
        return ISNVote(SNVOTE_PROXY_ADDR);
    }

    function getMasterNodeState() internal pure returns (INodeState) {
        return INodeState(MASTERNODE_STATE_PROXY_ADDR);
    }

    function getSuperNodeState() internal pure returns (INodeState) {
        return INodeState(SUPERNODE_STATE_PROXY_ADDR);
    }

    function getProposal() internal pure returns (IProposal) {
        return IProposal(PROPOSAL_PROXY_ADDR);
    }

    function getPropertyValue(string memory _name) internal view returns (uint) {
        return getProperty().getValue(_name);
    }

    function isMN(address _addr) internal view returns (bool) {
        return getMasterNode().exist(_addr);
    }

    function isValidMN(address _addr) internal view returns (bool) {
        return getMasterNode().isValid(_addr);
    }

    function isSN(address _addr) internal view returns (bool) {
        return getSuperNode().exist(_addr);
    }

    function isValidSN(address _addr) internal view returns (bool) {
        return getSuperNode().isValid(_addr);
    }

    function isFormalSN(address _addr) internal view returns (bool) {
        return getSuperNode().isFormal(_addr);
    }

    function getSNNum() internal view returns (uint) {
        return getSuperNode().getNum();
    }

    function existNodeAddress(address _addr) internal view returns (bool) {
        return getMasterNode().exist(_addr) || getSuperNode().exist(_addr);
    }

    function existNodeEnode(string memory _enode) internal view returns (bool) {
        return getMasterNode().existEnode(_enode) || getSuperNode().existEnode(_enode);
    }
}