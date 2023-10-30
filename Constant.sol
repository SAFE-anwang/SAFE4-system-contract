// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Constant {
    // contract address
    address internal constant PROPERTY_ADDR = 0x0000000000000000000000000000000000001000;
    address internal constant PROPERTY_ADMIN_ADDR = 0x0000000000000000000000000000000000001001;
    address internal constant PROPERTY_PROXY_ADDR= 0x0000000000000000000000000000000000001002;

    address internal constant ACCOUNT_MANAGER_ADDR = 0x0000000000000000000000000000000000001010;
    address internal constant ACCOUNT_MANAGER_ADMIN_ADDR = 0x0000000000000000000000000000000000001011;
    address internal constant ACCOUNT_MANAGER_PROXY_ADDR= 0x0000000000000000000000000000000000001012;

    address internal constant MASTERNODE_ADDR = 0x0000000000000000000000000000000000001020;
    address internal constant MASTERNODE_ADMIN_ADDR = 0x0000000000000000000000000000000000001021;
    address internal constant MASTERNODE_PROXY_ADDR= 0x0000000000000000000000000000000000001022;

    address internal constant SUPERNODE_ADDR = 0x0000000000000000000000000000000000001030;
    address internal constant SUPERNODE_ADMIN_ADDR = 0x0000000000000000000000000000000000001031;
    address internal constant SUPERNODE_PROXY_ADDR= 0x0000000000000000000000000000000000001032;

    address internal constant SNVOTE_ADDR = 0x0000000000000000000000000000000000001040;
    address internal constant SNVOTE_ADMIN_ADDR = 0x0000000000000000000000000000000000001041;
    address internal constant SNVOTE_PROXY_ADDR= 0x0000000000000000000000000000000000001042;

    address internal constant MASTERNODE_STATE_ADDR = 0x0000000000000000000000000000000000001050;
    address internal constant MASTERNODE_STATE_ADMIN_ADDR = 0x0000000000000000000000000000000000001051;
    address internal constant MASTERNODE_STATE_PROXY_ADDR= 0x0000000000000000000000000000000000001052;

    address internal constant SUPERNODE_STATE_ADDR = 0x0000000000000000000000000000000000001060;
    address internal constant SUPERNODE_STATE_ADMIN_ADDR = 0x0000000000000000000000000000000000001061;
    address internal constant SUPERNODE_STATE_PROXY_ADDR= 0x0000000000000000000000000000000000001062;

    address internal constant PROPOSAL_ADDR = 0x0000000000000000000000000000000000001070;
    address internal constant PROPOSAL_ADMIN_ADDR = 0x0000000000000000000000000000000000001071;
    address internal constant PROPOSAL_PROXY_ADDR = 0x0000000000000000000000000000000000001072;

    address internal constant SYSTEM_REWARD_ADDR = 0x0000000000000000000000000000000000001080;
    address internal constant SYSTEM_REWARD_ADMIN_ADDR = 0x0000000000000000000000000000000000001081;
    address internal constant SYSTEM_REWARD_PROXY_ADDR = 0x0000000000000000000000000000000000001082;

    address internal constant SAFE3_ADDR = 0x0000000000000000000000000000000000001090;
    address internal constant SAFE3_ADMIN_ADDR = 0x0000000000000000000000000000000000001091;
    address internal constant SAFE3_PROXY_ADDR = 0x0000000000000000000000000000000000001092;

    address internal constant MULTICALL_ADDR = 0x0000000000000000000000000000000000001100;
    address internal constant MULTICALL_ADMIN_ADDR = 0x0000000000000000000000000000000000001101;
    address internal constant MULTICALL_PROXY_ADDR = 0x0000000000000000000000000000000000001102;

    // constant
    uint internal constant COIN = 1000000000000000000;
   
    uint internal constant DAYS_IN_MONTH = 30;
    uint internal constant SECONDS_IN_DAY = 86400;

    // for property
    uint internal constant MAX_PROPERTY_NAME_LEN = 64;
    uint internal constant MAX_PROPERTY_DESCRIPTION_LEN = 256;
    uint internal constant MAX_PROPERTY_REASON_LEN = 512;

    // for vote
    uint internal constant VOTE_AGREE = 1;
    uint internal constant VOTE_REJECT = 1;
    uint internal constant VOTE_ABSTAIN = 1;

    // node state
    uint internal constant NODE_STATE_INIT = 0;
    uint internal constant NODE_STATE_START = 1;
    uint internal constant NODE_STATE_STOP = 2;

    // for node
    uint internal constant MIN_NODE_ENODE_LEN = 150;
    uint internal constant MAX_NODE_DESCRIPTION_LEN = 2048;
    uint internal constant MAX_INCENTIVE = 100;

    // for masternode
    uint internal constant MAX_MN_CREATOR_INCENTIVE = 50;

    // for supernode
    uint internal constant MAX_SN_NAME_LEN = 64;
    uint internal constant MAX_SN_CREATOR_INCENTIVE = 10;
    uint internal constant MIN_SN_PARTNER_INCENTIVE = 40;
    uint internal constant MAX_SN_PARTNER_INCENTIVE = 50;
    uint internal constant MIN_SN_VOTER_INCENTIVE = 40;
    uint internal constant MAX_SN_VOTER_INCENTIVE = 50;

    // for proposal
    uint internal constant MAX_PP_TITLE_LEN = 256;
    uint internal constant MAX_PP_PAY_TIMES = 100;
    uint internal constant MAX_PP_DESCRIPTIO_LEN = 2048;

    // for reward
    uint internal constant REWARD_SN = 1;
    uint internal constant REWARD_MN = 2;
    uint internal constant REWARD_CREATOR = 1;
    uint internal constant REWARD_PARTNER = 2;
    uint internal constant REWARD_VOTER = 3;
}