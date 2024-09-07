// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterNodeStorage {
    struct MemberInfo {
        uint lockID; // lock id
        address addr; // member address
        uint amount; // lock amount
        uint height; // add height
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
        uint lastRewardHeight; // last reward height
        uint createHeight; // masternode create height
        uint updateHeight; // masternode update height
    }

    function create(address _addr, address _creator, uint _lockID, uint _amount, string memory _enode, string memory _description, IncentivePlan memory _incentivePlan) external;
    function append(address _addr, uint _lockID, uint _amount) external;
    function updateAddress(address _addr, address _newAddr) external;
    function updateEnode(address _addr, string memory _enode) external;
    function updateDescription(address _addr, string memory _description) external;
    function updateIsOfficial(address _addr, bool _flag) external;
    function updateState(address _addr, uint _state) external;
    function removeMember(address _addr, uint _index) external;
    function dissolve(address _addr) external;
    function updateLastRewardHeight(address _addr, uint _height) external;

    function getInfo(address _addr) external view returns (MasterNodeInfo memory);
    function getInfoByID(uint _id) external view returns (MasterNodeInfo memory);
    function getNext() external view returns (address);

    function getNum() external view returns (uint);
    function getAll(uint _start, uint _count) external view returns (address[] memory);

    function getAddrNum4Creator(address _creator) external view returns (uint);
    function getAddrs4Creator(address _creator, uint _start, uint _count) external view returns (address[] memory);

    function getOfficials() external view returns (address[] memory);

    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existEnode(string memory _enode) external view returns (bool);
    function existLockID(address _addr, uint _lockID) external view returns (bool);
    function existFounder(address _founder) external view returns (bool);

    function isValid(address _addr) external view returns (bool);

    function existNodeAddress(address _addr) external view returns (bool);
    function existNodeEnode(string memory _enode) external view returns (bool);
    function existNodeFounder(address _founder) external view returns (bool);
}