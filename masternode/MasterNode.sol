// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../account/AccountManager.sol";
import "../masternode/MasterNodeInfo.sol";
import "../utils/SafeMath.sol";
import "../utils/BytesUtil.sol";

contract MasterNode {
    using SafeMath for uint;
    using BytesUtil for bytes;
    using MasterNodeInfo for MasterNodeInfo.Data;

    uint internal counter; // global masternode id

    mapping(address => MasterNodeInfo.Data) masternodes;
    mapping(uint => address) id2address;

    AccountManager internal am;

    event MNRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event MNUnionRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event MNAppendRegiste(address _addr, bytes20 _lockID, string _msg);

    constructor(AccountManager _am) {
        counter = 1;
        am = _am;
    }

    function registe(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description) public payable {
        require(msg.value >= 1000, "masternode need lock 1000 SAFE at least");
        require(_lockDay >= 180, "masternode need lock 6 month at least");
        require(_addr != address(0), "invalid masternode address");
        require(bytes(_ip).length != 0, "invalid masternode ip");
        require(bytes(_pubkey).length != 0, "invalid masternode pubkey");
        require(bytes(_description).length != 0, "invalid masternode description");
        require(!exist(_addr), "existent masternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit MNRegiste(_addr, _ip, _pubkey, "registe masternode failed: lock failed");
            return;
        }

        uint id = counter++;
        masternodes[_addr].create(id, lockID, _addr, _ip, _pubkey, _description);
        id2address[id] = _addr;
        am.setBindDay(lockID, _lockDay); // creator's lock id can't unbind util unlock it
        emit MNRegiste(_addr, _ip, _pubkey, "registe masternode successfully");
    }

    function unionRegiste(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description) public payable {
        require(msg.value >= 200, "union masternode need lock 200 SAFE at least");
        require(_lockDay >= 365, "union masternode need lock 1 year at least");
        require(_addr != address(0), "invalid supermasternode address");
        require(bytes(_ip).length != 0, "invalid supermasternode ip");
        require(bytes(_pubkey).length != 0, "invalid supermasternode pubkey");
        require(bytes(_description).length != 0, "invalid supermasternode description");
        require(!exist(_addr), "existent masternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit MNUnionRegiste(_addr, _ip, _pubkey, "registe union masternode failed: lock failed");
            return;
        }

        uint id = counter++;
        masternodes[_addr].create(id, lockID, _addr, _ip, _pubkey, _description);
        id2address[id] = _addr;
        am.setBindDay(lockID, _lockDay); // creator's lock id can't unbind util unlock it
        emit MNRegiste(_addr, _ip, _pubkey, "registe union masternode successfully");
    }

    function appendRegiste(uint _lockDay, address _addr) public payable {
        require(msg.value >= 50, "masternode need append lock 50 SAFE at least");
        require(_lockDay >= 180, "masternode need lock 6 month at least");
        require(exist(_addr), "non-existent masternode");

        bytes20 lockID = am.deposit(msg.sender, msg.value, _lockDay);
        if(lockID == 0) {
            emit MNAppendRegiste(_addr, lockID, "append registe union masternode failed: lock failed");
            return;
        }

        masternodes[_addr].appendLock(lockID, msg.sender, msg.value);
        am.setBindDay(lockID, 30); // lock id can't be unbind util 30 days.
        emit MNAppendRegiste(_addr, lockID, "append registe masternode successfully");
    }

    function appendRegiste(bytes20 _lockID, address _addr) public {
        require(exist(_addr), "non-existent masternode");
        AccountRecord.Data memory record = am.getRecordByID(msg.sender, _lockID);
        require(record.bindInfo.bindHeight == 0, "lock id is bind, can't append");
        require(record.addr == msg.sender, "lock address isn't caller");
        require(record.amount >= 50, "lock amout need 50 SAFE at least");
        require(record.lockDay >= 180, "lock day less 6 month");

        masternodes[_addr].appendLock(_lockID, record.addr, record.amount);
        am.setBindDay(_lockID, 30); // lock id can't be unbind util 30 days.
        emit MNAppendRegiste(_addr, _lockID, "append registe masternode successfully");
    }

    function reward(address _addr, uint _amount) public {
        MasterNodeInfo.Data memory info = masternodes[_addr];
        uint total = 0;
        for(uint i = 0; i < info.founders.length; i++) {
            if(total.add(info.founders[i].amount) <= 1000) {
                am.reward(info.founders[i].addr, _amount.mul(info.founders[i].amount).div(1000), 6);
                total = total.add(info.founders[i].amount);
                if(total == 1000) {
                    break;
                }
            } else {
                am.reward(info.founders[i].addr, _amount.mul(1000 - total).div(1000), 6);
                break;
            }
        }
    }

    function applyProposal() public pure returns (bytes20) {
        return 0;
    }

    function vote4proposal(bytes20 _proposalID, uint _result) public {
    }

    function changeAddress(address _addr, address _newAddr) public {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(exist(_addr), "non-existent masternode");
        require(!exist(_newAddr), "new masternode address has exist");
        require(_newAddr != address(0), "invalid address");
        masternodes[_newAddr] = masternodes[_addr];
        masternodes[_newAddr].setAddress(_newAddr);
        delete masternodes[_addr];
        id2address[masternodes[_newAddr].id] = _newAddr;
    }

    function changeIP(address _addr, string memory _newIP) public {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_newIP).length > 0, "invalid ip");
        masternodes[_addr].setIP(_newIP);
    }

    function changePubkey(address _addr, string memory _newPubkey) public {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_newPubkey).length > 0, "invalid pubkey");
        masternodes[_addr].setPubkey(_newPubkey);
    }

    function changeDescription(address _addr, string memory _newDescription) public {
        require(msg.sender == masternodes[_addr].creator, "caller isn't masternode creator");
        require(bytes(_newDescription).length > 0, "invalid description");
        masternodes[_addr].setDescription(_newDescription);
    }

    function getInfo(address _addr) public view returns (MasterNodeInfo.Data memory) {
        require(exist(_addr), "non-existent masternode");
        return masternodes[_addr];
    }

    /************************************************** internal **************************************************/
    function getCounter() internal returns (uint) {
        return counter++;
    }

    function exist(address _addr) public view returns (bool) {
        return masternodes[_addr].createTime != 0;
    }
}