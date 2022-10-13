// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INode.sol";
import "../masternode/MasterNodeInfo.sol";

interface IMasterNode {
    event MNRegiste(address, uint, uint, string);
    event MNUnionRegiste(address, uint, uint, string);
    event MNAppendRegiste(address, uint, uint, string);

    function registe(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) external payable;
    function unionRegiste(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) external payable;
    function appendRegiste(address _addr, AccountManager _am, uint _day, uint _blockspace) external payable;

    function applyProposal() external returns (uint);
    function vote4proposal(uint _proposalID, uint _result) external;

    function changeAddress(address _addr) external;
    function changeIP(string memory _ip) external;
    function changePubkey(string memory _pubkey) external;
    function changeDescription(string memory _description) external;

    function getApprovalVote4SMN(SMNVote _smnVote) external view returns (SMNVote.ProxyInfo[] memory);
    function getInfo(address _addr) external view returns (MasterNodeInfo.Data memory);
}