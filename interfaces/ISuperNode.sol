// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INode.sol";

interface ISuperNode is INode {
    struct SuperNodeInfo {
        uint id; // supernode id
        string name; // supernode name
        address addr; // supernode address
        address creator; // creator address
        uint amount; // total amount
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

    struct VoteInfo {
        MemberInfo[] voters; // all voters
        uint totalAmount; // total voter's amount
        uint totalNum; // total vote number
        uint height; // last vote height
    }

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function changeName(address _addr, string memory _name) external;
    function changeVoteInfo(address _addr, address _voter, uint _recordID, uint _amount, uint _num, uint _type) external;
    function getInfo(address _addr) external view returns (SuperNodeInfo memory);
    function getInfoByID(uint _id) external view returns (SuperNodeInfo memory);
    function getAll() external view returns (SuperNodeInfo[] memory);
    function getTops() external view returns (SuperNodeInfo[] memory);
    function getOfficials() external view returns (SuperNodeInfo[] memory);
    function existName(string memory _name) external view returns (bool);
    function isFormal(address _addr) external view returns (bool);
}