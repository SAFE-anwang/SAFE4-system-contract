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
        string ip; // supernode ip
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

    event SNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _reocrdID);
    event SNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _recordID);
    event SNStateUpdate(address _addr, uint8 _newState, uint8 _oldState);

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function changeVoteInfo(address _addr, address _voter, uint _recordID, uint _amount, uint _num, uint _type) external;
    function getInfo(address _addr) external view returns (SuperNodeInfo memory);
    function getInfo(uint _id) external view returns (SuperNodeInfo memory);
    function getAll() external view returns (SuperNodeInfo[] memory);
    function getTop() external view returns (SuperNodeInfo[] memory);
    function getOfficials() external view returns (SuperNodeInfo[] memory);
}