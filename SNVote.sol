// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/ISNVote.sol";
import "./interfaces/IAccountManager.sol";
import "./utils/SafeMath.sol";

contract SNVote is ISNVote, System {
    using SafeMath for uint256;

    mapping(uint => SNVoteRecord) id2record; // record to supernode or proxy vote
    mapping(address => SNVoteDetail) voter2detail; // voter to supernode or proxy list
    mapping(address => uint) dst2amount; // supernode or proxy to total voter amount
    mapping(address => uint) dst2num; // supernode or proxy to total vote number
    mapping(address => address[]) dst2voters; // supernode or proxy to voter list
    mapping(address => uint[]) dst2records; // supernode or proxy to record list
    mapping(uint => uint) record2index; // record to index of dst2records

    function voteOrApproval(bool _isVote, address _dstAddr, uint[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            voteOrApproval(_isVote, _dstAddr, _recordIDs[i]);
        }
    }

    function voteOrApproval(bool _isVote, address _dstAddr, uint _recordID) public {
        require(!isSN(msg.sender), "caller can't be supernode");
        if(_isVote) {
            require(isSN(_dstAddr), "invalid supernode address");
        } else {
            require(isMN(_dstAddr), "invalid proxy address");
        }
        require(id2record[_recordID].voterAddr == address(0), "record has been used");
        remove(msg.sender, _recordID);
        add(msg.sender, _dstAddr, _recordID);
    }

    function removeVoteOrApproval(uint[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            removeVoteOrApproval(_recordIDs[i]);
        }
    }

    function removeVoteOrApproval(uint _recordID) public {
        if(id2record[_recordID].voterAddr != msg.sender) {
            return;
        }
        remove(msg.sender, _recordID);
    }

    function proxyVote(address _snAddr) public {
        require(isMN(msg.sender), "caller isn't proxy");
        require(isSN(_snAddr), "invalid supernode");
        uint recordID;
        address voterAddr;
        for(uint i = 0; i < dst2records[msg.sender].length; i++) {
            recordID = dst2records[msg.sender][i];
            voterAddr = id2record[recordID].voterAddr;
            remove(voterAddr, recordID); // remove vote or approval
            add(voterAddr, _snAddr, recordID); // add vote
        }
    }

    function getVotedSN4Voter(address _voterAddr) public view returns (address[] memory retAddrs, uint[] memory retNums) {
        uint count = 0;
        for(uint i = 0; i < voter2detail[_voterAddr].dstAddrs.length; i++) {
            if(isSN(voter2detail[_voterAddr].dstAddrs[i])) {
                count++;
            }
        }
        if(count == 0) {
            return (retAddrs, retNums);
        }
        uint index = 0;
        retAddrs = new address[](count);
        retNums = new uint[](count);
        for(uint i = 0; i < voter2detail[_voterAddr].dstAddrs.length; i++) {
            if(isSN(voter2detail[_voterAddr].dstAddrs[i])) {
                retAddrs[index] = voter2detail[_voterAddr].dstAddrs[i];
                retNums[index++] = voter2detail[_voterAddr].totalNums[i];
            }
        }
        return (retAddrs, retNums);
    }

    function getVotedRecords4Voter(address _voterAddr) public view returns (uint[] memory retIDs) {
        SNVoteDetail memory detail = voter2detail[_voterAddr];
        uint count = 0;
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(isSN(detail.dstAddrs[i])) {
                for(uint k = 0; k < detail.entries[i].length; k++) {
                    count++;
                }
            }
        }
        if(count != 0) {
            return retIDs;
        }
        retIDs = new uint[](count);
        uint index = 0;
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(isSN(detail.dstAddrs[i])) {
                for(uint k = 0; k < detail.entries[i].length; k++) {
                    retIDs[index++] = detail.entries[i][k].recordID;
                }
            }
        }
    }

    function getVoters4SN(address _snAddr) public view returns (address[] memory retAddrs) {
        require(isSN(_snAddr), "invalid supernode");
        return dst2voters[_snAddr];
    }

    function getVoteNum4SN(address _snAddr) public view returns (uint) {
        require(isSN(_snAddr), "invalid supernode");
        return dst2num[_snAddr];
    }

    function getProxies4Voter(address _voterAddr) public view returns (address[] memory retAddrs, uint[] memory retNums) {
        uint count = 0;
        for(uint i = 0; i < voter2detail[_voterAddr].dstAddrs.length; i++) {
            if(isMN(voter2detail[_voterAddr].dstAddrs[i])) {
                count++;
            }
        }
        if(count == 0) {
            return (retAddrs, retNums);
        }
        uint index = 0;
        retAddrs = new address[](count);
        retNums = new uint[](count);
        for(uint i = 0; i < voter2detail[_voterAddr].dstAddrs.length; i++) {
            if(isMN(voter2detail[_voterAddr].dstAddrs[i])) {
                retAddrs[index] = voter2detail[_voterAddr].dstAddrs[i];
                retNums[index++] = voter2detail[_voterAddr].totalNums[i];
            }
        }
    }

    function getProxiedRecords4Voter(address _voterAddr) public view returns (uint[] memory retIDs) {
        SNVoteDetail memory detail = voter2detail[_voterAddr];
        uint count = 0;
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(isMN(detail.dstAddrs[i])) {
                for(uint k = 0; k < detail.entries[i].length; k++) {
                    count++;
                }
            }
        }
        if(count == 0) {
            return retIDs;
        }
        retIDs = new uint[](count);
        uint index = 0;
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(isMN(detail.dstAddrs[i])) {
                for(uint k = 0; k < detail.entries[i].length; k++) {
                    retIDs[index++] = detail.entries[i][k].recordID;
                }
            }
        }
    }

    function getVoters4Proxy(address _proxyAddr) public view returns (address[] memory) {
        require(isMN(_proxyAddr), "caller isn't proxy");
        return dst2voters[_proxyAddr];
    }

    function getVoteNum4Proxy(address _proxyAddr) public view returns (uint) {
        require(isMN(_proxyAddr), "caller isn't proxy");
        return dst2num[_proxyAddr];
    }

    function existDstAddr(address _voterAddr, address _snAddr) internal view returns (bool, uint) {
        SNVoteDetail memory detail = voter2detail[_voterAddr];
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(detail.dstAddrs[i] == _snAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existVoter(address _snAddr, address _voterAddr) internal view returns (bool, uint) {
        address[] memory voters = dst2voters[_snAddr];
        for(uint i = 0; i < voters.length; i++) {
            if(voters[i] == _voterAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existRecord(address _snAddr, uint _recordID) internal view returns (bool, uint) {
        uint[] memory recordIDs = dst2records[_snAddr];
        for(uint i = 0; i < recordIDs.length; i++) {
            if(recordIDs[i] == _recordID) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function add(address _voterAddr, address _dstAddr, uint _recordID) internal {
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        IAccountManager.AccountRecord memory record = am.getRecordByID(_recordID);
        IAccountManager.RecordUseInfo memory useinfo = am.getRecordUseInfo(_recordID);
        if(record.addr != _voterAddr || block.number < useinfo.unfreezeHeight) {
            return;
        }
        uint amount = record.amount;
        uint num = amount;
        if(isMN(useinfo.sepcialAddr)) {
             num = record.amount.mul(2);
        } else if(record.unlockHeight != 0) {
            num = record.amount.mul(15).div(10);
        }

        // vote or approval new dstAddr
        SNVoteDetail storage detail = voter2detail[_voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existDstAddr(_voterAddr, _dstAddr);
        if(exist) {
            // add amount & num
            detail.totalAmounts[pos] = detail.totalAmounts[pos].add(amount);
            detail.totalNums[pos] = detail.totalNums[pos].add(num);
            // add entry
            detail.entries[pos].push(SNVoteEntry(_recordID, amount, num, block.number));
            // add history
            id2record[_recordID] = SNVoteRecord(msg.sender, _dstAddr, detail.entries[pos].length - 1, block.number);
        } else {
            // add dst address
            detail.dstAddrs.push(_dstAddr);
            // add amount & num
            detail.totalAmounts.push(amount);
            detail.totalNums.push(num);
            // add entry
            detail.entries[0].push(SNVoteEntry(_recordID, amount, num, block.number));
            // add history
            id2record[_recordID] = SNVoteRecord(msg.sender, _dstAddr, 0, block.number);
        }

        // add total amount & total num
        dst2amount[_dstAddr] = dst2amount[_dstAddr].add(amount);
        dst2num[_dstAddr] = dst2num[_dstAddr].add(num);

        // add voter
        (exist, pos) = existVoter(_dstAddr, msg.sender);
        if(!exist) {
            dst2voters[_dstAddr].push(msg.sender);
        }

        // add record
        (exist, pos) = existRecord(_dstAddr, _recordID);
        if(!exist) {
            dst2records[_dstAddr].push(_recordID);
            record2index[_recordID] = dst2records[_dstAddr].length - 1;
        }

        // freeze
        if(isSN(_dstAddr)) {
            am.setRecordVote(_recordID, _dstAddr, 7);
            emit SNVOTE_VOTE(_voterAddr, _dstAddr, _recordID, num);
        } else {
            emit SNVOTE_APPROVAL(_voterAddr, _dstAddr, _recordID, num);
        }
    }

    function remove(address _voterAddr, uint _recordID) internal {
        address dstAddr = id2record[_recordID].dstAddr;
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existDstAddr(_voterAddr, dstAddr);
        if(!exist) {
            return;
        }
        uint index = id2record[_recordID].index;

        SNVoteDetail storage detail = voter2detail[_voterAddr];
        SNVoteEntry[] storage entries = detail.entries[pos];
        uint amount = entries[index].amount;
        uint num = entries[index].num;

        // remove amount & number
        dst2amount[dstAddr] = dst2amount[dstAddr].sub(amount);
        dst2num[dstAddr] = dst2num[dstAddr].sub(num);
        // remove history
        id2record[entries[entries.length - 1].recordID].index = index;
        delete id2record[_recordID];
        // remove entry
        entries[index] = entries[entries.length - 1];
        entries.pop();
        if(entries.length == 0) {
            // remove total amount & total num
            detail.totalAmounts[pos] = detail.totalAmounts[detail.totalAmounts.length - 1];
            detail.totalAmounts.pop();
            detail.totalNums[pos] = detail.totalNums[detail.totalNums.length - 1];
            detail.totalNums.pop();
            // remove dst address
            detail.dstAddrs[pos] = detail.dstAddrs[detail.dstAddrs.length -1];
            detail.dstAddrs.pop();
            // remove entry
            detail.entries[pos] = detail.entries[detail.entries.length -1];
            detail.entries.pop();
            // remove voter
            (exist, pos) = existVoter(dstAddr, _voterAddr);
            if(exist) {
                address[] storage voters = dst2voters[dstAddr];
                voters[pos] = voters[voters.length - 1];
                voters.pop();
            }
        } else {
            // decrease vote amount & num
            detail.totalAmounts[pos] = detail.totalAmounts[pos].sub(amount);
            detail.totalNums[pos] = detail.totalNums[pos].sub(num);
        }

        // unfreeze
        if(isSN(dstAddr)) {
            IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
            am.setRecordVote(_recordID, dstAddr, 0);
            emit SNVOTE_REMOVE_VOTE(_voterAddr, dstAddr, _recordID, num);
        } else {
            emit SNVOTE_REMOVE_APPROVAL(_voterAddr, dstAddr, _recordID, num);
        }
    }
}