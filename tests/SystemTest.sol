// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IProperty.sol";
import "../interfaces/IAccountManager.sol";
import "../interfaces/IMasterNode.sol";
import "../interfaces/ISuperNode.sol";
import "../interfaces/ISNVote.sol";
import "../interfaces/INodeState.sol";
import "../interfaces/IProposal.sol";
import "../interfaces/ISystemReward.sol";
import "../interfaces/ISafe3.sol";
import "hardhat/console.sol";

contract SystemTest {
    IProperty property;
    IAccountManager accountManager;
    IMasterNode masterNode;
    ISuperNode superNode;
    ISNVote snVote;
    INodeState masterNodeState;
    INodeState superNodeState;
    IProposal proposal;
    ISystemReward systemReward;
    ISafe3 safe3;

    function setProperty(address _property) public {
        property = IProperty(_property);
    }

    function getProperty() public view returns (IProperty) {
        return property;
    }

    function setAccountManager(address _accountManager) public {
        accountManager = IAccountManager(_accountManager);
    }

    function getAccountManager() public view returns(IAccountManager) {
        return accountManager;
    }

    function setMasterNode(address _masterNode) public {
        masterNode = IMasterNode(_masterNode);
    }

    function getMasterNode() public view returns(IMasterNode) {
        return masterNode;
    }

    function setSuperNode(address _superNode) public {
        superNode = ISuperNode(_superNode);
    }

    function getSuperNode() public view returns(ISuperNode) {
        return superNode;
    }

    function setSNVote(address _snVote) public {
        snVote = ISNVote(_snVote);
    }

    function getSNVote() public view returns(ISNVote) {
        return snVote;
    }

    function setMasterNodeState(address _masterNodeState) public {
        masterNodeState = INodeState(_masterNodeState);
    }

    function getMasterNodeState() public view returns(INodeState) {
        return masterNodeState;
    }

    function setSuperNodeState(address _superNodeState) public {
        superNodeState = INodeState(_superNodeState);
    }

    function getSuperNodeState() public view returns(INodeState) {
        return superNodeState;
    }

    function setProposal(address _proposal) public {
        proposal = IProposal(_proposal);
    }

    function getProposal() public view returns(IProposal) {
        return proposal;
    }

    function setSystemReward(address _systemReward) public {
        systemReward = ISystemReward(_systemReward);
    }

    function getSystemReward() public view returns(ISystemReward) {
        return systemReward;
    }

    function setSafe3(address _safe3) public {
        safe3 = ISafe3(_safe3);
    }

    function getSafe3() public view returns(ISafe3) {
        return safe3;
    }

    modifier onlyMN {
        require(isMN(msg.sender), "No masternode");
        _;
    }

    modifier onlySN {
        require(isSN(msg.sender), "No supernode");
        _;
    }

    modifier onlyAccountManagerContract {
        require(msg.sender == address(accountManager), "No account manager contract");
        _;
    }

    modifier onlyMnOrSnContract {
        require(msg.sender == address(masterNode) || msg.sender == address(superNode), "No masternode and supernode contract");
        _;
    }

    modifier onlySNVoteContract {
        require(msg.sender == address(snVote), "No supernode vote contract");
        _;
    }

    modifier onlyMasterNodeStateContract {
        require(msg.sender == address (masterNodeState), "No masternode state contract");
        _;
    }

    modifier onlySuperNodeStateContract {
        require(msg.sender == address (superNodeState), "No supernode state contract");
        _;
    }

    modifier onlySafe3Contract {
         require(msg.sender == address(safe3), "No SAFE3 contract");
         _;
    }

    modifier onlySystemRewardContract {
        require(msg.sender == address(systemReward), "No system reward contract");
        _;
    }

    function getPropertyValue(string memory _name) public view returns (uint) {
        return getProperty().getValue(_name);
    }

    function isMN(address _addr) public view returns (bool) {
        return masterNode.exist(_addr);
    }

    function isSN(address _addr) public view returns (bool) {
        return superNode.exist(_addr);
    }

    function getSNNum() public view returns (uint) {
        return superNode.getNum();
    }

    function existNodeAddress(address _addr) public view returns (bool) {
        return masterNode.exist(_addr) || superNode.exist(_addr);
    }

    function existNodeIP(string memory _ip) public view returns (bool) {
        return masterNode.existIP(_ip) || superNode.existIP(_ip);
    }
}