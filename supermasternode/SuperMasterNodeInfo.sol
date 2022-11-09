// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SuperMasterNodeInfo {
    struct IncentivePlan {
        uint creator;
        uint partner;
        uint voter;
    }

    struct MemberInfo {
        bytes20 lockID;
        address addr;
        uint amount;
    }

    struct Data {
        bytes20 id; // supermasternode id
        address creator; // creator address
        uint amount; // total amount
        address addr; // masternode address
        string ip; // masternode ip
        string pubkey; // public key
        string description; // description
        uint state; // node state
        MemberInfo[] founders; // founders
        uint totalVoterAmount; // total voter amount
        MemberInfo[] voters; // voters;
        IncentivePlan incentivePlan; // incentive plan
        uint createTime; // create time
        uint updateTime; // update time
    }

    function create(Data storage _self, bytes20 _id, address _creator, uint _amount, bytes20 _lockID,string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) public {
        _self.id = _id;
        _self.creator = _creator;
        _self.amount = _amount;
        _self.ip = _ip;
        _self.pubkey = _pubkey;
        _self.description = _description;
        _self.state = 0;

        MemberInfo memory info;
        info.lockID = _lockID;
        info.addr = _creator;
        info.amount = _amount;
        _self.founders.push(info);

        IncentivePlan memory plan;
        plan.creator = _creatorIncentive;
        plan.partner = _partnerIncentive;
        plan.voter = _voterIncentive;
        _self.incentivePlan = plan;

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