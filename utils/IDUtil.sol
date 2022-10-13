// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IDUtil {
    uint counter;

    constructor() {
        counter = 1;
    }

    function getId() public returns (uint) {
        return counter++;
    }
}