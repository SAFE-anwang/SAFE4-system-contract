// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.2;

import "./System.sol";

contract SNVote is ISNVote, System {
    // for records
    mapping(uint => VoteRecord) id2record; // voter's record to supernode or proxy vote

    // for voters
    mapping(address => mapping(address => VoteDetail)) voter2details; // voter to details
    mapping(address => uint) voter2amount; // voter to total amount
    mapping(address => uint) voter2num; // voter to total votenum
    mapping(address => address[]) voter2dsts; // voter to supernode or proxy list
    mapping(address => uint[]) voter2ids; // voter to record list

    // for supernodes or proxies
    mapping(address => mapping(address => VoteDetail)) dst2details; // supernode or proxy to details
    mapping(address => uint) dst2amount; // supernode or proxy to total amount
    mapping(address => uint) dst2num; // supernode or proxy to total votenum
    mapping(address => address[]) dst2voters; // supernode or proxy to voter list
    mapping(address => uint[]) dst2ids; // supernode or proxy to record list

    event SNVOTE_VOTE(address _voterAddr, address _snAddr, uint _recordID, uint _voteNum);
    event SNVOTE_APPROVAL(address _voterAddr, address _proxyAddr, uint _recordID, uint _voteNum);
    event SNVOTE_REMOVE_VOTE(address _voterAddr, address _snAddr, uint _recordID, uint _voteNum);
    event SNVOTE_REMOVE_APPROVAL(address _voterAddr, address _proxyAddr, uint _recordID, uint _voteNum);

    function voteOrApproval(bool _isVote, address _dstAddr, uint[] memory _recordIDs) public override {
        require(!isSN(msg.sender), "caller can't be supernode");
        if(_isVote) {
            require(isSN(_dstAddr), "invalid supernode address");
        } else {
            require(isMN(_dstAddr), "invalid proxy address");
        }
        uint id = 0;
        for(uint i = 0; i < _recordIDs.length; i++) {
            id = _recordIDs[i];
            if(_recordIDs[i] == 0) {
                // generate new record id
                id = getAccountManager().moveID0(msg.sender);
            }
            remove(msg.sender, id);
            add(msg.sender, _dstAddr, id);
        }
    }

    function removeVoteOrApproval(uint[] memory _recordIDs) public override {
        require(!isSN(msg.sender), "caller can't be supernode");
        for(uint i = 0; i < _recordIDs.length; i++) {
            if(_recordIDs[i] == 0) {
                continue;
            }
            remove(msg.sender, _recordIDs[i]);
        }
    }

    function removeVoteOrApproval2(address _voterAddr, uint _recordID) public override onlyAccountManagerContract {
        if(_recordID == 0) {
            return;
        }
        remove(_voterAddr, _recordID);
    }

    function proxyVote(address _snAddr) public override onlyMN {
        require(isSN(_snAddr), "invalid supernode");
        uint recordID;
        address voterAddr;
        uint[] memory ids = dst2ids[msg.sender];
        for(uint i = 0; i < ids.length; i++) {
            recordID = ids[i];
            voterAddr = id2record[recordID].voterAddr;
            remove(voterAddr, recordID); // remove vote or approval
            add(voterAddr, _snAddr, recordID); // add vote
        }
    }

    // get voter's supernode
    function getSuperNodes4Voter(address _voterAddr) public view override returns (address[] memory retAddrs, uint[] memory retNums) {
        uint count = 0;
        address[] memory dsts = voter2dsts[_voterAddr];
        for(uint i = 0; i < dsts.length; i++) {
            if(isSN(dsts[i])) {
                count++;
            }
        }
        if(count == 0) {
            return (retAddrs, retNums);
        }
        retAddrs = new address[](count);
        retNums = new uint[](count);
        uint index = 0;
        for(uint i = 0; i < dsts.length; i++) {
            if(isSN(dsts[i])) {
                retAddrs[index] = dsts[i];
                retNums[index++] = voter2details[_voterAddr][dsts[i]].totalNum;
            }
        }
        return (retAddrs, retNums);
    }

    // get voter's records
    function getRecordIDs4Voter(address _voterAddr) public view override returns (uint[] memory) {
        return voter2ids[_voterAddr];
    }

    // get supernode's voters
    function getVoters4SN(address _snAddr) public view override returns (address[] memory retAddrs, uint[] memory retNums) {
        require(isSN(_snAddr), "invalid supernode");
        retAddrs = dst2voters[_snAddr];
        retNums = new uint[](retAddrs.length);
        for(uint i = 0; i < retAddrs.length; i++) {
            retNums[i] = dst2details[_snAddr][retAddrs[i]].totalNum;
        }
    }

    // get supernode's votenum
    function getVoteNum4SN(address _snAddr) public view override returns (uint) {
        require(isSN(_snAddr), "invalid supernode");
        return dst2num[_snAddr];
    }

    // get voter's proxy
    function getProxies4Voter(address _voterAddr) public view override returns (address[] memory retAddrs, uint[] memory retNums) {
        uint count = 0;
        address[] memory dsts = voter2dsts[_voterAddr];
        for(uint i = 0; i < dsts.length; i++) {
            if(isMN(dsts[i])) {
                count++;
            }
        }
        if(count == 0) {
            return (retAddrs, retNums);
        }
        retAddrs = new address[](count);
        retNums = new uint[](count);
        uint index = 0;
        for(uint i = 0; i < dsts.length; i++) {
            if(isMN(dsts[i])) {
                retAddrs[index] = dsts[i];
                retNums[index++] = voter2details[_voterAddr][dsts[i]].totalNum;
            }
        }
    }

    // get voter's proxied record
    function getProxiedRecordIDs4Voter(address _voterAddr) public view override returns (uint[] memory retIDs) {
        uint[] memory ids = voter2ids[_voterAddr];
        uint id = 0;
        uint count = 0;
        for(uint i = 0; i < ids.length; i++) {
            id = ids[i];
            if(isMN(id2record[id].dstAddr)) {
                count++;
            }
        }
        if(count == 0) {
            return retIDs;
        }
        retIDs = new uint[](count);
        uint index = 0;
        for(uint i = 0; i < ids.length; i++) {
            id = ids[i];
            if(isMN(id2record[id].dstAddr)) {
                retIDs[index++] = id;
            }
        }
    }

    // get proxy's voters
    function getVoters4Proxy(address _proxyAddr) public view override returns (address[] memory retAddrs, uint[] memory retNums) {
        require(isMN(_proxyAddr), "invalid proxy");
        retAddrs = dst2voters[_proxyAddr];
        retNums = new uint[](retAddrs.length);
        for(uint i = 0; i < retAddrs.length; i++) {
            retNums[i] = dst2details[_proxyAddr][retAddrs[i]].totalNum;
        }
    }

    // get proxy's votenum
    function getVoteNum4Proxy(address _proxyAddr) public view override returns (uint) {
        require(isMN(_proxyAddr), "invalid proxy");
        return dst2num[_proxyAddr];
    }

    function existDst4Voter(address _voterAddr, address _dstAddr) internal view returns (bool, uint) {
        address[] memory dsts = voter2dsts[_voterAddr];
        for(uint i = 0; i < dsts.length; i++) {
            if(dsts[i] == _dstAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existVoter4Dst(address _dstAddr, address _voterAddr) internal view returns (bool, uint) {
        address[] memory voters = dst2voters[_dstAddr];
        for(uint i = 0; i < voters.length; i++) {
            if(voters[i] == _voterAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existID4Voter(address _voterAddr, uint _recordID) internal view returns (bool, uint) {
        uint[] memory recordIDs = voter2ids[_voterAddr];
        for(uint i = 0; i < recordIDs.length; i++) {
            if(recordIDs[i] == _recordID) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existID4Dst(address _dstAddr, uint _recordID) internal view returns (bool, uint) {
        uint[] memory recordIDs = dst2ids[_dstAddr];
        for(uint i = 0; i < recordIDs.length; i++) {
            if(recordIDs[i] == _recordID) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function add4Voter(address _voterAddr, address _dstAddr, uint _recordID, uint _amount, uint _num) internal {
        // update detail
        VoteDetail storage detail = voter2details[_voterAddr][_dstAddr];
        detail.addr = _dstAddr;
        detail.totalAmount += _amount;
        detail.totalNum += _num;
        detail.recordIDs.push(_recordID);

        // update total amount
        voter2amount[_voterAddr] += _amount;

        // update total votenum
        voter2num[_voterAddr] += _num;

        // update dst list
        bool flag = false;
        uint pos = 0;
        (flag, pos) = existDst4Voter(_voterAddr, _dstAddr);
        if(!flag) {
            voter2dsts[_voterAddr].push(_dstAddr);
        }

        // update record list
        flag = false;
        pos = 0;
        (flag, pos) = existID4Voter(_voterAddr, _recordID);
        if(!flag) {
            voter2ids[_voterAddr].push(_recordID);
        }
    }

    function add4Dst(address _dstAddr, address _voterAddr, uint _recordID, uint _amount, uint _num) internal {
        // update detail
        VoteDetail storage detail = dst2details[_dstAddr][_voterAddr];
        detail.addr = _voterAddr;
        detail.totalAmount += _amount;
        detail.totalNum += _num;
        detail.recordIDs.push(_recordID);

        // update total amount
        dst2amount[_dstAddr] += _amount;

        // update total votenum
        dst2num[_dstAddr] += _num;

        // update voter list
        bool flag = false;
        uint pos = 0;
        (flag, pos) = existVoter4Dst(_dstAddr, _voterAddr);
        if(!flag) {
            dst2voters[_dstAddr].push(_voterAddr);
        }

        // update record list
        flag = false;
        pos = 0;
        (flag, pos) = existID4Dst(_dstAddr, _recordID);
        if(!flag) {
            dst2ids[_dstAddr].push(_recordID);
        }
    }

    function add(address _voterAddr, address _dstAddr, uint _recordID) internal {
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_recordID);
        require(record.addr == _voterAddr, "caller isn't owner of record");

        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_recordID);
        require(block.number >= useinfo.releaseHeight, "record is voted, need wait for release");

        uint amount = record.amount;
        uint num = amount;
        if(isMN(useinfo.frozenAddr)) {
             num = record.amount * 2;
        } else if(block.number < record.unlockHeight) {
            num = record.amount * 15 / 10;
        }

        // update vote record
        id2record[_recordID] = VoteRecord(_voterAddr, _dstAddr, amount, num, block.number);

        // update voter
        add4Voter(_voterAddr, _dstAddr, _recordID, amount, num);

        // update dst
        add4Dst(_dstAddr, _voterAddr, _recordID, amount, num);

        // freeze record
        if(isSN(_dstAddr)) { // vote
            getAccountManager().setRecordVoteInfo(_recordID, _voterAddr, _dstAddr, getPropertyValue("record_snvote_lockday"));
            getSuperNode().changeVoteInfo(_dstAddr, _voterAddr, _recordID, amount, num, 1);
            emit SNVOTE_VOTE(_voterAddr, _dstAddr, _recordID, num);
        } else { // approval
            emit SNVOTE_APPROVAL(_voterAddr, _dstAddr, _recordID, num);
        }
    }

    function remove4Voter(address _voterAddr, address _dstAddr, uint _recordID, uint _amount, uint _num) internal {
        // update detail
        bool flag = false;
        uint pos = 0;
        (flag, pos) = existDst4Voter(_voterAddr, _dstAddr);
        if(!flag) {
            return;
        }

        // remove record id
        VoteDetail storage detail = voter2details[_voterAddr][_dstAddr];
        uint[] storage recordIDs = detail.recordIDs;
        flag = false;
        pos = 0;
        for(uint i = 0; i < recordIDs.length; i++) {
            if(recordIDs[i] == _recordID) {
                flag = true;
                pos = i;
                break;
            }
        }
        if(!flag) {
            return;
        }
        recordIDs[pos] = recordIDs[recordIDs.length - 1];
        recordIDs.pop();
        if(recordIDs.length == 0) {
            // remove detail
            delete voter2details[_voterAddr][_dstAddr];
        } else {
            // remove amount & votenum
            detail.totalAmount -= _amount;
            detail.totalNum -= _num;
        }

        // update total amount
        if(voter2amount[_voterAddr] <= _amount) {
            voter2amount[_voterAddr] = 0;
        } else {
            voter2amount[_voterAddr] -= _amount;
        }

        // update total votenum
        if(voter2num[_voterAddr] <= _num) {
            voter2num[_voterAddr] = 0;
        } else {
            voter2num[_voterAddr] -= _num;
        }

        // update dst list
        if(recordIDs.length == 0) {
            flag = false;
            pos = 0;
            (flag, pos) = existDst4Voter(_voterAddr, _dstAddr);
            if(flag) {
                address[] storage dsts = voter2dsts[_voterAddr];
                dsts[pos] = dsts[dsts.length - 1];
                dsts.pop();
            }
        }

        // update record id list
        flag = false;
        pos = 0;
        (flag, pos) = existID4Voter(_voterAddr, _recordID);
        if(flag) {
            uint[] storage ids = voter2ids[_voterAddr];
            ids[pos] = ids[ids.length - 1];
            ids.pop();
        }
    }

    function remove4Dst(address _dstAddr, address _voterAddr, uint _recordID, uint _amount, uint _num) internal {
        // update detail
        bool flag = false;
        uint pos = 0;
        (flag, pos) = existVoter4Dst(_dstAddr, _voterAddr);
        if(!flag) {
            return;
        }

        // remove record id
        VoteDetail storage detail = dst2details[_dstAddr][_voterAddr];
        uint[] storage recordIDs = detail.recordIDs;
        flag = false;
        pos = 0;
        for(uint i = 0; i < recordIDs.length; i++) {
            if(recordIDs[i] == _recordID) {
                flag = true;
                pos = i;
                break;
            }
        }
        if(!flag) {
            return;
        }
        recordIDs[pos] = recordIDs[recordIDs.length - 1];
        recordIDs.pop();
        if(recordIDs.length == 0) {
            // remove detail
            delete dst2details[_dstAddr][_voterAddr];
        } else {
            // remove amount & votenum
            detail.totalAmount -= _amount;
            detail.totalNum -= _num;
        }

        // update total amount
        if(dst2amount[_dstAddr] <= _amount) {
            dst2amount[_dstAddr] = 0;
        } else {
            dst2amount[_dstAddr] -= _amount;
        }

        // update total votenum
        if(dst2num[_dstAddr] <= _num) {
            dst2num[_dstAddr] = 0;
        } else {
            dst2num[_dstAddr] -= _num;
        }
        
        // update voter list
        if(recordIDs.length == 0) {
            flag = false;
            pos = 0;
            (flag, pos) = existVoter4Dst(_dstAddr, _voterAddr);
            if(flag) {
                address[] storage voters = dst2voters[_dstAddr];
                voters[pos] = voters[voters.length - 1];
                voters.pop();
            }
        }

        // update record id list
        flag = false;
        pos = 0;
        (flag, pos) = existID4Dst(_dstAddr, _recordID);
        if(flag) {
            uint[] storage ids = dst2ids[_dstAddr];
            ids[pos] = ids[ids.length - 1];
            ids.pop();
        }
    }

    function remove(address _voterAddr, uint _recordID) internal {
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_recordID);
        require(record.addr == _voterAddr, "caller isn't owner of record");

        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_recordID);
        require(block.number >= useinfo.releaseHeight, "record is voted, need wait for release");

        VoteRecord memory voteRecord = id2record[_recordID];
        address dstAddr = voteRecord.dstAddr;
        if(dstAddr == address(0) || voteRecord.voterAddr != _voterAddr) {
            return;
        }

        uint amount = voteRecord.amount;
        uint num = voteRecord.num;

        // update voter
        remove4Voter(_voterAddr, dstAddr, _recordID, amount, num);

        // update dst
        remove4Dst(dstAddr, _voterAddr, _recordID, amount, num);

        // remove vote record
        delete id2record[_recordID];

        // unfreeze record
        if(isSN(dstAddr)) { // vote
            getAccountManager().setRecordVoteInfo(_recordID, _voterAddr, dstAddr, 0);
            getSuperNode().changeVoteInfo(dstAddr, _voterAddr, _recordID, amount, num, 0);
            emit SNVOTE_REMOVE_VOTE(_voterAddr, dstAddr, _recordID, num);
        } else { // proxy
            emit SNVOTE_REMOVE_APPROVAL(_voterAddr, dstAddr, _recordID, num);
        }
    }
}