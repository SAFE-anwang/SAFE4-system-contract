// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProperty {
    struct PropertyInfo {
        string name;
        uint value;
        string description;
        uint createHeight;
        uint updateHeight;
    }

    struct UnconfirmedPropertyInfo {
        string name;
        uint value;
        address applicant;
        address[] voters;
        uint[] voteResults;
        string reason;
        uint applyHeight;
    }

    event PropertyAdd(string _name, uint _value);
    event PropertyUpdateApply(string _name, uint _newValue, uint _oldValue);
    event PropertyUpdateReject(string _name, uint _newValue);
    event PropertyUpdateAgree(string _name, uint _newValue);
    event PropertyUpdateVote(string _name, uint _newValue, address _voter, uint _voteResult);

    function add(string memory _name, uint _value, string memory _description) external;
    function applyUpdate(string memory _name, uint _value, string memory _reason) external;
    function vote4Update(string memory _name, uint _result) external;
    function getInfo(string memory _name) external view returns (PropertyInfo memory);
    function getUnconfirmedInfo(string memory _name) external view returns (UnconfirmedPropertyInfo memory);
    function getValue(string memory _name) external view returns (uint);
    function getAllConfirmed() external view returns (PropertyInfo[] memory);
    function getAllUnConfirmed() external view returns (UnconfirmedPropertyInfo[] memory);
}