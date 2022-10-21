// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint private counter;

    constructor() {
        counter = 1;
    }

    function getCounter() internal returns (uint) {
        return counter++;
    }
}