// SPDX-License-Identifier: MIT
// masternode information

pragma solidity ^0.8.0;

library MasterNodeInfo {
    struct MemberInfo {
        bytes20 lockID;
        address addr;
        uint amount;
    }

    struct Data {
        uint id; // masternode id
        address creator; // createor address
        uint amount; // total locked amount
        address addr; // masternode address
        string ip; // masternode ip
        string pubkey; // public key
        string description; // description
        uint state; // node state
        MemberInfo[] founders; // founders
        uint createTime; // create time
        uint updateTime; // update time
    }

    function create(Data storage _self, uint _id, bytes20 _lockID, address _addr, string memory _ip, string memory _pubkey, string memory _description) public {
        _self.id = _id;
        _self.creator = msg.sender;
        _self.addr = _addr;
        _self.amount = msg.value;
        _self.ip = _ip;
        _self.pubkey = _pubkey;
        _self.description = _description;
        _self.state = 0;

        MemberInfo memory info;
        info.lockID = _lockID;
        info.addr = msg.sender;
        info.amount = msg.value;
        _self.founders.push(info);

        _self.createTime = block.timestamp;
        _self.updateTime = 0;
    }

    function appendLock(Data storage _self, bytes20 _lockID, address _addr, uint _amount) public {
        require(_self.amount != 0, "need create first");
        require(!existLockID(_self, _lockID), "existent lock id");

        MemberInfo memory info;
        info.lockID = _lockID;
        info.addr = _addr;
        info.amount = _amount;
        _self.founders.push(info);

        _self.amount += _amount;
        _self.updateTime = block.timestamp;
    }

    function setAddress(Data storage _self, address _addr) public {
        _self.addr = _addr;
        _self.updateTime = block.timestamp;
    }

    function setIP(Data storage _self, string memory _ip) public {
        _self.ip = _ip;
        _self.updateTime = block.timestamp;
    }

    function setPubkey(Data storage _self, string memory _pubkey) public {
        _self.pubkey = _pubkey;
        _self.updateTime = block.timestamp;
    }

    function setDescription(Data storage _self, string memory _description) public {
        _self.description = _description;
        _self.updateTime = block.timestamp;
    }

    function existLockID(Data memory _self, bytes20 _lokcID) internal pure returns (bool) {
        for(uint i = 0; i < _self.founders.length; i++) {
            if(_self.founders[i].lockID == _lokcID) {
                return true;
            }
        }
        return false;
    }
}