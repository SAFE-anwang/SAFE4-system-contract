// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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