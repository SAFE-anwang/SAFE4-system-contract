// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/Base58.sol";
import "./utils/StringUtil.sol";

contract Safe3 is ISafe3, System {
    using StringUtil for string;

    // available safe3
    bytes[] keyIDs;
    mapping(bytes => Safe3Info) availables;

    // locked safe3
    bytes[] lockedKeyIDs;
    mapping(bytes => Safe3LockInfo[]) locks;

    // special safe3
    uint specialNum;
    bytes[] specialKeyIDs;
    mapping(bytes => SpecialSafe3Info) specials;

    event RedeemAvailable(string _safe3Addr, uint _amount, address _safe4Addr);
    event RedeemLock(string _safe3Addr, uint _amount, uint _lockID);
    event RedeemMasterNode(string _safe3Addr, address _safe4Addr);
    event ApplyRedeemSpecial(string _safe3Addr, address _safe4Addr);
    event RedeemSpecialReject(string _safe3Addr);
    event RedeemSpecialAgree(string _safe3Addr);
    event RedeemSpecialVote(string _safe3Addr, address _voter, uint _voteResult);

    function redeemAvailable(bytes memory _pubkey, bytes memory _sig) public override onlyOwner {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey, [0]=0x04");

        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(availables[keyID].amount > 0, "non-existent available amount");
        require(availables[keyID].redeemHeight == 0, "has redeemed");

        string memory safe3Addr = getSafe3Addr(_pubkey);
        require(safe3Addr.equal(availables[keyID].safe3Addr), "pubkey is incompatiable with Safe3 address");

        bytes32 h = sha256(abi.encodePacked(safe3Addr));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(_pubkey, msgHash, _sig), "invalid signature");

        address safe4Addr = getSafe4Addr(_pubkey);
        payable(safe4Addr).transfer(availables[keyID].amount);
        availables[keyID].safe4Addr = safe4Addr;
        availables[keyID].redeemHeight = block.number;
    }

    function redeemLocked(bytes memory _pubkey, bytes memory _sig, string memory _enode) public override onlyOwner {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey, [0]=0x04");

        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(locks[keyID].length > 0, "non-existent locked amount");

        string memory safe3Addr = getSafe3Addr(_pubkey);
        bytes32 h = sha256(abi.encodePacked(safe3Addr));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(_pubkey, msgHash, _sig), "invalid signature");

        address safe4Addr = getSafe4Addr(_pubkey);
        for(uint i = 0; i < locks[keyID].length; i++) {
            Safe3LockInfo memory info = locks[keyID][i];
            if(info.redeemHeight != 0 || !safe3Addr.equal(info.safe3Addr) || info.amount == 0 || info.lockDay == 0) {
                continue;
            }
            uint lockID = getAccountManager().fromSafe3{value: info.amount}(safe4Addr, info.lockDay, info.remainLockHeight);
            if(info.isMN) {
                getMasterNodeLogic().fromSafe3(safe4Addr, info.amount, info.lockDay, lockID, info.mnState);
                getMasterNodeLogic().changeEnode(safe4Addr, _enode);
            }
            locks[keyID][i].safe4Addr = safe4Addr;
            locks[keyID][i].redeemHeight = block.number;
        }
    }

    function applyRedeemSpecial(bytes memory _pubkey, bytes memory _sig) public override onlyOwner {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey, [0]=0x04");

        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(specials[keyID].amount > 0, "non-existent available amount");
        require(specials[keyID].redeemHeight == 0, "has redeemed");
        require(specials[keyID].applyHeight == 0, "has applied");

        string memory safe3Addr = getSafe3Addr(_pubkey);
        require(safe3Addr.equal(specials[keyID].safe3Addr), "pubkey is incompatiable with Safe3 address");

        bytes32 h = sha256(abi.encodePacked(safe3Addr));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(_pubkey, msgHash, _sig), "invalid signature");

        specials[keyID].safe4Addr = getSafe4Addr(_pubkey);
        specials[keyID].applyHeight = block.number;
    }

    function vote4Special(string memory _safe3Addr, uint _voteResult) public override onlySN {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        require(specials[keyID].amount != 0, "non-existent special safe3 address");
        require(specials[keyID].applyHeight > 0, "need apply first");
        require(specials[keyID].redeemHeight == 0, "has redeemed");
        require(_voteResult == Constant.VOTE_AGREE || _voteResult == Constant.VOTE_REJECT || _voteResult == Constant.VOTE_ABSTAIN, "invalue vote result, must be agree(1), reject(2), abstain(3)");

        SpecialSafe3Info storage info = specials[keyID];
        uint i = 0;
        for(i = 0; i < info.voters.length; i++) {
            if(info.voters[i] == msg.sender) {
                break;
            }
        }
        if(i != info.voters.length) {
            info.voteResults[i] = _voteResult;
        } else {
            info.voters.push(msg.sender);
            info.voteResults.push(_voteResult);
        }
        uint agreeCount = 0;
        uint rejectCount = 0;
        uint snCount = getSNNum();
        for(i = 0; i < info.voters.length; i++) {
            if(info.voteResults[i] == Constant.VOTE_AGREE) {
                agreeCount++;
            } else { // reject or abstain
                rejectCount++;
            }
            if(agreeCount > snCount * 2 / 3) {
                payable(info.safe4Addr).transfer(info.amount);
                info.redeemHeight = block.number;
                emit RedeemSpecialAgree(_safe3Addr);
                return;
            }
            if(rejectCount >= snCount / 3) {
                emit RedeemSpecialReject(_safe3Addr);
                return;
            }
        }
        emit RedeemSpecialVote(_safe3Addr, msg.sender, _voteResult);
    }

    function getAvailable(string memory _safe3Addr) public view override returns (Safe3Info memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        return availables[keyID];
    }

    function getLocked(string memory _safe3Addr) public view override returns (Safe3LockInfo[] memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        return locks[keyID];
    }

    function getSpecial(string memory _safe3Addr) public view override returns (SpecialSafe3Info memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        return specials[keyID];
    }

    function getAllAvailable() public view override returns (Safe3Info[] memory) {
        Safe3Info[] memory ret = new Safe3Info[](keyIDs.length);
        for(uint i = 0; i < keyIDs.length; i++) {
            ret[i] = availables[keyIDs[i]];
        }
        return ret;
    }

    function getAllLocked() public view override returns (Safe3LockInfo[] memory) {
        Safe3LockInfo[] memory ret = new Safe3LockInfo[](lockedKeyIDs.length);
        uint pos = 0;
        for(uint i = 0; i < lockedKeyIDs.length; i++) {
            Safe3LockInfo[] memory infos = locks[lockedKeyIDs[i]];
            for(uint k = 0; k < infos.length; k++) {
                ret[pos++] = infos[k];
            }
        }
        return ret;
    }

    function getAllSpecial() public view override returns (SpecialSafe3Info[] memory) {
        SpecialSafe3Info[] memory ret = new SpecialSafe3Info[](specialKeyIDs.length);
        for(uint i = 0; i < specialKeyIDs.length; i++) {
            ret[i] = specials[specialKeyIDs[i]];
        }
        return ret;
    }

    function getKeyIDFromPubkey(bytes memory _pubkey) public pure returns (bytes memory) {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey, [0]=0x04");
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

    function getKeyIDFromAddress(string memory _safe3Addr) public pure returns (bytes memory) {
        return Base58.decodeFromString(_safe3Addr);
    }

    function getSafe3Addr(bytes memory _pubkey) public pure returns (string memory) {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey");
        return string(Base58.encode(getKeyIDFromPubkey(_pubkey)));
    }

    function getSafe4Addr(bytes memory _pubkey) public pure returns (address addr) {
        return address(uint160(uint256(keccak256(getPubkey4(_pubkey)))));
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
        return getSafe4Addr(getPubkey4(_pubkey)) == ecrecover(_msgHash, v, r, s);
    }

    function getPubkey4(bytes memory _pubkey) internal pure returns (bytes memory) {
        if(_pubkey.length == 65 && _pubkey[0] == 0x04) {
            bytes memory temp = new bytes(64);
            for(uint i = 0; i < 64; i++) {
                temp[i] = _pubkey[i + 1];
            }
            return temp;
        }
        return _pubkey;
    }
}