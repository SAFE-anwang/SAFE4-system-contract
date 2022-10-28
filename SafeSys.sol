// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeProperty.sol";
import "./masternode/MasterNode.sol";
import "./supermasternode/SuperMasterNode.sol";
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

    event SafeLock(address _addr, uint _amount, uint _lockDay, string _msg);
    event SafeWithdraw(address _addr, uint _amount, string _msg);

    constructor() {
        property = new SafeProperty();
        am = new AccountManager(property);
        mn = new MasterNode(property, am, smnVote);
        smn = new SuperMasterNode(property, am);
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
    // self-lock with specified locked height
    function lock(uint _lockDay) public payable {
        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit SafeLock(msg.sender, msg.value, _lockDay, "lock successfully");
        } else {
            emit SafeLock(msg.sender, msg.value, _lockDay, "lock failed, please check");
        }
    }

    // send locked safe to address by locked height
    function sendLock(address _to, uint _lockDay) public payable {
        bytes20 lockID = am.deposit(_to, msg.value, _lockDay);
        if(lockID == 0) {
            emit SafeLock(_to, msg.value, _lockDay, "send lock successfully");
        } else {
            emit SafeLock(_to, msg.value, _lockDay, "send lock failed, please check");
        }
    }

    // withdraw all
    function withdraw() public {
        uint ret = am.withdraw();
        if(ret == 0) {
            emit SafeWithdraw(msg.sender, 0, "insufficient amount");
        } else {
            emit SafeWithdraw(msg.sender, ret, "withdraw successfully");
        }
    }

    // withdraw specify amount
    function withdraw(uint amount) public {
        uint ret = am.withdraw(amount);
        if(ret < amount) {
            emit SafeWithdraw(msg.sender, ret, "insufficient amount");
        } else {
            emit SafeWithdraw(msg.sender, amount, "withdraw successfully");
        }
    }

    // get total amount
    function getTotalAmount() public view returns (uint, bytes20[] memory) {
        return am.getTotalAmount();
    }

    // get unlocked amount
    function getAvailableAmount() public view returns (uint, bytes20[] memory) {
        return am.getAvailableAmount();
    }

    // get locked amount
    function getLockAmount() public view returns (uint, bytes20[] memory) {
        return am.getLockAmount();
    }

    // get all records
    function getAccountRecords() public view returns(AccountRecord.Data[] memory) {
        return am.getAccountRecords();
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