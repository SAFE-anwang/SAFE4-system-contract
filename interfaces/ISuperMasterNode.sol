// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISuperMasterNode {
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

    struct SuperMasterNodeInfo {
        uint id; // supermasternode id
        string name; // supermasternode name
        address addr; // supermasternode address
        address creator; // creator address
        uint amount; // total amount
        string ip; // supermasternode ip
        string pubkey; // supermasternode public key
        string description; // supermasternode description
        uint state; // supermasternode state
        MemberInfo[] founders; // supermasternode founders
        IncentivePlan incentivePlan; // incentive plan
        MemberInfo[] voters; // voters;
        uint totalVoteNum; // supermasternode total vote number
        uint totalVoterAmount; // supermasternode total voter amount
        uint createHeight; // supermasternode create height
        uint updateHeight; // supermasternode update height
    }

    function register(address _addr, bool _isUnion, uint _lockDay, string memory _name, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function appendRegister(address _addr, uint _lockDay) external payable;
    function reward(address _addr) external payable;
    function changeAddress(address _addr, address _newAddr) external;
    function changeIP(address _addr, string memory _newIP) external;
    function changePubkey(address _addr, string memory _newPubkey) external;
    function changeDescription(address _addr, string memory _newDescription) external;
    function getInfo(address _addr) external view returns (SuperMasterNodeInfo memory);
    function getTop() external view returns (SuperMasterNodeInfo[] memory);
    function getNum() external view returns (uint);
    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existIP(string memory _ip) external view returns (bool);
    function existPubkey(string memory _pubkey) external view returns (bool);
    function existLockID(address _addr, bytes20 _lokcID) external view returns (bool);
}