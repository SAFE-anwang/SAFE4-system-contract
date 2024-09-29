// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./utils/Base58.sol";
import "./utils/StringUtil.sol";
import "./utils/Secp256k1.sol";

contract Safe3 is ISafe3, System {
    using StringUtil for string;

    struct AvailableData {
        uint64 amount;
        uint32 redeemHeight;
        address safe4Addr;
    }

    struct LockedData {
        uint64 amount;
        uint32 remainLockHeight;
        uint16 lockDay;
        bool isMN;
        uint32 redeemHeight;
        address safe4Addr;
    }

    struct SpecialData {
        uint64 amount;
        uint32 applyHeight;
        uint32 redeemHeight;
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
    event RedeemLocked(string _safe3Addr, uint _amount, address _safe4Addr, uint _lockID);
    event RedeemMasterNode(string _safe3Addr, address _safe4Addr, uint _lockID, address _mnAddr);
    event ApplyRedeemSpecial(string _safe3Addr, uint _amount, address _safe4Addr);
    event RedeemSpecialReject(string _safe3Addr);
    event RedeemSpecialAgree(string _safe3Addr);
    event RedeemSpecialVote(string _safe3Addr, address _voter, uint _voteResult);

    bool internal lock; // re-entrant lock
    modifier noReentrant() {
        require(!lock, "Error: reentrant call");
        lock = true;
        _;
        lock = false;
    }

    function batchRedeemAvailable(bytes[] memory _pubkeys, bytes[] memory _sigs, address _targetAddr) public override noReentrant {
        require(_pubkeys.length == _sigs.length, "invalid parameter count");
        require(_targetAddr != address(0), "invalid target address");
        for(uint k; k < _pubkeys.length; k++) {
            require(checkPubkey(_pubkeys[k]), "invalid pubkey");
            require(checkSig(_pubkeys[k], _sigs[k], _targetAddr), "invalid signautre");
            bytes memory keyID = getKeyIDFromPubkey(_pubkeys[k]);
            if(availables[keyID].amount == 0 || availables[keyID].redeemHeight != 0) {
                continue;
            }
            string memory safe3Addr = getSafe3Addr(_pubkeys[k]);
            payable(_targetAddr).transfer(availables[keyID].amount * 10000000000);
            availables[keyID].safe4Addr = _targetAddr;
            availables[keyID].redeemHeight = uint32(block.number);
            emit RedeemAvailable(safe3Addr, availables[keyID].amount * 10000000000, _targetAddr);
        }
    }

    function batchRedeemLocked(bytes[] memory _pubkeys, bytes[] memory _sigs, address _targetAddr) public override {
        require(_pubkeys.length == _sigs.length, "invalid parameter count");
        require(_targetAddr != address(0), "invalid target address");
        for(uint k; k < _pubkeys.length; k++) {
            require(checkPubkey(_pubkeys[k]), "invalid pubkey");
            require(checkSig(_pubkeys[k], _sigs[k], _targetAddr), "invalid signautre");
            bytes memory keyID = getKeyIDFromPubkey(_pubkeys[k]);
            string memory safe3Addr = getSafe3Addr(_pubkeys[k]);
            for(uint i; i < locks[keyID].length; i++) {
                LockedData storage data = locks[keyID][i];
                if(data.amount > 0 && data.redeemHeight == 0 && !data.isMN) {
                    uint lockID = getAccountManager().fromSafe3{value: data.amount * 10000000000}(_targetAddr, data.lockDay, data.remainLockHeight);
                    data.safe4Addr = _targetAddr;
                    data.redeemHeight = uint32(block.number);
                    emit RedeemLocked(safe3Addr, data.amount * 10000000000, _targetAddr, lockID);
                }
            }
        }
    }

    function batchRedeemMasterNode(bytes[] memory _pubkeys, bytes[] memory _sigs, string[] memory _enodes, address _targetAddr) public override {
        require(_pubkeys.length == _sigs.length || _pubkeys.length == _enodes.length, "invalid parameter count");
        require(_targetAddr != address(0), "invalid target address");
        for(uint k; k < _pubkeys.length; k++) {
            require(checkPubkey(_pubkeys[k]), "invalid pubkey");
            require(checkSig(_pubkeys[k], _sigs[k], _targetAddr), "invalid signautre");
            bytes memory keyID = getKeyIDFromPubkey(_pubkeys[k]);
            string memory safe3Addr = getSafe3Addr(_pubkeys[k]);
            address mnAddr = getSafe4Addr(_pubkeys[k]);
            for(uint i; i < locks[keyID].length; i++) {
                LockedData storage data = locks[keyID][i];
                if(data.amount > 0 && data.redeemHeight == 0 && data.isMN) {
                    uint lockID = getAccountManager().fromSafe3{value: data.amount * 10000000000}(_targetAddr, data.lockDay, data.remainLockHeight);
                    getMasterNodeLogic().fromSafe3(mnAddr, _targetAddr, data.amount * 10000000000, data.lockDay, lockID, _enodes[k]);
                    data.safe4Addr = _targetAddr;
                    data.redeemHeight = uint32(block.number);
                    emit RedeemMasterNode(safe3Addr, _targetAddr, lockID, mnAddr);
                    break;
                }
            }
        }
    }

    function applyRedeemSpecial(bytes memory _pubkey, bytes memory _sig) public override {
        require(checkPubkey(_pubkey), "invalid pubkey");
        require(checkSig(_pubkey, _sig), "invalid signautre");

        bytes memory keyID = getKeyIDFromPubkey(_pubkey);
        require(specials[keyID].amount > 0, "non-existent available amount");
        require(specials[keyID].redeemHeight == 0, "has redeemed");
        require(specials[keyID].applyHeight == 0, "has applied");

        string memory safe3Addr = getSafe3Addr(_pubkey);
        specials[keyID].safe4Addr = getSafe4Addr(_pubkey);
        specials[keyID].applyHeight = uint32(block.number);
        emit ApplyRedeemSpecial(safe3Addr, specials[keyID].amount * 10000000000, specials[keyID].safe4Addr);
    }

    function vote4Special(string memory _safe3Addr, uint _voteResult) public override noReentrant { // only for creator of formal supernodes
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        require(specials[keyID].amount != 0, "non-existent special safe3 address");
        require(specials[keyID].applyHeight > 0, "need apply first");
        require(specials[keyID].redeemHeight == 0, "has redeemed");
        require(_voteResult == Constant.VOTE_AGREE || _voteResult == Constant.VOTE_REJECT || _voteResult == Constant.VOTE_ABSTAIN, "invalue vote result, must be agree(1), reject(2), abstain(3)");
        address[] memory sns = getSuperNodeStorage().getTops4Creator(msg.sender);
        require(sns.length > 0, "caller isn't creator of formal supernodes");
        SpecialData storage data = specials[keyID];
        for(uint k; k < sns.length; k++) {
            uint i;
            for(; i < data.voters.length; i++) {
                if(data.voters[i] == sns[k]) {
                    break;
                }
            }
            if(i != data.voters.length) {
                data.voteResults[i] = _voteResult;
            } else {
                data.voters.push(sns[k]);
                data.voteResults.push(_voteResult);
            }
            emit RedeemSpecialVote(_safe3Addr, sns[k], _voteResult);
        }
        uint agreeCount;
        uint rejectCount;
        uint snCount = getSNNum();
        for(uint i = 0; i < data.voters.length; i++) {
            if(data.voteResults[i] == Constant.VOTE_AGREE) {
                agreeCount++;
            } else { // reject or abstain
                rejectCount++;
            }
            if(agreeCount > snCount * 2 / 3) {
                payable(data.safe4Addr).transfer(data.amount * 10000000000);
                data.redeemHeight = uint32(block.number);
                emit RedeemSpecialAgree(_safe3Addr);
                return;
            }
            if(rejectCount >= snCount / 3) {
                emit RedeemSpecialReject(_safe3Addr);
                return;
            }
        }
    }

    function getAllAvailableNum() public view override returns (uint) {
        return keyIDs.length;
    }

    function getAvailableInfos(uint _start, uint _count) public view override returns (AvailableSafe3Info[] memory) {
        require(_start < keyIDs.length, "invalid _start, must be in [0, getAllAvailableNum())");
        require(_count > 0 && _count <= 10, "max return 10 available infos");

        uint num = _count;
        if(_start + _count >= keyIDs.length) {
            num = keyIDs.length - _start;
        }

        AvailableSafe3Info[] memory ret = new AvailableSafe3Info[](num);
        bytes memory keyID;
        for(uint i; i < num; i++) {
            keyID = keyIDs[i + _start];
            ret[i] = AvailableSafe3Info(string(Base58.encode(keyID)), uint(availables[keyID].amount) * 10000000000, availables[keyID].safe4Addr, availables[keyID].redeemHeight);
        }
        return ret;
    }

    function getAvailableInfo(string memory _safe3Addr) public view override returns (AvailableSafe3Info memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        return AvailableSafe3Info(_safe3Addr, uint(availables[keyID].amount) * 10000000000, availables[keyID].safe4Addr, availables[keyID].redeemHeight);
    }

    function getAllLockedNum() public view override returns (uint) {
        return lockedNum;
    }

    function getLockedAddrNum() public view returns (uint) {
        return lockedKeyIDs.length;
    }

    function getLockedAddrs(uint _start, uint _count) external view override returns (string[] memory) {
        require(_start < lockedKeyIDs.length, "invalid _start, must be in [0, getLockedAddrNum())");
        require(_count > 0 && _count <= 10, "max return 10 locked addrs");

        uint num = _count;
        if(_start + _count >= lockedKeyIDs.length) {
            num = lockedKeyIDs.length - _start;
        }

        string[] memory ret = new string[](num);
        for(uint i; i < num; i++) {
            ret[i] = string(Base58.encode(lockedKeyIDs[i + _start]));
        }
        return ret;
    }

    function getLockedNum(string memory _safe3Addr) public view override returns (uint) {
        return locks[getKeyIDFromAddress(_safe3Addr)].length;
    }

    function getLockedInfo(string memory _safe3Addr, uint _start, uint _count) public view override returns (LockedSafe3Info[] memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        require(locks[keyID].length > 0, "non-existent locked amount");
        require(_start < locks[keyID].length, "invalid _start, must be in [0, getLockedNum(addr))");
        require(_count > 0 && _count <= 10, "max return 10 locked infos");

        uint num = _count;
        if(_start + _count >= locks[keyID].length) {
            num = locks[keyID].length - _start;
        }

        LockedSafe3Info[] memory ret = new LockedSafe3Info[](num);
        LockedData memory data;
        for(uint i; i < num; i++) {
            data = locks[keyID][i + _start];
            ret[i] = LockedSafe3Info(_safe3Addr, uint(data.amount) * 10000000000, data.remainLockHeight, data.lockDay, data.isMN, data.safe4Addr, data.redeemHeight);
        }
        return ret;
    }

    function getAllSpecialNum() public view override returns (uint) {
        return specialKeyIDs.length;
    }

    function getSpecialInfos(uint _start, uint _count) public view override returns (SpecialSafe3Info[] memory) {
        require(_start < specialKeyIDs.length, "invalid _start, must be in [0, getAllSpecialNum())");
        require(_count > 0 && _count <= 10, "max return 10 special infos");

        uint num = _count;
        if(_start + _count >= specialKeyIDs.length) {
            num = specialKeyIDs.length - _start;
        }

        SpecialSafe3Info[] memory ret = new SpecialSafe3Info[](num);
        bytes memory keyID;
        for(uint i; i < num; i++) {
            keyID = specialKeyIDs[i + _start];
            SpecialData memory data = specials[keyID];
            ret[i].safe3Addr = string(Base58.encode(keyID));
            ret[i].amount = uint(data.amount) * 10000000000;
            ret[i].applyHeight = data.applyHeight;
            ret[i].voters = new address[](data.voters.length);
            for(uint k; k < data.voters.length; k++) {
                ret[i].voters[k] = data.voters[k];
            }
            ret[i].voteResults = new uint[](data.voteResults.length);
            for(uint k; k < data.voteResults.length; k++) {
                ret[i].voteResults[k] = data.voteResults[k];
            }
            ret[i].safe4Addr = data.safe4Addr;
            ret[i].redeemHeight = data.redeemHeight;
        }
        return ret;
    }

    function getSpecialInfo(string memory _safe3Addr) public view override returns (SpecialSafe3Info memory) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        SpecialData memory data = specials[keyID];
        SpecialSafe3Info memory ret;
        ret.safe3Addr = _safe3Addr;
        ret.amount = uint(data.amount) * 10000000000;
        ret.applyHeight = data.applyHeight;
        ret.voters = new address[](data.voters.length);
        for(uint i; i < data.voters.length; i++) {
            ret.voters[i] = data.voters[i];
        }
        ret.voteResults = new uint[](data.voteResults.length);
        for(uint i; i < data.voteResults.length; i++) {
            ret.voteResults[i] = data.voteResults[i];
        }
        ret.safe4Addr = data.safe4Addr;
        ret.redeemHeight = data.redeemHeight;
        return ret;
    }

    function existAvailableNeedToRedeem(string memory _safe3Addr) public view override returns (bool) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        return (availables[keyID].amount > 0 && availables[keyID].redeemHeight == 0);
    }

    function existLockedNeedToRedeem(string memory _safe3Addr) public view override returns (bool) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        if(locks[keyID].length == 0) {
            return false;
        }
        for(uint i; i < locks[keyID].length; i++) {
            LockedData memory data = locks[keyID][i];
            if(data.amount > 0 && data.redeemHeight == 0 && !data.isMN) {
                return true;
            }
        }
        return false;
    }

    function existMasterNodeNeedToRedeem(string memory _safe3Addr) public view override returns (bool) {
        bytes memory keyID = getKeyIDFromAddress(_safe3Addr);
        if(locks[keyID].length == 0) {
            return false;
        }
        for(uint i; i < locks[keyID].length; i++) {
            LockedData memory data = locks[keyID][i];
            if(data.amount > 0 && data.redeemHeight == 0 && data.isMN) {
                return true;
            }
        }
        return false;
    }

    function getKeyIDFromPubkey(bytes memory _pubkey) internal pure returns (bytes memory) {
        bytes32 h = sha256(_pubkey);
        bytes20 r = ripemd160(abi.encodePacked(h));
        bytes memory t = new bytes(21);
        t[0] = 0x4c;
        for(uint i; i < 20; i++) {
            t[i + 1] = r[i];
        }
        h = sha256(t);
        h = sha256(abi.encodePacked(h));
        bytes memory t2 = new bytes(25);
        for(uint i; i < 21; i++) {
            t2[i] = t[i];
        }
        for(uint i; i < 4; i++) {
            t2[i + 21] = h[i];
        }
        return t2;
    }

    function getKeyIDFromAddress(string memory _safe3Addr) internal pure returns (bytes memory) {
        return Base58.decodeFromString(_safe3Addr);
    }

    function getSafe3Addr(bytes memory _pubkey) internal pure returns (string memory) {
        return string(Base58.encode(getKeyIDFromPubkey(_pubkey)));
    }

    function getSafe4Addr(bytes memory _pubkey) internal pure returns (address addr) {
        return address(uint160(uint256(keccak256(getPubkey4(_pubkey)))));
    }

    function checkPubkey(bytes memory _pubkey) internal pure returns (bool) {
        return (_pubkey.length == 65 && (_pubkey[0] == 0x04 || _pubkey[0] == 0x06 || _pubkey[0] == 0x07)) ||
               (_pubkey.length == 33 && (_pubkey[0] == 0x02 || _pubkey[0] == 0x03));
    }

    function getPubkey4(bytes memory _pubkey) internal pure returns (bytes memory) {
        bytes memory pubkey = _pubkey;
        if(_pubkey.length != 65) {
            pubkey = Secp256k1.getDecompressed(_pubkey);
        }
        if(pubkey.length == 65) {
            bytes memory temp = new bytes(64);
            for(uint i; i < 64; i++) {
                temp[i] = pubkey[i + 1];
            }
            return temp;
        }
        revert("get decompressed pubkey failed");
    }

    function checkSig(bytes memory _pubkey, bytes memory _sig) internal pure returns (bool) {
        return checkSig(_pubkey, _sig, address(0));
    }

    function checkSig(bytes memory _pubkey, bytes memory _sig, address _targetAddr) public pure returns (bool) {
        string memory safe3Addr = getSafe3Addr(_pubkey);
        bytes32 h;
        if(_targetAddr == address(0)) {
            h = sha256(abi.encodePacked(safe3Addr));
        } else {
            h = sha256(abi.encodePacked(safe3Addr, _targetAddr));
        }
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly{
            r := mload(add(_sig ,32))
            s := mload(add(_sig ,64))
            v := byte(0,mload(add(_sig ,96)))
        }
        return getSafe4Addr(_pubkey) == ecrecover(msgHash, v, r, s);
    }
}