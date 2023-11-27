// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./Constant.sol";
import "./interfaces/IProperty.sol";
import "./interfaces/IAccountManager.sol";
import "./interfaces/IMasterNodeStorage.sol";
import "./interfaces/IMasterNodeLogic.sol";
import "./interfaces/ISuperNodeStorage.sol";
import "./interfaces/ISuperNodeLogic.sol";
import "./interfaces/ISNVote.sol";
import "./interfaces/INodeState.sol";
import "./interfaces/IProposal.sol";
import "./interfaces/ISystemReward.sol";
import "./interfaces/ISafe3.sol";
import "./3rd/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "./3rd/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "./3rd/OpenZeppelin/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "./3rd/OpenZeppelin/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

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

    modifier onlyMasterNodeLogic {
        require(msg.sender == MASTERNODE_LOGIC_PROXY_ADDR, "No masternode logic contract");
        _;
    }

    modifier onlySuperNodeLogic {
        require(msg.sender == SUPERNODE_LOGIC_PROXY_ADDR, "No supernode logic contract");
        _;
    }

    modifier onlyMnOrSnContract {
        require(msg.sender == MASTERNODE_LOGIC_PROXY_ADDR || msg.sender == SUPERNODE_LOGIC_PROXY_ADDR, "No masternode logic and supernode logic contract");
        _;
    }

    modifier onlySnOrSNVoteContract {
        require(msg.sender == SUPERNODE_LOGIC_PROXY_ADDR || msg.sender == SNVOTE_PROXY_ADDR, "No supernode logic and snvote contract");
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

    function getMasterNodeStorage() internal pure returns (IMasterNodeStorage) {
        return IMasterNodeStorage(MASTERNODE_STORAGE_PROXY_ADDR);
    }

    function getMasterNodeLogic() internal pure returns (IMasterNodeLogic) {
        return IMasterNodeLogic(MASTERNODE_LOGIC_PROXY_ADDR);
    }

    function getSuperNodeStorage() internal pure returns (ISuperNodeStorage) {
        return ISuperNodeStorage(SUPERNODE_STORAGE_PROXY_ADDR);
    }

    function getSuperNodeLogic() internal pure returns (ISuperNodeLogic) {
        return ISuperNodeLogic(SUPERNODE_LOGIC_PROXY_ADDR);
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
        return getMasterNodeStorage().exist(_addr);
    }

    function isValidMN(address _addr) internal view returns (bool) {
        return getMasterNodeStorage().isValid(_addr);
    }

    function isSN(address _addr) internal view returns (bool) {
        return getSuperNodeStorage().exist(_addr);
    }

    function isValidSN(address _addr) internal view returns (bool) {
        return getSuperNodeStorage().isValid(_addr);
    }

    function isFormalSN(address _addr) internal view returns (bool) {
        return getSuperNodeStorage().isFormal(_addr);
    }

    function getSNNum() internal view returns (uint) {
        return getSuperNodeStorage().getNum();
    }

    function existNodeAddress(address _addr) internal view returns (bool) {
        return getMasterNodeStorage().exist(_addr) || getSuperNodeStorage().exist(_addr);
    }

    function existNodeEnode(string memory _enode) internal view returns (bool) {
        return getMasterNodeStorage().existEnode(_enode) || getSuperNodeStorage().existEnode(_enode);
    }
}