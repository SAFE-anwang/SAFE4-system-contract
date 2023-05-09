// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INode.sol";

interface ISuperMasterNode is INode {
    struct SuperMasterNodeInfo {
        uint id; // supermasternode id
        string name; // supermasternode name
        address addr; // supermasternode address
        address creator; // creator address
        uint amount; // total amount
        string enode; // supermasternode enode, contain node id & node ip & node port
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

    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function appendRegister(address _addr, uint _lockDay) external payable;
    function reward(address _addr) external payable;
    function getTop() external view returns (SuperMasterNodeInfo[] memory);
    function getNum() external view returns (uint);
}