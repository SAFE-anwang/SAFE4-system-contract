// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EllipticCurve.sol";

library Secp256k1 {
    uint256 internal constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 internal constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 internal constant AA = 0;
    uint256 internal constant BB = 7;
    uint256 internal constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    function getCompressed(bytes memory _pubkey) internal pure returns (bytes memory) {
        require(_pubkey.length == 65 && (_pubkey[0] == 0x04 || _pubkey[0] == 0x06 || _pubkey[0] == 0x07), "invalid pubkey");
        bytes memory ret = new bytes(33);
        for(uint i = 1; i <= 32; i++) {
            ret[i] = _pubkey[i];
        }
        if(uint8(_pubkey[64]) % 2 == 0) {
            ret[0] = 0x02;
        } else {
            ret[0] = 0x03;
        }
        return ret;
    }

    function getDecompressed(bytes memory _pubkey) internal pure returns (bytes memory) {
        require(_pubkey.length == 33 && (_pubkey[0] == 0x02 || _pubkey[0] == 0x03), "invalid pubkey");
        bytes memory ret = new bytes(65);
        uint8 prefix = uint8(_pubkey[0]);
        bytes32 x;
        for(uint i = 0; i < 32; i++) {
            x |= bytes32(_pubkey[1 + i] & 0xFF) >> (i * 8);
        }
        bytes32 y = bytes32(EllipticCurve.deriveY(prefix, uint(x), AA, BB, PP));
        ret[0] = 0x04;
        for(uint i = 0; i < 32; i++) {
            ret[i + 1] = _pubkey[i + 1];
        }
        for(uint i = 0; i < 32; i++) {
            ret[i + 33] = y[i];
        }
        return ret;
    }
}