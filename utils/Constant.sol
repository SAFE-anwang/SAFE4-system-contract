// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constant {
    // property contract address
    address internal constant PROPERTY_ADDR = 0x0000000000000000000000000000000000001000;

    // account-manager contract address
    address internal constant ACCOUNT_MANAGER_ADDR= 0x0000000000000000000000000000000000001010;

    // masternode-storage contract address
    address internal constant MASTERNODE_STORAGE_ADDR= 0x0000000000000000000000000000000000001020;

    // masternode-logic contract address
    address internal constant MASTERNODE_LOGIC_ADDR= 0x0000000000000000000000000000000000001025;

    // supernode-storage contract address
    address internal constant SUPERNODE_STORAGE_ADDR= 0x0000000000000000000000000000000000001030;

    // supernode-logic contract address
    address internal constant SUPERNODE_LOGIC_ADDR= 0x0000000000000000000000000000000000001035;

    // supernode-vote contract address
    address internal constant SNVOTE_ADDR= 0x0000000000000000000000000000000000001040;

    // masternode-state contract address
    address internal constant MASTERNODE_STATE_ADDR= 0x0000000000000000000000000000000000001050;

    // supernode-state contract address
    address internal constant SUPERNODE_STATE_ADDR= 0x0000000000000000000000000000000000001060;

    // proposal contract address
    address internal constant PROPOSAL_ADDR = 0x0000000000000000000000000000000000001070;

    // system-reward contract address
    address internal constant SYSTEM_REWARD_ADDR = 0x0000000000000000000000000000000000001080;

    // safe3 contract address
    address internal constant SAFE3_ADDR = 0x0000000000000000000000000000000000001090;

    // multicall contract address
    address internal constant MULTICALL_ADDR = 0x0000000000000000000000000000000000001100;

    // wsafe contract address
    address internal constant WSAFE_ADDR = 0x0000000000000000000000000000000000001101;

    // multisig contract address
    address internal constant MULTISIGWALLET_ADDR = 0x0000000000000000000000000000000000001102;

    // timelock contract address
    address internal constant TIMELOCK_ADDR = 0x0000000000000000000000000000000000001103;

    // constant
    uint internal constant COIN = 1000000000000000000;

    uint internal constant DAYS_IN_MONTH = 30;
    uint internal constant SECONDS_IN_DAY = 86400;

    // for property
    uint internal constant MIN_PROPERTY_NAME_LEN = 4;
    uint internal constant MAX_PROPERTY_NAME_LEN = 64;
    uint internal constant MIN_PROPERTY_DESCRIPTION_LEN = 4;
    uint internal constant MAX_PROPERTY_DESCRIPTION_LEN = 256;
    uint internal constant MIN_PROPERTY_REASON_LEN = 12;
    uint internal constant MAX_PROPERTY_REASON_LEN = 512;

    // for vote
    uint internal constant VOTE_AGREE = 1;
    uint internal constant VOTE_REJECT = 2;
    uint internal constant VOTE_ABSTAIN = 3;

    // node state
    uint internal constant NODE_STATE_INIT = 0;
    uint internal constant NODE_STATE_START = 1;
    uint internal constant NODE_STATE_STOP = 2;

    // for node
    uint internal constant MIN_NODE_ENODE_LEN = 150;
    uint internal constant MAX_NODE_ENODE_LEN = 200;
    uint internal constant MIN_NODE_DESCRIPTION_LEN = 12;
    uint internal constant MAX_NODE_DESCRIPTION_LEN = 2048;
    uint internal constant MAX_INCENTIVE = 100;

    // for masternode
    uint internal constant MAX_MN_CREATOR_INCENTIVE = 50;

    // for supernode
    uint internal constant MIN_SN_NAME_LEN = 2;
    uint internal constant MAX_SN_NAME_LEN = 64;
    uint internal constant MIN_SN_CREATOR_INCENTIVE = 0;
    uint internal constant MAX_SN_CREATOR_INCENTIVE = 10;
    uint internal constant MIN_SN_PARTNER_INCENTIVE = 40;
    uint internal constant MAX_SN_PARTNER_INCENTIVE = 50;
    uint internal constant MIN_SN_VOTER_INCENTIVE = 40;
    uint internal constant MAX_SN_VOTER_INCENTIVE = 50;

    // for proposal
    uint internal constant MIN_PP_TITLE_LEN = 8;
    uint internal constant MAX_PP_TITLE_LEN = 256;
    uint internal constant MAX_PP_PAY_TIMES = 100;
    uint internal constant MIN_PP_DESCRIPTIO_LEN = 8;
    uint internal constant MAX_PP_DESCRIPTIO_LEN = 2048;

    // for reward
    uint internal constant REWARD_SN = 1;
    uint internal constant REWARD_MN = 2;
    uint internal constant REWARD_CREATOR = 1;
    uint internal constant REWARD_PARTNER = 2;
    uint internal constant REWARD_VOTER = 3;
}