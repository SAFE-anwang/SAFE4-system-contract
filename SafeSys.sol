// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeProperty.sol";
import "./masternode/MasterNode.sol";
import "./supermasternode/SuperMasterNode.sol";
import "./supermasternode/SMNVote.sol";
import "./utils/BytesUtil.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SafeSys is Initializable, OwnableUpgradeable {
    using BytesUtil for bytes;

    SafeProperty internal property;
    AccountManager internal am;
    SMNVote internal smnVote;
    MasterNode internal mn;
    SuperMasterNode internal smn;

    constructor() {
        property = new SafeProperty();
        am = new AccountManager(property);
        mn = new MasterNode(property, am);
        smn = new SuperMasterNode(property, am);
        smnVote = new SMNVote();
        initialize();
    }

    /**************************************** upgradeable ****************************************/
    function initialize() internal initializer {
        __Ownable_init();
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    /**************************************** account manager ****************************************/
    function deposit() public payable returns (bytes20) {
        return am.deposit(msg.sender, msg.value, 0);
    }

    // self-lock with specified locked height
    function lock(uint _lockDay) public payable returns (bytes20) {
        return am.deposit(msg.sender, msg.value, _lockDay);
    }

    // withdraw all
    function withdraw() public {
        uint ret = am.withdraw(msg.sender);
        if(ret == 0) {
            return;
        }
        removeVote4SMN(); // adjust supermasternode vote
    }

    // withdraw specify records
    function withdraw(bytes20[] memory recordIDs) public {
        uint ret = am.withdraw(msg.sender, recordIDs);
        if(ret == 0) {
            return;
        }
        removeVote4SMN(recordIDs);
    }

    // transfer
    function transfer(address _to, uint _amount) public returns (bytes20) {
        return am.transfer(msg.sender, _to, _amount);
    }

    // transfer with lock
    function transferLock(address _to, uint _amount, uint _lockDay) public returns (bytes20) {
        return am.transferLock(msg.sender, _to, _amount, _lockDay);
    }

    // get total amount
    function getTotalAmount() public view returns (uint, bytes20[] memory) {
        return am.getTotalAmount(msg.sender);
    }

    // get unlocked amount
    function getAvailableAmount() public view returns (uint, bytes20[] memory) {
        return am.getAvailableAmount(msg.sender);
    }

    // get locked amount
    function getLockAmount() public view returns (uint, bytes20[] memory) {
        return am.getLockAmount(msg.sender);
    }

    // get all records
    function getAccountRecords() public view returns(AccountRecord.Data[] memory) {
        return am.getAccountRecords(msg.sender);
    }

    /**************************************** masternode ****************************************/
    function registeMN(uint _lockDay, address _mnAddr, string memory _ip, string memory _pubkey, string memory _description) public payable {
        mn.registe(_lockDay, _mnAddr, _ip, _pubkey, _description);
    }

    function unionRegisteMN(uint _lockDay, address _mnAddr, string memory _ip, string memory _pubkey, string memory _description) public payable {
        mn.unionRegiste(_lockDay, _mnAddr, _ip, _pubkey, _description);
    }

    function appendRegisteMN(uint _lockDay, address _mnAddr) public payable {
        mn.appendRegiste(_lockDay, _mnAddr);
    }

    function appendRegisteMN(bytes20 _lockID, address _mnAddr) public payable {
        mn.appendRegiste(_lockID, _mnAddr);
    }

    /**************************************** supermasternode ****************************************/

    /**************************************** supermasternode vote ****************************************/
    function vote4SMN(address _smnAddr) public virtual {
        // require(isSuperMasterNode(_to), "target is not a supermasternode");
        //_smnVote.vote(_to);
    }

    function removeVote4SMN() public {
        //_smnVote.removeVote();
    }

    function approvalVote4SMN(address _proxyAddr) public {
        //require(isMasterNode(_to), "target is not a masternode");
       // _smnVote.approval(_to);
    }

    function removeApprovalVote4SMN() public {
       // _smnVote.approval(address(0));
    }
}