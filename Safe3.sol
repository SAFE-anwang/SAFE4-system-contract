// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/Base58.sol";
import "./utils/StringUtil.sol";

contract Safe3 is ISafe3, System {
    using StringUtil for string;

    struct AvailableData {
        uint96 amount;
        uint24 redeemHeight;
        address safe4Addr;
    }

    struct LockedData {
        bytes32 txid;
        uint16 n; // txout-pos
        uint96 amount;
        uint24 lockHeight;
        uint24 unlockHeight;
        uint24 remainLockHeight;
        uint16 lockDay;
        bool isMN;
        uint24 redeemHeight;
        address safe4Addr;
    }

    struct SpecialData {
        uint96 amount;
        uint24 applyHeight;
        uint24 redeemHeight;
        address safe4Addr;
        address[] voters;
        uint[] voteResults;
    }

    // available safe3
    bytes[] keyIDs;
    mapping(bytes => AvailableData) availables;

    // locked safe3
    uint lockedNum;
    bytes[] lockedKeyIDs;
    mapping(bytes => LockedData[]) locks;

    // special safe3
    bytes[] specialKeyIDs;
    mapping(bytes => SpecialData) specials;

    event RedeemAvailable(string _safe3Addr, uint _amount, address _safe4Addr);
    event RedeemLock(string _safe3Addr, uint _amount, uint _lockID);
    event RedeemMasterNode(string _safe3Addr, address _safe4Addr);
    event ApplyRedeemSpecial(string _safe3Addr, address _safe4Addr);
    event RedeemSpecialReject(string _safe3Addr);
    event RedeemSpecialAgree(string _safe3Addr);
    event RedeemSpecialVote(string _safe3Addr, address _voter, uint _voteResult);

    function redeemAvailable(bytes memory _pubkey, bytes memory _sig) public override {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey, [0]=0x04");

        bytes memory tempPubkey = getPubkey4(_pubkey);
        require((uint(keccak256(tempPubkey)) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) == uint(uint160(msg.sender)), "pubkey is incompatiable with caller");

        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(availables[keyID].amount > 0, "non-existent available amount");
        require(availables[keyID].redeemHeight == 0, "has redeemed");

        string memory safe3Addr = getSafe3Addr(_pubkey);
        // require(safe3Addr.equal(availables[keyID].safe3Addr), "pubkey is incompatiable with Safe3 address");

        bytes32 h = sha256(abi.encodePacked(safe3Addr));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(tempPubkey, msgHash, _sig), "invalid signature");

        address safe4Addr = getSafe4Addr(tempPubkey);
        payable(safe4Addr).transfer(availables[keyID].amount);
        availables[keyID].safe4Addr = safe4Addr;
        availables[keyID].redeemHeight = uint24(block.number);
    }

    function redeemLocked(bytes memory _pubkey, bytes memory _sig, string memory _enode) public override {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey, [0]=0x04");

        bytes memory tempPubkey = getPubkey4(_pubkey);
        require((uint(keccak256(tempPubkey)) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) == uint(uint160(msg.sender)), "pubkey is incompatiable with caller");

        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(locks[keyID].length > 0, "non-existent locked amount");

        string memory safe3Addr = getSafe3Addr(_pubkey);
        bytes32 h = sha256(abi.encodePacked(safe3Addr));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(tempPubkey, msgHash, _sig), "invalid signature");

        address safe4Addr = getSafe4Addr(tempPubkey);
        for(uint i = 0; i < locks[keyID].length; i++) {
            LockedData memory data = locks[keyID][i];
            if(data.redeemHeight != 0 || data.amount == 0 || data.lockDay == 0) {
                continue;
            }
            uint lockID = getAccountManager().fromSafe3{value: data.amount}(safe4Addr, data.lockDay, data.remainLockHeight);
            if(data.isMN) {
                getMasterNodeLogic().fromSafe3(safe4Addr, data.amount, data.lockDay, lockID, _enode);
            }
            locks[keyID][i].safe4Addr = safe4Addr;
            locks[keyID][i].redeemHeight = uint24(block.number);
        }
    }

    function applyRedeemSpecial(bytes memory _pubkey, bytes memory _sig) public override {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey, [0]=0x04");

        bytes memory tempPubkey = getPubkey4(_pubkey);
        require((uint(keccak256(tempPubkey)) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) == uint(uint160(msg.sender)), "pubkey is incompatiable with caller");

        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(specials[keyID].amount > 0, "non-existent available amount");
        require(specials[keyID].redeemHeight == 0, "has redeemed");
        require(specials[keyID].applyHeight == 0, "has applied");

        string memory safe3Addr = getSafe3Addr(_pubkey);
        // require(safe3Addr.equal(specials[keyID].safe3Addr), "pubkey is incompatiable with Safe3 address");

        bytes32 h = sha256(abi.encodePacked(safe3Addr));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        require(verifySig(tempPubkey, msgHash, _sig), "invalid signature");

        specials[keyID].safe4Addr = getSafe4Addr(tempPubkey);
        specials[keyID].applyHeight = uint24(block.number);
    }

    function vote4Special(string memory _safe3Addr, uint _voteResult) public override onlySN {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        require(specials[keyID].amount != 0, "non-existent special safe3 address");
        require(specials[keyID].applyHeight > 0, "need apply first");
        require(specials[keyID].redeemHeight == 0, "has redeemed");
        require(_voteResult == Constant.VOTE_AGREE || _voteResult == Constant.VOTE_REJECT || _voteResult == Constant.VOTE_ABSTAIN, "invalue vote result, must be agree(1), reject(2), abstain(3)");

        SpecialData storage data = specials[keyID];
        uint i = 0;
        for(i = 0; i < data.voters.length; i++) {
            if(data.voters[i] == msg.sender) {
                break;
            }
        }
        if(i != data.voters.length) {
            data.voteResults[i] = _voteResult;
        } else {
            data.voters.push(msg.sender);
            data.voteResults.push(_voteResult);
        }
        uint agreeCount = 0;
        uint rejectCount = 0;
        uint snCount = getSNNum();
        for(i = 0; i < data.voters.length; i++) {
            if(data.voteResults[i] == Constant.VOTE_AGREE) {
                agreeCount++;
            } else { // reject or abstain
                rejectCount++;
            }
            if(agreeCount > snCount * 2 / 3) {
                payable(data.safe4Addr).transfer(data.amount);
                data.redeemHeight = uint24(block.number);
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

    function getAvailable(string memory _safe3Addr) public view override returns (AvailableSafe3Info memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        return AvailableSafe3Info(_safe3Addr, availables[keyID].amount, availables[keyID].safe4Addr, availables[keyID].redeemHeight);
    }

    function getLocked(string memory _safe3Addr) public view override returns (LockedSafe3Info[] memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        LockedSafe3Info[] memory ret = new LockedSafe3Info[](locks[keyID].length);
        for(uint i = 0; i < locks[keyID].length; i++) {
            LockedData memory data = locks[keyID][i];
            ret[i] = LockedSafe3Info(_safe3Addr, data.amount, string(abi.encodePacked(StringUtil.toHex(data.txid), "-", StringUtil.toString(data.n))), data.lockHeight, data.unlockHeight, data.remainLockHeight, data.lockDay, data.isMN, data.safe4Addr, data.redeemHeight);
        }
        return ret;
    }

    function getSpecial(string memory _safe3Addr) public view override returns (SpecialSafe3Info memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        SpecialData memory data = specials[keyID];
        SpecialSafe3Info memory ret;
        ret.safe3Addr = _safe3Addr;
        ret.amount = data.amount;
        ret.applyHeight = data.applyHeight;
        ret.voters = new address[](data.voters.length);
        for(uint i = 0; i < data.voters.length; i++) {
            ret.voters[i] = data.voters[i];
        }
        ret.voteResults = new uint[](data.voteResults.length);
        for(uint i = 0; i < data.voteResults.length; i++) {
            ret.voteResults[i] = data.voteResults[i];
        }
        ret.safe4Addr = data.safe4Addr;
        ret.redeemHeight = data.redeemHeight;
        return ret;
    }

    function getAllAvailable() public view override returns (AvailableSafe3Info[] memory) {
        AvailableSafe3Info[] memory ret = new AvailableSafe3Info[](keyIDs.length);
        for(uint i = 0; i < keyIDs.length; i++) {
            bytes memory keyID = keyIDs[i];
            ret[i] = AvailableSafe3Info(string(Base58.encode(keyID)), availables[keyID].amount, availables[keyID].safe4Addr, availables[keyID].redeemHeight);
        }
        return ret;
    }

    function getAllLocked() public view override returns (LockedSafe3Info[] memory) {
        LockedSafe3Info[] memory ret = new LockedSafe3Info[](lockedNum);
        uint pos = 0;
        for(uint i = 0; i < lockedKeyIDs.length; i++) {
            bytes memory keyID = lockedKeyIDs[i];
            for(uint k = 0; k < locks[keyID].length; k++) {
                LockedData memory data = locks[keyID][k];
                ret[pos++] = LockedSafe3Info(string(Base58.encode(keyID)), data.amount, string(abi.encodePacked(StringUtil.toHex(data.txid), "-", StringUtil.toString(data.n))), data.lockHeight, data.unlockHeight, data.remainLockHeight, data.lockDay, data.isMN, data.safe4Addr, data.redeemHeight);
            }
        }
        return ret;
    }

    function getAllSpecial() public view override returns (SpecialSafe3Info[] memory) {
        SpecialSafe3Info[] memory ret = new SpecialSafe3Info[](specialKeyIDs.length);
        for(uint i = 0; i < specialKeyIDs.length; i++) {
            SpecialData memory data = specials[specialKeyIDs[i]];
            ret[i].safe3Addr = string(Base58.encode(specialKeyIDs[i]));
            ret[i].amount = data.amount;
            ret[i].applyHeight = data.applyHeight;
            ret[i].voters = new address[](data.voters.length);
            for(uint k = 0; k < data.voters.length; k++) {
                ret[i].voters[k] = data.voters[k];
            }
            ret[i].voteResults = new uint[](data.voteResults.length);
            for(uint k = 0; k < data.voteResults.length; k++) {
                ret[i].voteResults[k] = data.voteResults[k];
            }
            ret[i].safe4Addr = data.safe4Addr;
            ret[i].redeemHeight = data.redeemHeight;
        }
        return ret;
    }

    function getKeyIDFromPubkey(bytes memory _pubkey) internal pure returns (bytes memory) {
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

    function getKeyIDFromAddress(string memory _safe3Addr) internal pure returns (bytes memory) {
        return Base58.decodeFromString(_safe3Addr);
    }

    function getSafe3Addr(bytes memory _pubkey) internal pure returns (string memory) {
        require(_pubkey.length == 65 && _pubkey[0] == 0x04, "must be uncompressed pubkey");
        return string(Base58.encode(getKeyIDFromPubkey(_pubkey)));
    }

    function getSafe4Addr(bytes memory _pubkey) internal pure returns (address addr) {
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