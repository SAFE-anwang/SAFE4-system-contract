// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISuperNodeStorage {
    struct MemberInfo {
        uint lockID; // lock id
        address addr; // member address
        uint amount; // lock amount
        uint height; // add height
    }

    struct IncentivePlan {
        uint creator; // creator percent [0, 10%]
        uint partner; // partner percent [40%, 50$]
        uint voter; // voter percent [40%, 50%]
    }

    struct StateInfo {
        uint state;
        uint height;
    }

    struct VoteInfo {
        MemberInfo[] voters; // all voters
        uint totalAmount; // total voter's amount
        uint totalNum; // total vote number
        uint height; // last vote height
    }

    struct SuperNodeInfo {
        uint id; // supernode id
        string name; // supernode name
        address addr; // supernode address
        address creator; // creator address
        string enode; // supernode enode, contain node id & node ip & node port
        string description; // supernode description
        bool isOfficial; // official or not
        StateInfo stateInfo; // masternode state information
        MemberInfo[] founders; // supernode founders
        IncentivePlan incentivePlan; // incentive plan
        VoteInfo voteInfo; // vote information
        uint lastRewardHeight; // last reward height
        uint createHeight; // supernode create height
        uint updateHeight; // supernode update height
    }

    function create(address _addr, uint _lockID, uint _amount, string memory _name, string memory _enode, string memory _description, IncentivePlan memory _incentivePlan) external;
    function append(address _addr, uint _lockID, uint _amount) external;
    function updateAddress(address _addr, address _newAddr) external;
    function updateName(address _addr, string memory _name) external;
    function updateEnode(address _addr, string memory _enode) external;
    function updateDescription(address _addr, string memory _description) external;
    function updateIsOfficial(address _addr, bool _flag) external;
    function updateState(address _addr, uint _state) external;
    function removeMember(address _addr, uint _index) external;
    function dissolve(address _addr) external;
    function increaseVote(address _addr, address _voter, uint _recordID, uint _amount, uint _num) external;
    function reduceVote(address _addr, address _voter, uint _recordID, uint _amount, uint _num) external;
    function updateLastRewardHeight(address _addr, uint _height) external;

    function getInfo(address _addr) external view returns (SuperNodeInfo memory);
    function getInfoByID(uint _id) external view returns (SuperNodeInfo memory);
    function getAll() external view returns (SuperNodeInfo[] memory);
    function getTops() external view returns (SuperNodeInfo[] memory);
    function getOfficials() external view returns (SuperNodeInfo[] memory);
    function getNum() external view returns (uint);
    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existName(string memory _name) external view returns (bool);
    function existEnode(string memory _enode) external view returns (bool);
    function existLockID(address _addr, uint _lockID) external view returns (bool);
    function isValid(address _addr) external view returns (bool);
    function isFormal(address _addr) external view returns (bool);
}