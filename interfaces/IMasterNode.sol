// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INode.sol";

interface IMasterNode is INode {
    struct MasterNodeInfo {
        uint id; // masternode id
        address addr; // masternode address
        address creator; // createor address
        uint amount; // total locked amount
        string enode; // masternode enode, contain node id & node ip & node port
        string ip; // masternode ip
        string description; // masternode description
        bool isOfficial; // official or not
        StateInfo stateInfo; // masternode state information
        MemberInfo[] founders; // masternode founders
        IncentivePlan incentivePlan; // incentive plan
        uint lastRewardHeight; // last reward height
        uint createHeight; // masternode create height
        uint updateHeight; // masternode update height
    }

    event MNRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _lockID);
    event MNAppendRegister(address _addr, address _operator, uint _amount, uint _lockDay, uint _lockID);
    event MNStateUpdate(address _addr, uint8 _newState, uint8 _oldState);

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive) external payable;
    function fromSafe3(address _addr, uint _amount, uint _lockDay, uint _lockID) external;
    function getInfo(address _addr) external view returns (MasterNodeInfo memory);
    function getNext() external view returns (address);
    function getAll() external view returns (MasterNodeInfo[] memory);
    function getOfficials() external view returns (MasterNodeInfo[] memory);
}