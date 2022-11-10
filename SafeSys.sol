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
    using SafeMath for uint;
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
        smnVote = new SMNVote(am);
        smn = new SuperMasterNode(property, am, smnVote);
    }

    /**************************************** upgradeable ****************************************/
    function initialize() public initializer {
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

    // get bind amount
    function getBindAMount() public view returns (uint, bytes20[] memory) {
        return am.getBindAmount(msg.sender);
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

    function applyProposal() public view returns (bytes20) {
        return mn.applyProposal();
    }

    function vote4proposal(bytes20 _proposalID, uint _result) public {
        mn.vote4proposal(_proposalID, _result);
    }

    function changeMNAddress(address _newAddr) public {
        mn.changeAddress(msg.sender, _newAddr);
    }

    function changeMNIP(string memory _newIP) public {
        mn.changeIP(msg.sender, _newIP);
    }

    function changeMNPubkey(string memory _newPubkey) public {
        mn.changePubkey(msg.sender, _newPubkey);
    }

    function changeMNDescription(string memory _newDescription) public {
        mn.changeDescription(msg.sender, _newDescription);
    }

    function getMNInfo(address _mnAddr) public view returns (MasterNodeInfo.Data memory) {
        return mn.getInfo(_mnAddr);
    }

    /**************************************** supermasternode ****************************************/
    function registeSMN(uint _lockDay, address _smnAddr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable {
        smn.registe(_lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
    }

    function unionRegisteSMN(uint _lockDay, address _smnAddr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public payable {
        smn.unionRegiste(_lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive);
    }

    function appendRegisteSMN(uint _lockDay, address _smnAddr) public payable {
        smn.appendRegiste(_lockDay, _smnAddr);
    }

    function appendRegisteSMN(bytes20 _lockID, address _smnAddr) public payable {
        smn.appendRegiste(_lockID, _smnAddr);
    }

    function verifySMN(address _smnAddr) public onlyOwner {
        smn.verify(_smnAddr);
    }

    function applyUpdateProperty(string memory _name, bytes memory _value, string memory _reason) public {
        smn.applyUpdateProperty(property, _name, _value, _reason);
    }

    function vote4updateProperty(string memory _name, uint _result) public {
        smn.vote4UpdateProperty(property, _name, _result);
    }

    function uploadMasterNodeState(uint[] memory _ids, uint8[] memory _states) public {
        smn.uploadMasterNodeState(_ids, _states);
    }

    function uploadSuperMasterNodeState(bytes20[] memory _ids, uint8[] memory _states) public {
        smn.uploadSuperMasterNodeState(_ids, _states);
    }

    function changeSMNAddress(address _newAddr) public {
        smn.changeAddress(msg.sender, _newAddr);
    }

    function changeSMNIP(string memory _newIP) public {
        smn.changeIP(msg.sender, _newIP);
    }

    function changeSMNPubkey(string memory _newPubkey) public {
        smn.changePubkey(msg.sender, _newPubkey);
    }

    function changeSMNDescription(string memory _newDescription) public {
        smn.changeDescription(msg.sender, _newDescription);
    }

    function getSMNInfo(address _smnAddr) public view returns (SuperMasterNodeInfo.Data memory) {
        return smn.getInfo(_smnAddr);
    }

    function getTopSMN() public view returns (SuperMasterNodeInfo.Data[] memory) {
        return smn.getTop();
    }

    /**************************************** supermasternode vote ****************************************/
    function vote4SMN(address _smnAddr, bytes20 _recordID) public {
        require(!isSuperMasterNode(msg.sender), "voter can't be a supermasternode");
        require(isSuperMasterNode(_smnAddr), "target is not a supermasternode");
        AccountRecord.Data memory record = am.getRecordByID(msg.sender, _recordID);
        uint num = 0;
        if(isMasterNode(msg.sender)) {
            num = 2 * record.amount;
        } else if(record.unlockHeight != 0) {
            num = 15 * record.amount / 10;
        } else {
            num = record.amount;
        }
        smnVote.vote(msg.sender, _smnAddr, _recordID, num);
    }

    function removeVote4SMN() public {
        smnVote.removeVote(msg.sender);
    }

    function removeVote4SMN(bytes20[] memory _recordIDs) public {
        smnVote.removeVote(msg.sender, _recordIDs);
    }

    function approvalVote4SMN(address _proxyAddr, bytes20 _recordID) public {
        require(isMasterNode(_proxyAddr), "proxy address is not a masternode");
        AccountRecord.Data memory record = am.getRecordByID(msg.sender, _recordID);
        uint num = 0;
        if(isMasterNode(msg.sender)) {
            num = 2 * record.amount;
        } else if(record.unlockHeight != 0) {
            num = 15 * record.amount / 10;
        } else {
            num = record.amount;
        }
        smnVote.approval(msg.sender, _proxyAddr, _recordID, num);
    }

    function removeAllApprovalVote4SMN() public {
        smnVote.removeApproval(msg.sender);
    }

    function removeApprovalVote4SMN(bytes20[] memory _recordIDs) public {
        smnVote.removeApproval(msg.sender, _recordIDs);
    }

    function getApprovalVote4SMN() public view returns (address[] memory) {
        return smnVote.getApprovals(msg.sender);
    }

    /**************************************** common ****************************************/
    function reward(address _smnAddr, uint _smnAmount, address _mnAddr, uint _mnAmount) public {
        smn.reward(_smnAddr, _smnAmount);
        mn.reward(_mnAddr, _mnAmount);
    }

    /**************************************** internal ****************************************/
    function isMasterNode(address _addr) internal view returns (bool) {
        return mn.exist(_addr);
    }

    function isSuperMasterNode(address _addr) internal view returns (bool) {
        return smn.isConfirmed(_addr);
    }
}