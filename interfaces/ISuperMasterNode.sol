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
        string pubkey; // supernode public key
        string description; // supernode description
        uint state; // supernode state
        MemberInfo[] founders; // supernode founders
        IncentivePlan incentivePlan; // incentive plan
        MemberInfo[] voters; // voters;
        uint totalVoteNum; // supernode total vote number
        uint totalVoterAmount; // supernode total voter amount
        uint createHeight; // supernode create height
        uint updateHeight; // supernode update height
    }

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function appendRegister(address _addr, uint _lockDay) external payable;
    function reward(address _addr) external payable;
    function getTop() external view returns (SuperNodeInfo[] memory);
    function getNum() external view returns (uint);
}