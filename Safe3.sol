// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "utils/Base58.sol";

contract Safe3 {
    struct LockInfo {
        uint amount;
        uint lockHeight;
        uint unlockHeight;
        uint lockDay;
        string txid;
    }
    
    mapping(string => uint) availables;
    mapping(string => LockInfo[]) locks;

    // function redeemo(string memory safe3Addr, string memory pubkey) public {
    // }

    function getBtcAddr(string memory _pubkey) public pure returns (string memory) {
        bytes memory b = hex2bytes(_pubkey);
        bytes32 h = sha256(b);
        bytes20 r = ripemd160(abi.encodePacked(h));
        bytes memory t = new bytes(21);
        t[0] = 0x4c;
        for(uint i = 0; i < 20; i++) {
            t[i + 1] = r[i];
        }
        bytes32 h1 = sha256(t);
        bytes32 h2 = sha256(abi.encodePacked(h1));
        bytes memory t2 = new bytes(25);
        for(uint i = 0; i < 21; i++) {
            t2[i] = t[i];
        }
        for(uint i = 0; i < 4; i++) {
            t2[i + 21] = h2[i];
        }
        string memory addr = string(Base58.encode(t2));
        return addr;
    }

    function hex2bytes(string memory _data) internal pure returns (bytes memory) {
        uint8 _ascii_0 = 48;
        uint8 _ascii_A = 65;
        uint8 _ascii_a = 97;

        bytes memory a = bytes(_data);
        uint8[] memory b = new uint8[](a.length);

        for(uint i = 0; i < a.length; i++) {
            uint8 _a = uint8(a[i]);
            if(_a >= _ascii_a) {
                b[i] = _a - _ascii_a + 10;
            } else if(_a >= _ascii_A) {
                b[i] = _a - _ascii_A + 10;
            } else {
                b[i] = _a - _ascii_0;
            }
        }

        bytes memory ret = new bytes(b.length / 2);
        for(uint i = 0; i < b.length; i += 2) {
            ret[i / 2] = bytes1(b[i] * 16 + b[i + 1]);
        }
        return ret;
    }
}