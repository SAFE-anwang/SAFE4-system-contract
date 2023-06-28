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

    function redeem(bytes memory _pubkey, bytes32 _msgHash, bytes memory _sig) public returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly{
            r := mload(add(_sig ,32))
            s := mload(add(_sig ,64))
            v := byte(0,mload(add(_sig ,96)))
        }
        address signer = ecrecover(_msgHash, v, r, s);

        address safe4Addr = getSafe4Addr(_pubkey);
        if(safe4Addr != signer) {
            return false;
        }

        string memory safe3Addr = getSafe3Addr(_pubkey);
        payable(safe4Addr).transfer(availables[safe3Addr]);
        return true;
    }

    function getSafe3Addr(bytes memory _pubkey) public pure returns (string memory) {
        bytes32 h = sha256(_pubkey);
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

    function getSafe4Addr(bytes memory _pubkey) public pure returns (address addr) {
        bytes32 b = keccak256(_pubkey);
        assembly {
            addr := mload(add(b, 12))
        }
    }
}