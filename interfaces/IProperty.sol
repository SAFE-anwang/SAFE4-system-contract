// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../types/PropertyType.sol";

interface IProperty {
    function add(string memory _name, uint _value, string memory _description) external;
    function applyUpdate(string memory _name, uint _value, string memory _reason) external;
    function vote4Update(string memory _name, uint _result) external;
    function getInfo(string memory _name) external view returns (PropertyInfo memory);
    function getUnconfirmedInfo(string memory _name) external view returns (UnconfirmedPropertyInfo memory);
    function getValue(string memory _name) external view returns (uint);
}