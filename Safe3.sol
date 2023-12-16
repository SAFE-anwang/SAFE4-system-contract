// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/Base58.sol";

contract Safe3 is ISafe3, System {
    // available safe3
    uint num;
    bytes[] keyIDs;
    mapping(bytes => Safe3Info) availables;

    // locked safe3
    uint lockedNum;
    bytes[] lockedKeyIDs;
    mapping(bytes => Safe3LockInfo[]) locks;

    function redeemAvailable(bytes memory _pubkey, bytes memory _sig) public override {
        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(availables[keyID].amount > 0, "non-existent available amount");
        require(availables[keyID].redeemHeight == 0, "has redeemed");

        bytes32 h = sha256(abi.encodePacked(string(Base58.encode(keyID))));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(_pubkey, msgHash, _sig), "invalid signature");

        address safe4Addr = getSafe4Addr(_pubkey);
        payable(safe4Addr).transfer(availables[keyID].amount);
        availables[keyID].amount = 0;
        availables[keyID].redeemHeight = block.number;
    }

    function redeemLocked(bytes memory _pubkey, bytes memory _sig) public override {
        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
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
            if(info.unlockHeight <= Constant.SAFE3_END_HEIGHT) {
                lockDay = 0;
                remainLockHeight = 0;
            } else {
                if(info.lockHeight < Constant.SPOS_HEIGHT) {
                    if(info.unlockHeight <= Constant.SPOS_HEIGHT) {
                        lockDay += (info.unlockHeight - info.lockHeight) / 576;
                    } else {
                        lockDay += (Constant.SPOS_HEIGHT - info.lockHeight) / 576;
                        lockDay += (info.unlockHeight - Constant.SPOS_HEIGHT) / 2880;
                    }
                    if((info.unlockHeight - info.lockHeight) % Constant.DAYS_IN_MONTH != 0) {
                        lockDay += 1;
                    }
                } else {
                    lockDay += (info.unlockHeight - info.lockHeight) / 2880 + ((info.unlockHeight - info.lockHeight) % 2880 == 0 ? 0 : 1);
                }
                remainLockHeight = info.unlockHeight - Constant.SAFE3_END_HEIGHT;
            }
            uint lockID = getAccountManager().fromSafe3(safe4Addr, info.amount, lockDay, remainLockHeight);
            if(info.isMN) {
                getMasterNodeLogic().fromSafe3(safe4Addr, info.amount, lockDay, lockID);
            }
        }
    }

    function getAvailable(string memory _safe3Addr) public view override returns (Safe3Info memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        return availables[keyID];
    }

    function getLocked(string memory _safe3Addr) public view override returns (Safe3LockInfo[] memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
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
            for(uint k = 0; k < infos.length; k++) {
                ret[pos++] = infos[k];
            }
        }
        return ret;
    }

    function getKeyIDFromPubkey(bytes memory _pubkey) internal pure returns (bytes memory) {
        bytes32 h = sha256(_pubkey);
        bytes20 r = ripemd160(abi.encodePacked(h));
        bytes memory t = new bytes(21);
        t[0] = 0x4c;
        for(uint i = 0; i < 20; i++) {
            t[i + 1] = r[i];
        }
        h = sha256(t);
        h = sha256(abi.encodePacked(h));
        bytes memory t2 = new bytes(25);
        for(uint i = 0; i < 21; i++) {
            t2[i] = t[i];
        }
        for(uint i = 0; i < 4; i++) {
            t2[i + 21] = h[i];
        }
        return t2;
    }

    function getKeyIDFromAddress(string memory _safe3Addr) internal pure returns (bytes memory) {
        return Base58.decodeFromString(_safe3Addr);
    }

    //function getSafe3Addr(bytes memory _pubkey) internal pure returns (string memory) {
    //    return string(Base58.encode(getKeyIDFromPubkey(_pubkey)));
    //}

    function getSafe4Addr(bytes memory _pubkey) internal pure returns (address addr) {
        return address(uint160(uint256(keccak256(_pubkey))));
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