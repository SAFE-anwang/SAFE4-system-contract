// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INode.sol";
import "../supermasternode/SuperMasterNodeInfo.sol";

interface ISuperMasterNode {
    event SMNRegiste(address, uint, uint, string);
    event SMNUnionRegiste(address, uint, uint, string);
    event SMNAppendRegiste(address, uint, uint, string);

    function registe(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) external payable;
    function unionRegiste(AccountManager _am, uint _day, uint _blockspace, string memory _ip, string memory _pubkey, string memory _description) external payable;
    function appendRegiste(address _addr, AccountManager _am, uint _day, uint _blockspace) external payable;

    function reward(uint _amount) external;
    function modifyProperty(string memory _name) external;
    function uploadMasterNodeState(uint8[] memory _ids, uint8[] memory _states) external;
    function uploadState(uint8[] memory _ids, uint8[] memory _states) external;

    function changeAddress(address _addr) external;
    function changeIP(string memory _ip) external;
    function changePubkey(string memory _pubkey) external;
    function changeDescription(string memory _description) external;

    function getInfo(address _addr) external view returns (SuperMasterNodeInfo.Data memory);
}