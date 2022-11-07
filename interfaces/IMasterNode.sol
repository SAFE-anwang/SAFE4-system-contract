// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafeProperty.sol";
import "../account/AccountManager.sol";
import "../masternode/MasterNodeInfo.sol";

interface IMasterNode {
    event MNRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event MNUnionRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event MNAppendRegiste(address _addr, bytes20 _lockID, string _msg);

    function registe(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description) external payable;
    function unionRegiste(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description) external payable;
    function appendRegiste(uint _lockDay, address _addr) external payable;
    function appendRegiste(bytes20 _lockID, address _addr) external;

    function applyProposal() external returns (bytes20);
    function vote4proposal(bytes20 _proposalID, uint _result) external;

    function changeAddress(address _addr, address _newAddr) external;
    function changeIP(address _addr, string memory _newIP) external;
    function changePubkey(address _addr, string memory _newPubkey) external;
    function changeDescription(address _addr, string memory _newDescription) external;

    function getInfo(address _addr) external view returns (MasterNodeInfo.Data memory);
}