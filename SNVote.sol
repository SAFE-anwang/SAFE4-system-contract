// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

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

    uint allAmount; // all supernodes received amount
    uint allVoteNum; // all supernodes received voteNum
    uint allProxiedAmount; // all proxies received amount
    uint allProxiedVoteNum; // all proxies received voteNum

    event SNVOTE_VOTE(address _voterAddr, address _snAddr, uint _recordID, uint _voteNum);
    event SNVOTE_APPROVAL(address _voterAddr, address _proxyAddr, uint _recordID, uint _voteNum);
    event SNVOTE_REMOVE_VOTE(address _voterAddr, address _snAddr, uint _recordID, uint _voteNum);
    event SNVOTE_REMOVE_APPROVAL(address _voterAddr, address _proxyAddr, uint _recordID, uint _voteNum);

    function voteOrApproval(bool _isVote, address _dstAddr, uint[] memory _recordIDs) public override {
        require(!isSN(msg.sender), "supernode can't vote others");
        if(_isVote) {
            require(isValidSN(_dstAddr), "invalid supernode address");
        } else {
            require(isValidMN(_dstAddr), "invalid proxy address");
        }
        uint id;
        for(uint i; i < _recordIDs.length; i++) {
            id = _recordIDs[i];
            if(_recordIDs[i] == 0) {
                // generate new record id
                id = getAccountManager().moveID0(msg.sender);
            }
            remove(msg.sender, id);
            add(msg.sender, _dstAddr, id);
        }
    }

    function voteOrApprovalWithAmount(bool _isVote, address _dstAddr) public payable override {
        require(!isSN(msg.sender), "supernode can't vote others");
        if(_isVote) {
            require(isValidSN(_dstAddr), "invalid supernode address");
        } else {
            require(isValidMN(_dstAddr), "invalid proxy address");
        }
        uint recordID = getAccountManager().depositReturnNewID{value: msg.value}(msg.sender);
        add(msg.sender, _dstAddr, recordID);
    }

    function removeVoteOrApproval(uint[] memory _recordIDs) public override {
        require(!isSN(msg.sender), "supernode can't remove vote");
        for(uint i; i < _recordIDs.length; i++) {
            if(_recordIDs[i] == 0) {
                continue;
            }
            remove(msg.sender, _recordIDs[i]);
        }
    }

    function removeVoteOrApproval2(address _voterAddr, uint _recordID) public override onlyAmOrSnContract {
        if(_recordID == 0) {
            return;
        }
        remove(_voterAddr, _recordID);
    }

    function proxyVote(address _snAddr) public override {
        require(isValidMN(msg.sender), "invalid proxy");
        require(isValidSN(_snAddr), "invalid supernode");
        uint recordID;
        address voterAddr;
        uint[] memory ids = dst2ids[msg.sender];
        for(uint i; i < ids.length; i++) {
            recordID = ids[i];
            voterAddr = id2record[recordID].voterAddr;
            remove(voterAddr, recordID); // remove vote or approval
            add(voterAddr, _snAddr, recordID); // add vote
        }
    }

    function getAmount4Voter(address _voterAddr) public view override returns (uint) {
        return voter2amount[_voterAddr];
    }

    function getVoteNum4Voter(address _voterAddr) public view override returns (uint) {
        return voter2num[_voterAddr];
    }

    // get voter's supernode number
    function getSNNum4Voter(address _voterAddr) public view override returns (uint) {
        uint num;
        address[] memory dsts = voter2dsts[_voterAddr];
        for(uint i; i < dsts.length; i++) {
            if(isSN(dsts[i])) {
                num++;
            }
        }
        return num;
    }

    function getSNs4Voter(address _voterAddr, uint _start, uint _count) public view override returns (address[] memory, uint[] memory) {
        uint snNum = getSNNum4Voter(_voterAddr);
        require(_start < snNum, "invalid _start, must be in [0, getSNNum4Voter())");
        require(_count > 0 && _count <= 100, "max return 100 SNs");

        address[] memory tempAddrs = new address[](snNum);
        uint[] memory tempNums = new uint[](snNum);
        address[] memory dsts = voter2dsts[_voterAddr];
        uint index;
        for(uint i; i < dsts.length; i++) {
            if(isSN(dsts[i])) {
                tempAddrs[index] = dsts[i];
                tempNums[index++] = voter2details[_voterAddr][dsts[i]].totalNum;
            }
        }

        uint num = _count;
        if(_start + _count >= snNum) {
            num = snNum - _start;
        }
        address[] memory retAddrs = new address[](num);
        uint[] memory retNums = new uint[](num);
        for(uint i; i < num; i++) {
            retAddrs[i] = tempAddrs[i + _start];
            retNums[i] = tempNums[i + _start];
        }
        return(retAddrs, retNums);
    }

    function getProxyNum4Voter(address _voterAddr) public view override returns (uint) {
        uint num;
        address[] memory dsts = voter2dsts[_voterAddr];
        for(uint i; i < dsts.length; i++) {
            if(isMN(dsts[i])) {
                num++;
            }
        }
        return num;
    }

    function getProxies4Voter(address _voterAddr, uint _start, uint _count) public view override returns (address[] memory, uint[] memory) {
        uint proxyNum = getProxyNum4Voter(_voterAddr);
        require(_start < proxyNum, "invalid _start, must be in [0, getProxyNum4Voter())");
        require(_count > 0 && _count <= 100, "max return 100 proxies");

        address[] memory tempAddrs = new address[](proxyNum);
        uint[] memory tempNums = new uint[](proxyNum);
        address[] memory dsts = voter2dsts[_voterAddr];
        uint index;
        for(uint i; i < dsts.length; i++) {
            if(isMN(dsts[i])) {
                tempAddrs[index] = dsts[i];
                tempNums[index++] = voter2details[_voterAddr][dsts[i]].totalNum;
            }
        }

        uint num = _count;
        if(_start + _count >= proxyNum) {
            num = proxyNum - _start;
        }
        address[] memory retAddrs = new address[](num);
        uint[] memory retNums = new uint[](num);
        for(uint i; i < num; i++) {
            retAddrs[i] = tempAddrs[i + _start];
            retNums[i] = tempNums[i + _start];
        }
        return (retAddrs, retNums);
    }

    function getVotedIDNum4Voter(address _voterAddr) public view override returns (uint) {
        uint num;
        uint[] memory ids = voter2ids[_voterAddr];
        for(uint i; i < ids.length; i++) {
            if(isSN(id2record[ids[i]].dstAddr)) {
                num++;
            }
        }
        return num;
    }

    function getVotedIDs4Voter(address _voterAddr, uint _start, uint _count) public view override returns (uint[] memory) {
        uint idNum = getVotedIDNum4Voter(_voterAddr);
        require(_start < idNum, "invalid _start, must be in [0, getVotedIDNum4Voter())");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](idNum);
        uint[] memory ids = voter2ids[_voterAddr];
        uint index;
        for(uint i; i < ids.length; i++) {
            if(isSN(id2record[ids[i]].dstAddr)) {
                temp[index++] = ids[i];
            }
        }

        uint num = _count;
        if(_start + _count >= idNum) {
            num = idNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
        }
        return ret;
    }

    function getProxiedIDNum4Voter(address _voterAddr) public view override returns (uint) {
        uint num;
        uint[] memory ids = voter2ids[_voterAddr];
        for(uint i; i < ids.length; i++) {
            if(isMN(id2record[ids[i]].dstAddr)) {
                num++;
            }
        }
        return num;
    }

    function getProxiedIDs4Voter(address _voterAddr, uint _start, uint _count) public view override returns (uint[] memory) {
        uint idNum = getProxiedIDNum4Voter(_voterAddr);
        require(_start < idNum, "invalid _start, must be in [0, getProxiedIDNum4Voter())");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint[] memory temp = new uint[](idNum);
        uint[] memory ids = voter2ids[_voterAddr];
        uint index;
        for(uint i; i < ids.length; i++) {
            if(isMN(id2record[ids[i]].dstAddr)) {
                temp[index++] = ids[i];
            }
        }

        uint num = _count;
        if(_start + _count >= idNum) {
            num = idNum - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = temp[i + _start];
        }
        return ret;
    }

    function getTotalAmount(address _addr) public view override returns (uint) {
        return dst2amount[_addr];
    }

    function getTotalVoteNum(address _addr) public view override returns (uint) {
        return dst2num[_addr];
    }

    function getVoterNum(address _addr) public view override returns (uint) {
        return dst2voters[_addr].length;
    }

    function getVoters(address _addr, uint _start, uint _count) public view override returns (address[] memory, uint[] memory) {
        require(_start < dst2voters[_addr].length, "invalid _start, must be in [0, getVoterNum())");
        require(_count > 0 && _count <= 100, "max return 100 voters");

        address[] memory tempAddrs = dst2voters[_addr];
        uint[] memory tempNums = new uint[](tempAddrs.length);
        for(uint i; i < tempAddrs.length; i++) {
            tempNums[i] = dst2details[_addr][tempAddrs[i]].totalNum;
        }

        uint num = _count;
        if(_start + _count >= tempAddrs.length) {
            num = tempAddrs.length - _start;
        }
        address[] memory retAddrs = new address[](num);
        uint[] memory retNums = new uint[](num);
        for(uint i; i < num; i++) {
            retAddrs[i] = tempAddrs[i + _start];
            retNums[i] = tempNums[i + _start];
        }
        return (retAddrs, retNums);
    }

    function getIDNum(address _addr) public view override returns (uint) {
        return dst2ids[_addr].length;
    }

    function getIDs(address _addr, uint _start, uint _count) public view override returns (uint[] memory) {
        require(_start < dst2ids[_addr].length, "invalid _start, must be in [0, getIDNum())");
        require(_count > 0 && _count <= 100, "max return 100 ids");

        uint num = _count;
        if(_start + _count >= dst2ids[_addr].length) {
            num = dst2ids[_addr].length - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = dst2ids[_addr][i + _start];
        }
        return ret;
    }

    function getAllAmount() public view override returns (uint) {
        return allAmount;
    }

    function getAllVoteNum() public view override returns (uint) {
        return allVoteNum;
    }

    function getAllProxiedAmount() public view override returns (uint) {
        return allProxiedAmount;
    }

    function getAllProxiedVoteNum() public view override returns (uint) {
        return allProxiedVoteNum;
    }

    function existDst4Voter(address _voterAddr, address _dstAddr) internal view returns (bool, uint) {
        address[] memory dsts = voter2dsts[_voterAddr];
        for(uint i; i < dsts.length; i++) {
            if(dsts[i] == _dstAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existVoter4Dst(address _dstAddr, address _voterAddr) internal view returns (bool, uint) {
        address[] memory voters = dst2voters[_dstAddr];
        for(uint i; i < voters.length; i++) {
            if(voters[i] == _voterAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existID4Voter(address _voterAddr, uint _recordID) internal view returns (bool, uint) {
        uint[] memory recordIDs = voter2ids[_voterAddr];
        for(uint i; i < recordIDs.length; i++) {
            if(recordIDs[i] == _recordID) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existID4Dst(address _dstAddr, uint _recordID) internal view returns (bool, uint) {
        uint[] memory recordIDs = dst2ids[_dstAddr];
        for(uint i; i < recordIDs.length; i++) {
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
        bool flag;
        uint pos;
        (flag, pos) = existDst4Voter(_voterAddr, _dstAddr);
        if(!flag) {
            voter2dsts[_voterAddr].push(_dstAddr);
        }

        // update record list
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
        bool flag;
        uint pos;
        (flag, pos) = existVoter4Dst(_dstAddr, _voterAddr);
        if(!flag) {
            dst2voters[_dstAddr].push(_voterAddr);
        }

        // update record list
        (flag, pos) = existID4Dst(_dstAddr, _recordID);
        if(!flag) {
            dst2ids[_dstAddr].push(_recordID);
        }
    }

    function add(address _voterAddr, address _dstAddr, uint _recordID) internal {
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_recordID);
        if(record.addr != _voterAddr) {
            return;
        }

        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_recordID);
        if(block.number < useinfo.releaseHeight || isSN(useinfo.frozenAddr)) {
            return;
        }

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
            allAmount += amount;
            allVoteNum += num;
            getAccountManager().setRecordVoteInfo(_recordID, _dstAddr, getPropertyValue("record_snvote_lockday"));
            emit SNVOTE_VOTE(_voterAddr, _dstAddr, _recordID, num);
        } else { // approval
            allProxiedAmount += amount;
            allProxiedVoteNum += num;
            emit SNVOTE_APPROVAL(_voterAddr, _dstAddr, _recordID, num);
        }
    }

    function remove4Voter(address _voterAddr, address _dstAddr, uint _recordID, uint _amount, uint _num) internal {
        // update detail
        bool flag;
        uint pos;
        (flag, pos) = existDst4Voter(_voterAddr, _dstAddr);
        if(!flag) {
            return;
        }

        // remove record id
        VoteDetail storage detail = voter2details[_voterAddr][_dstAddr];
        uint[] storage recordIDs = detail.recordIDs;
        flag = false;
        pos = 0;
        for(uint i; i < recordIDs.length; i++) {
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
            (flag, pos) = existDst4Voter(_voterAddr, _dstAddr);
            if(flag) {
                address[] storage dsts = voter2dsts[_voterAddr];
                dsts[pos] = dsts[dsts.length - 1];
                dsts.pop();
            }
        }

        // update record id list
        (flag, pos) = existID4Voter(_voterAddr, _recordID);
        if(flag) {
            uint[] storage ids = voter2ids[_voterAddr];
            ids[pos] = ids[ids.length - 1];
            ids.pop();
        }
    }

    function remove4Dst(address _dstAddr, address _voterAddr, uint _recordID, uint _amount, uint _num) internal {
        // update detail
        bool flag;
        uint pos;
        (flag, pos) = existVoter4Dst(_dstAddr, _voterAddr);
        if(!flag) {
            return;
        }

        // remove record id
        VoteDetail storage detail = dst2details[_dstAddr][_voterAddr];
        uint[] storage recordIDs = detail.recordIDs;
        flag = false;
        pos = 0;
        for(uint i; i < recordIDs.length; i++) {
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
            (flag, pos) = existVoter4Dst(_dstAddr, _voterAddr);
            if(flag) {
                address[] storage voters = dst2voters[_dstAddr];
                voters[pos] = voters[voters.length - 1];
                voters.pop();
            }
        }

        // update record id list
        (flag, pos) = existID4Dst(_dstAddr, _recordID);
        if(flag) {
            uint[] storage ids = dst2ids[_dstAddr];
            ids[pos] = ids[ids.length - 1];
            ids.pop();
        }
    }

    function remove(address _voterAddr, uint _recordID) internal {
        IAccountManager.AccountRecord memory record = getAccountManager().getRecordByID(_recordID);
        if(record.addr != _voterAddr) {
            return;
        }

        IAccountManager.RecordUseInfo memory useinfo = getAccountManager().getRecordUseInfo(_recordID);
        if(block.number < useinfo.releaseHeight) {
            return;
        }

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
            allAmount -= amount;
            allVoteNum -= num;
            getAccountManager().setRecordVoteInfo(_recordID, address(0), 0);
            emit SNVOTE_REMOVE_VOTE(_voterAddr, dstAddr, _recordID, num);
        } else { // proxy
            allProxiedAmount -= amount;
            allProxiedVoteNum -= num;
            emit SNVOTE_REMOVE_APPROVAL(_voterAddr, dstAddr, _recordID, num);
        }
    }
}