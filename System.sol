// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./utils/Constant.sol";

contract System is Initializable, OwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
        transferOwnership(Constant.MULTISIGWALLET_ADDR);
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    modifier onlyFormalSN {
        require(isFormalSN(msg.sender), "No formal supernode");
        _;
    }

    modifier onlyAmOrSnContract {
        require(msg.sender == Constant.ACCOUNT_MANAGER_ADDR || msg.sender == Constant.SUPERNODE_LOGIC_ADDR, "No account-manager and supernode-logic contract");
        _;
    }

    modifier onlyMasterNodeLogic {
        require(msg.sender == Constant.MASTERNODE_LOGIC_ADDR, "No masternode-logic contract");
        _;
    }

    modifier onlySuperNodeLogic {
        require(msg.sender == Constant.SUPERNODE_LOGIC_ADDR, "No supernode-logic contract");
        _;
    }

    modifier onlyMnOrSnContract {
        require(msg.sender == Constant.MASTERNODE_LOGIC_ADDR || msg.sender == Constant.SUPERNODE_LOGIC_ADDR, "No masternode-logic and supernode-logic contract");
        _;
    }

    modifier onlySnOrSNVoteContract {
        require(msg.sender == Constant.SUPERNODE_LOGIC_ADDR || msg.sender == Constant.SNVOTE_ADDR, "No supernode-logic and supernode-vote contract");
        _;
    }

    modifier onlyMnSnAmContract {
        require(msg.sender == Constant.MASTERNODE_LOGIC_ADDR || msg.sender == Constant.SUPERNODE_LOGIC_ADDR || msg.sender == Constant.ACCOUNT_MANAGER_ADDR, "No masternode-logic, supernode-logic and account-manager contract");
        _;
    }

    modifier onlySNVoteContract {
        require(msg.sender == Constant.SNVOTE_ADDR, "No supernode-vote contract");
        _;
    }

    modifier onlyMasterNodeStateContract {
        require(msg.sender == Constant.MASTERNODE_STATE_ADDR, "No masternode-state contract");
        _;
    }

    modifier onlySuperNodeStateContract {
        require(msg.sender == Constant.SUPERNODE_STATE_ADDR, "No supernode-state contract");
        _;
    }

    modifier onlySafe3Contract {
        require(msg.sender == Constant.SAFE3_ADDR, "No SAFE3 contract");
        _;
    }

    modifier onlySystemRewardContract {
        require(msg.sender == Constant.SYSTEM_REWARD_ADDR, "No system-reward contract");
        _;
    }

    modifier onlyProposalContract {
        require(msg.sender == Constant.PROPOSAL_ADDR, "No proposal contract");
        _;
    }

    function getAccountManager() internal pure returns (IAccountManager) {
        return IAccountManager(Constant.ACCOUNT_MANAGER_ADDR);
    }

    function getMasterNodeStorage() internal pure returns (IMasterNodeStorage) {
        return IMasterNodeStorage(Constant.MASTERNODE_STORAGE_ADDR);
    }

    function getMasterNodeLogic() internal pure returns (IMasterNodeLogic) {
        return IMasterNodeLogic(Constant.MASTERNODE_LOGIC_ADDR);
    }

    function getSuperNodeStorage() internal pure returns (ISuperNodeStorage) {
        return ISuperNodeStorage(Constant.SUPERNODE_STORAGE_ADDR);
    }

    function getSuperNodeLogic() internal pure returns (ISuperNodeLogic) {
        return ISuperNodeLogic(Constant.SUPERNODE_LOGIC_ADDR);
    }

    function getSNVote() internal pure returns (ISNVote) {
        return ISNVote(Constant.SNVOTE_ADDR);
    }

    function getProposal() internal pure returns (IProposal) {
        return IProposal(Constant.PROPOSAL_ADDR);
    }

    function getPropertyValue(string memory _name) internal view returns (uint) {
        return IProperty(Constant.PROPERTY_ADDR).getValue(_name);
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
        return getSuperNodeStorage().getTops().length;
    }
}