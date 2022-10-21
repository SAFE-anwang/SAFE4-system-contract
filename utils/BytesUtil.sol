// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BytesUtil {
    function toBytes(uint _v) public pure returns (bytes memory bs) {
        bs = new bytes(32);
        assembly {
            mstore(add(bs, 32), _v)
        }
    }

    function toUint(bytes memory bs) public pure returns (uint) {
        uint ret = 0;
        for(uint i = 0; i < bs.length; i++){
            ret = ret + uint8(bs[i])*(2**(8*(bs.length-(i+1))));
        }
        return ret;
    }
}