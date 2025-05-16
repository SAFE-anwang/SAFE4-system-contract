// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISuperNodeLogic {
    function register(bool _isUnion, address _addr, uint _lockDay, string memory _name, string memory _enode, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function appendRegister(address _addr, uint _lockDay) external payable;
    function turnRegister(address _addr, uint _lockID) external;
    function reward(address _addr) external payable;
    function removeMember(address _addr, uint _lockID) external;
    function changeAddress(address _addr, address _newAddr) external;
    function changeName(address _addr, string memory _name) external;
    function changeNameByID(uint _id, string memory _name) external;
    function changeEnode(address _addr, string memory _enode) external;
    function changeEnodeByID(uint _id, string memory _enode) external;
    function changeDescription(address _addr, string memory _description) external;
    function changeDescriptionByID(uint _id, string memory _description) external;
    function changeIsOfficial(address _addr, bool _flag) external;
    function changeState(uint _id, uint _state) external;
}