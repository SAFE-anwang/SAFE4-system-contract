// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterNode {
    struct MemberInfo {
        bytes20 lockID; // lock id
        address addr; // member address
        uint amount; // lock amount
        uint height; // add height
    }

    struct IncentivePlan {
        uint creator; // creator percent [0, 10%]
        uint partner; // partner percent [40%, 50$]
        uint voter; // voter percent [40%, 50%]
    }

    struct MasterNodeInfo {
        uint id; // masternode id
        address addr; // masternode address
        address creator; // createor address
        uint amount; // total locked amount
        string ip; // masternode ip
        string pubkey; // masternode public key
        string description; // masternode description
        uint state; // masternode state
        MemberInfo[] founders; // masternode founders
        IncentivePlan incentivePlan; // incentive plan
        uint createHeight; // masternode create height
        uint updateHeight; // masternode update height
    }

    function register(address _addr, bool _isUnion, uint _lockDay, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive) external payable;
    function appendRegister(address _addr, uint _lockDay) external payable;
    function reward(address _addr) external payable;
    function changeAddress(address _addr, address _newAddr) external;
    function changeIP(address _addr, string memory _newIP) external;
    function changePubkey(address _addr, string memory _newPubkey) external;
    function changeDescription(address _addr, string memory _newDescription) external;
    function getInfo(address _addr) external view returns (MasterNodeInfo memory);
    function getNext() external view returns (address);
    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existIP(string memory _ip) external view returns (bool);
    function existPubkey(string memory _pubkey) external view returns (bool);
    function existLockID(address _addr, bytes20 _lokcID) external view returns (bool);
}