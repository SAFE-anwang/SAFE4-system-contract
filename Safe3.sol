// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.2;

import "./System.sol";
import "./utils/Base58.sol";

contract Safe3 is ISafe3, System {
    uint internal constant SPOS_HEIGHT = 1092826;
    uint internal constant SAFE3_END_HEIGHT = 5000000;

    // avaiable safe3
    uint num;
    bytes20[] keyIDs;
    mapping(bytes20 => Safe3Info) availables;

    // locked safe3
    uint lockedNum;
    bytes20[] lockedKeyIDs;
    mapping(bytes20 => Safe3LockInfo[]) locks;

    function redeemAvaiable(bytes memory _pubkey, bytes memory _sig) public override {
        bytes20 keyID = getKeyIDFromPubkey(_pubkey);
        require(availables[keyID].amount > 0, "non-existent avaiable amount");
        require(availables[keyID].redeemHeight == 0, "has redeemed");

        bytes32 h = sha256(abi.encodePacked(getSafe3Addr(_pubkey)));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(_pubkey, msgHash, _sig), "invalid signature");

        address safe4Addr = getSafe4Addr(_pubkey);
        payable(safe4Addr).transfer(availables[keyID].amount);
        availables[keyID].amount = 0;
        availables[keyID].redeemHeight = block.number;
    }

    function redeemLock(bytes memory _pubkey, bytes memory _sig) public override {
        bytes20 keyID = getKeyIDFromPubkey(_pubkey);
        for(uint i = 0; i < locks[keyID].length; i++) {
            Safe3LockInfo memory info = locks[keyID][i];
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
                    if((info.unlockHeight - info.lockHeight) % DAYS_IN_MONTH != 0) {
                        lockDay += 1;
                    }
                } else {
                    lockDay += (info.unlockHeight - info.lockHeight) / 2880 + ((info.unlockHeight - info.lockHeight) % 2880 == 0 ? 0 : 1);
                }
                remainLockHeight = info.unlockHeight - SAFE3_END_HEIGHT;
            }
            uint lockID = getAccountManager().fromSafe3(safe4Addr, info.amount, lockDay, remainLockHeight);
            if(info.isMN) {
                getMasterNode().fromSafe3(safe4Addr, info.amount, lockDay, lockID);
            }
        }
    }

    function getAvailable(string memory _safe3Addr) public view override returns (Safe3Info memory) {
        bytes20 keyID = bytesToBytes20(getKeyIDFromAddress(_safe3Addr), 0);
        return availables[keyID];
    }

    function getLocked(string memory _safe3Addr) public view override returns (Safe3LockInfo[] memory) {
        bytes20 keyID = bytesToBytes20(getKeyIDFromAddress(_safe3Addr), 0);
        return locks[keyID];
    }

    function getAllAvailable() public view override returns (Safe3Info[] memory) {
        Safe3Info[] memory ret = new Safe3Info[](num);
        for(uint i = 0; i < keyIDs.length; i++) {
            ret[i] = availables[keyIDs[i]];
        }
        return ret;
    }

    function getAllLocked() public view override returns (Safe3LockInfo[] memory) {
        Safe3LockInfo[] memory ret = new Safe3LockInfo[](lockedNum);
        uint pos = 0;
        for(uint i = 0; i < lockedKeyIDs.length; i++) {
            Safe3LockInfo[] memory infos = locks[lockedKeyIDs[i]];
            for(uint k = 0; k > infos.length; k++) {
                ret[pos++] = infos[k];
            }
        }
        return ret;
    }

    function getKeyIDFromPubkey(bytes memory _pubkey) internal pure returns (bytes20) {
        return ripemd160(abi.encodePacked(sha256(_pubkey)));
    }

    function getKeyIDFromAddress(string memory _safe3Addr) internal pure returns (bytes memory) {
        bytes memory b =  Base58.decodeFromString(_safe3Addr);
        require(b.length == 25, "invalid safe3 address");
        bytes memory keyID = new bytes(20);
        for(uint i = 0; i < 20; i++) {
            keyID[i] = b[i + 1];
        }
        return keyID;
    }

    function getSafe3Addr(bytes memory _pubkey) internal pure returns (string memory) {
        bytes32 h = sha256(_pubkey);
        bytes20 keyID = ripemd160(abi.encodePacked(h));
        bytes memory t = new bytes(21);
        t[0] = 0x4c;
        for(uint i = 0; i < 20; i++) {
            t[i + 1] = keyID[i];
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

    function bytesToBytes20(bytes memory b, uint offset) internal pure returns (bytes20) {
        bytes20 out;
        for (uint i = 0; i < 20; i++) {
            out |= bytes20(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}