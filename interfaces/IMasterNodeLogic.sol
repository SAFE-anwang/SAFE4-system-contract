// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterNodeLogic {
    function register(bool _isUnion, address _addr, uint _lockDay, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive) external payable;
    function appendRegister(address _addr, uint _lockDay) external payable;
    function turnRegister(address _addr, uint _lockID) external;
    function reward(address _addr) external payable;
    function removeMember(address _addr, uint _lockID) external;
    function fromSafe3(address _addr, uint _amount, uint _lockDay, uint _lockID, string memory _enode) external;
    function changeAddress(address _addr, address _newAddr) external;
    function changeEnode(address _addr, string memory _enode) external;
    function changeDescription(address _addr, string memory _description) external;
    function changeIsOfficial(address _addr, bool _flag) external;
    function changeState(uint _id, uint _state) external;
}