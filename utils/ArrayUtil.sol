// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ArrayUtil {
    function find(address[] memory _arr, address _addr) internal pure returns (int) {
        for(uint i = 0; i < _arr.length; i++) {
            if(_arr[i] == _addr) {
                return int(i);
            }
        }
        return -1;
    }
}