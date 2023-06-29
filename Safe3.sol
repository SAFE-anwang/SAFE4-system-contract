// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISafe3.sol";
import "./interfaces/IAccountManager.sol";
import "./System.sol";
import "utils/Base58.sol";

contract Safe3 is ISafe3, System {
    uint internal constant SPOS_HEIGHT = 1092826;
    uint internal constant SAFE3_END_HEIGHT = 5000000;

    // avaiable safe3
    mapping(string => Safe3Info) availables;
    string[] addrs;
    uint num;

    // locked safe3
    mapping(string => Safe3LockInfo[]) locks;
    string[] lockedAddrs;
    uint lockNum;

    function redeemAvaiable(bytes memory _pubkey, bytes memory _sig) public {
        string memory safe3Addr = getSafe3Addr(_pubkey);
        require(availables[safe3Addr].amount > 0, "non-existent avaiable amount");
        require(availables[safe3Addr].redeemHeight == 0, "has redeemed");

        bytes32 h = sha256(abi.encodePacked(safe3Addr));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(_pubkey, msgHash, _sig), "invalid signature");

        address safe4Addr = getSafe4Addr(_pubkey);
        payable(safe4Addr).transfer(availables[safe3Addr].amount);
        availables[safe3Addr].amount = 0;
        availables[safe3Addr].redeemHeight = block.number + 1;
    }

    function redeemLock(bytes memory _pubkey, bytes memory _sig) public {
        string memory safe3Addr = getSafe3Addr(_pubkey);
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        for(uint i = 0; i < locks[safe3Addr].length; i++) {
            Safe3LockInfo memory info = locks[safe3Addr][i];
            if(info.amount == 0 || info.redeemHeight != 0) {
                continue;
            }

            bytes32 h = sha256(abi.encodePacked(info.txid));
            bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
            if(!verifySig(_pubkey, msgHash, _sig)) {
                return;
            }

            address safe4Addr = getSafe4Addr(_pubkey);
            uint lockDay = 0;
            uint remainLockHeight;
            if(info.unlockHeight <= SAFE3_END_HEIGHT) {
                lockDay = 0;
                remainLockHeight = 0;
            } else {
                if(info.lockHeight < SPOS_HEIGHT) {
                    if(info.unlockHeight <= SPOS_HEIGHT) {
                        lockDay += (info.unlockHeight - info.lockHeight) / 576;
                    } else {
                        lockDay += (SPOS_HEIGHT - info.lockHeight) / 576;
                        lockDay += (info.unlockHeight - SPOS_HEIGHT) / 2880;
                    }
                    if((info.unlockHeight - info.lockHeight) % 30 != 0) {
                        lockDay += 1;
                    }
                } else {
                    lockDay += (info.unlockHeight - info.lockHeight) / 2880 + ((info.unlockHeight - info.lockHeight) % 2880 == 0 ? 0 : 1);
                }
                remainLockHeight = info.unlockHeight - SAFE3_END_HEIGHT;
            }
            uint lockID = am.fromSafe3(safe4Addr, info.amount, lockDay, remainLockHeight);
            if(info.isMN) {
                mn.fromSafe3(safe4Addr, info.amount, lockDay, lockID);
            }
        }
    }

    function getAvailable(string memory _safe3Addr) public view returns (Safe3Info memory) {
        return availables[_safe3Addr];
    }

    function getLocked(string memory _safe3Addr) public view returns (Safe3LockInfo[] memory) {
        return locks[_safe3Addr];
    }

    function getAllAvailable() public view returns (Safe3Info[] memory) {
        Safe3Info[] memory ret = new Safe3Info[](num);
        for(uint i = 0; i < addrs.length; i++) {
            ret[i] = availables[addrs[i]];
        }
        return ret;
    }

    function getAllLocked() public view returns (Safe3LockInfo[] memory) {
        Safe3LockInfo[] memory ret = new Safe3LockInfo[](lockNum);
        uint pos = 0;
        for(uint i = 0; i < lockedAddrs.length; i++) {
            Safe3LockInfo[] memory infos = locks[lockedAddrs[i]];
            for(uint k = 0; k > infos.length; k++) {
                ret[pos++] = infos[k];
            }
        }
        return ret;
    }

    function getSafe3Addr(bytes memory _pubkey) internal pure returns (string memory) {
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

    function verifySig(bytes memory _pubkey, bytes32 _msgHash, bytes memory _sig) internal pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly{
            r := mload(add(_sig ,32))
            s := mload(add(_sig ,64))
            v := byte(0,mload(add(_sig ,96)))
        }
        return getSafe4Addr(_pubkey) == ecrecover(_msgHash, v, r, s);
    }
}