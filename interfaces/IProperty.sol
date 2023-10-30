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

    function add(string memory _name, uint _value, string memory _description) external;
    function applyUpdate(string memory _name, uint _value, string memory _reason) external;
    function vote4Update(string memory _name, uint _result) external;
    function getInfo(string memory _name) external view returns (PropertyInfo memory);
    function getUnconfirmedInfo(string memory _name) external view returns (UnconfirmedPropertyInfo memory);
    function getValue(string memory _name) external view returns (uint);
    function getAll() external view returns (PropertyInfo[] memory);
    function getAllUnconfirmed() external view returns (UnconfirmedPropertyInfo[] memory);
    function exist(string memory _name) external view returns (bool);
    function existUnconfirmed(string memory _name) external view returns (bool);
}