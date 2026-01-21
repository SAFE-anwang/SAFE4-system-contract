// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterNodeStorage {
    struct MemberInfo {
        uint lockID; // lock id
        address addr; // member address
        uint amount; // lock amount
        uint unlockHeight; // unlock height
    }

    struct IncentivePlan {
        uint creator; // creator percent [0, 50%]
        uint partner; // partner percent [0%, 50%]
        uint voter; // voter percent: 0%
    }

    struct MasterNodeInfo {
        uint id; // masternode id
        address addr; // masternode address
        address creator; // createor address
        string enode; // masternode enode, contain node id & node ip & node port
        string description; // masternode description
        bool isOfficial; // official or not
        uint state; // masternode state
        MemberInfo[] founders; // masternode founders
        IncentivePlan incentivePlan; // incentive plan
        bool isUnion; // union or not
        uint lastRewardHeight; // last reward height
        uint createHeight; // masternode create height
        uint updateHeight; // masternode update height
    }

    function create(address _addr, bool _isUnion, address _creator, uint _lockID, uint _amount, string memory _enode, string memory _description, IncentivePlan memory _incentivePlan, uint _unlockHeight) external;
    function append(address _addr, uint _lockID, uint _amount, uint _unlockHeight) external;
    function updateAddress(address _addr, address _newAddr) external;
    function updateEnode(address _addr, string memory _enode) external;
    function updateDescription(address _addr, string memory _description) external;
    function updateIsOfficial(address _addr, bool _flag) external;
    function updateState(address _addr, uint _state) external;
    function removeMember(address _addr, uint _index) external;
    function updateLastRewardHeight(address _addr, uint _height) external;
    function updateFounderUnlockHeight(address _addr, uint _lockID, uint _unlockheight) external;

    function getInfo(address _addr) external view returns (MasterNodeInfo memory);
    function getInfoByID(uint _id) external view returns (MasterNodeInfo memory);
    function getIDsByEnode(string memory _enode) external view returns (uint[] memory);
    function getNext() external view returns (address);

    function getNum() external view returns (uint);
    function getAll(uint _start, uint _count) external view returns (address[] memory);

    function getAddrNum4Creator(address _creator) external view returns (uint);
    function getAddrs4Creator(address _creator, uint _start, uint _count) external view returns (address[] memory);
    function getAddrNum4Partner(address _partner) external view returns (uint);
    function getAddrs4Partner(address _partner, uint _start, uint _count) external view returns (address[] memory);

    function getOfficials() external view returns (address[] memory);

    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existEnode(string memory _enode) external view returns (bool);
    function existLockID(address _addr, uint _lockID) external view returns (bool);
    function existFounder(address _founder) external view returns (bool);

    function isValid(address _addr) external view returns (bool);
    function isUnion(address _addr) external view returns (bool);

    function existNodeAddress(address _addr) external view returns (bool);
    function existNodeEnode(string memory _enode) external view returns (bool);
    function existNodeFounder(address _founder) external view returns (bool);

    function isBindEnode(uint _id, string memory _enode) external view returns (bool);
    function isValidEnode(string memory _enode) external view returns (bool);
}