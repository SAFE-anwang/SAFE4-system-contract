// SPDX-License-Identifier: MIT
// masternode information

pragma solidity ^0.8.0;

library SuperMasterNodeInfo {
    struct Data {
        uint id; // supermasternode id
        address creator; // createor address
        uint[] lockID; // lock id list
        uint amount; // total locked amount
        address addr; // masternode address
        string ip; // masternode ip
        string pubkey; // public key
        string description; // description
        uint state; // node state
        uint createTime; // create time
        uint updateTime; // update time
    }

    function create(Data memory _self, uint _id, uint _lockID, address _addr, uint _amount, string memory _ip, string memory _pubkey, string memory _description) public view {
        _self.id = _id;
        _self.creator = _addr;
        _self.lockID = new uint[](1);
        _self.lockID[0] = _lockID;
        _self.addr = _addr;
        _self.amount = _amount;
        _self.ip = _ip;
        _self.pubkey = _pubkey;
        _self.description = _description;
        _self.state = 0;
        _self.createTime = block.timestamp;
        _self.updateTime = 0;
    }

    function appendLock(Data storage _self, uint _lockID, uint _amount) public {
        uint[] memory temp = new uint[](_self.lockID.length + 1);
        uint i = 0;
        for(i = 0; i < _self.lockID.length; i++) {
            temp[i] = _self.lockID[i];
        }
        temp[i] = _lockID; 
        _self.lockID = temp;
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
}