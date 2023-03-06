// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/ISMNVote.sol";
import "./interfaces/IAccountManager.sol";
import "./utils/SafeMath.sol";

contract SMNVote is ISMNVote, System {
    using SafeMath for uint256;

    mapping(bytes20 => SMNVoteRecord) id2record; // record to supermasternode or proxy vote
    mapping(address => SMNVoteDetail) voter2detail; // voter to supermasternode or proxy list
    mapping(address => uint) dst2amount; // supermasternode or proxy to total voter amount
    mapping(address => uint) dst2num; // supermasternode or proxy to total vote number
    mapping(address => address[]) dst2voters; // supermasternode or proxy to voter list
    mapping(address => bytes20[]) dst2records; // supermasternode or proxy to record list
    mapping(bytes20 => uint) record2index; // record to index of dst2records

    function vote(address _smnAddr, bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            vote(_smnAddr, _recordIDs[i]);
        }
    }

    function vote(address _smnAddr, bytes20 _recordID) public {
        require(!isSMN(msg.sender), "caller can't be supermasternode");
        require(isSMN(_smnAddr), "invalid supermasternode");
        require(id2record[_recordID].voterAddr == address(0), "record has been used");
        addVoteOrProxy(msg.sender, _smnAddr, _recordID);
    }

    function removeVote(bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            removeVote(_recordIDs[i]);
        }
    }

    function removeVote(bytes20 _recordID) public {
        if(id2record[_recordID].voterAddr != msg.sender) {
            return;
        }
        removeVoteOrProxy(msg.sender, _recordID);
    }

    function removeRecord(bytes20 _recordID) public {
        if(id2record[_recordID].voterAddr != msg.sender) {
            return;
        }
        removeVoteOrProxy(msg.sender, _recordID);
    }

    function decreaseRecord(bytes20 _recordID, uint _amount, uint _num) public {
        if(id2record[_recordID].voterAddr != msg.sender) {
            return;
        }
        decreaseVoteOrProxy(_recordID, _amount, _num);
    }

    function proxyVote(address _smnAddr) public {
        require(isMN(msg.sender), "caller isn't proxy");
        require(isSMN(_smnAddr), "invalid supermasternode");
        bytes20 recordID;
        address voterAddr;
        for(uint i = 0; i < dst2records[msg.sender].length; i++) {
            recordID = dst2records[msg.sender][i];
            voterAddr = id2record[recordID].voterAddr;
            removeVoteOrProxy(voterAddr, recordID); // remove proxy
            addVoteOrProxy(voterAddr, _smnAddr, recordID); // add vote
        }
    }

    function approval(address _proxyAddr, bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            approval(_proxyAddr, _recordIDs[i]);
        }
    }

    function approval(address _proxyAddr, bytes20 _recordID) public {
        require(!isSMN(msg.sender), "caller can't be supermasternode");
        require(isMN(_proxyAddr), "proxy isn't masternode");
        require(id2record[_recordID].voterAddr == address(0), "record has been used");
        addVoteOrProxy(msg.sender, _proxyAddr, _recordID);
    }

    function removeApproval(bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            removeApproval(_recordIDs[i]);
        }
    }

    function removeApproval(bytes20 _recordID) public {
        if(id2record[_recordID].voterAddr != msg.sender) {
            return;
        }
        removeVoteOrProxy(msg.sender, _recordID);
    }

    function getVotedSMN4Voter() public view returns (address[] memory retAddrs, uint[] memory retNums) {
        uint count = 0;
        for(uint i = 0; i < voter2detail[msg.sender].dstAddrs.length; i++) {
            if(isSMN(voter2detail[msg.sender].dstAddrs[i])) {
                count++;
            }
        }
        if(count == 0) {
            return (retAddrs, retNums);
        }
        uint index = 0;
        retAddrs = new address[](count);
        retNums = new uint[](count);
        for(uint i = 0; i < voter2detail[msg.sender].dstAddrs.length; i++) {
            if(isSMN(voter2detail[msg.sender].dstAddrs[i])) {
                retAddrs[index] = voter2detail[msg.sender].dstAddrs[i];
                retNums[index++] = voter2detail[msg.sender].totalNums[i];
            }
        }
        return (retAddrs, retNums);
    }

    function getVotedRecords4Voter() public view returns (bytes20[] memory retIDs) {
        SMNVoteDetail memory detail = voter2detail[msg.sender];
        uint count = 0;
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(isSMN(detail.dstAddrs[i])) {
                for(uint k = 0; k < detail.entries[i].length; k++) {
                    count++;
                }
            }
        }
        if(count != 0) {
            return retIDs;
        }
        retIDs = new bytes20[](count);
        uint index = 0;
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(isSMN(detail.dstAddrs[i])) {
                for(uint k = 0; k < detail.entries[i].length; k++) {
                    retIDs[index++] = detail.entries[i][k].recordID;
                }
            }
        }
    }

    function getVoters4SMN(address _smnAddr) public view returns (address[] memory retAddrs) {
        require(isSMN(_smnAddr), "invalid supermasternode");
        return dst2voters[_smnAddr];
    }

    function getVoteNum4SMN(address _smnAddr) public view returns (uint) {
        require(isSMN(_smnAddr), "invalid supermasternode");
        return dst2num[_smnAddr];
    }

    function getProxies4Voter() public view returns (address[] memory retAddrs, uint[] memory retNums) {
        uint count = 0;
        for(uint i = 0; i < voter2detail[msg.sender].dstAddrs.length; i++) {
            if(isMN(voter2detail[msg.sender].dstAddrs[i])) {
                count++;
            }
        }
        if(count == 0) {
            return (retAddrs, retNums);
        }
        uint index = 0;
        retAddrs = new address[](count);
        retNums = new uint[](count);
        for(uint i = 0; i < voter2detail[msg.sender].dstAddrs.length; i++) {
            if(isMN(voter2detail[msg.sender].dstAddrs[i])) {
                retAddrs[index] = voter2detail[msg.sender].dstAddrs[i];
                retNums[index++] = voter2detail[msg.sender].totalNums[i];
            }
        }
    }

    function getProxiedRecords4Voter() public view returns (bytes20[] memory retIDs) {
        SMNVoteDetail memory detail = voter2detail[msg.sender];
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
        retIDs = new bytes20[](count);
        uint index = 0;
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(isMN(detail.dstAddrs[i])) {
                for(uint k = 0; k < detail.entries[i].length; k++) {
                    retIDs[index++] = detail.entries[i][k].recordID;
                }
            }
        }
    }

    function getVoters4Proxy() public view returns (address[] memory) {
        require(isMN(msg.sender), "caller isn't proxy");
        return dst2voters[msg.sender];
    }

    function getVoteNum4Proxy() public view returns (uint) {
        require(isMN(msg.sender), "caller isn't proxy");
        return dst2num[msg.sender];
    }

    function existDstAddr(address _voterAddr, address _smnAddr) internal view returns (bool, uint) {
        SMNVoteDetail memory detail = voter2detail[_voterAddr];
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(detail.dstAddrs[i] == _smnAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existVoter(address _smnAddr, address _voterAddr) internal view returns (bool, uint) {
        address[] memory voters = dst2voters[_smnAddr];
        for(uint i = 0; i < voters.length; i++) {
            if(voters[i] == _voterAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existRecord(address _smnAddr, bytes20 _recordID) internal view returns (bool, uint) {
        bytes20[] memory recordIDs = dst2records[_smnAddr];
        for(uint i = 0; i < recordIDs.length; i++) {
            if(recordIDs[i] == _recordID) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function addVoteOrProxy(address _voterAddr, address _dstAddr, bytes20 _recordID) internal {
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        IAccountManager.AccountRecord memory record = am.getRecordByID(_recordID);
        if(block.number < record.bindInfo.unbindHeight) {
            return;
        }
        uint amount = record.amount;
        uint num = amount;
        if(isMN(msg.sender)) {
             num = record.amount.mul(2);
        } else if(record.unlockHeight != 0) {
            num = record.amount.mul(15).div(10);
        }

        SMNVoteDetail storage detail = voter2detail[_voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existDstAddr(_voterAddr, _dstAddr);
        if(exist) {
            // add amount & num
            detail.totalAmounts[pos] = detail.totalAmounts[pos].add(amount);
            detail.totalNums[pos] = detail.totalNums[pos].add(num);
            // add entry
            detail.entries[pos].push(SMNVoteEntry(_recordID, amount, num, block.number));
            // add history
            id2record[_recordID] = SMNVoteRecord(msg.sender, _dstAddr, detail.entries[pos].length - 1, block.number);
        } else {
            // add dst address
            detail.dstAddrs.push(_dstAddr);
            // add amount & num
            detail.totalAmounts.push(amount);
            detail.totalNums.push(num);
            // add entry
            detail.entries[0].push(SMNVoteEntry(_recordID, amount, num, block.number));
            // add history
            id2record[_recordID] = SMNVoteRecord(msg.sender, _dstAddr, 0, block.number);
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

        // bind
        if(isSMN(_dstAddr)) {
            am.setBindDay(_recordID, 7);
        }
    }

    function removeVoteOrProxy(address _voterAddr, bytes20 _recordID) internal {
        address dstAddr = id2record[_recordID].dstAddr;
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existDstAddr(_voterAddr, dstAddr);
        if(!exist) {
            return;
        }
        uint index = id2record[_recordID].index;

        SMNVoteDetail storage detail = voter2detail[_voterAddr];
        SMNVoteEntry[] storage entries = detail.entries[pos];
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

        // unbind
        if(isSMN(dstAddr)) {
            IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
            am.setBindDay(_recordID, 0);
        }
    }

    function decreaseVoteOrProxy(bytes20 _recordID, uint _amount, uint _num) internal {
        address dstAddr = id2record[_recordID].dstAddr;
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existDstAddr(msg.sender, dstAddr);
        if(!exist) {
            return;
        }
        uint index = id2record[_recordID].index;

        SMNVoteDetail storage detail = voter2detail[msg.sender];
        SMNVoteEntry[] storage entries = detail.entries[pos];
        require(entries[index].amount >= _amount, "invalid amount");
        require(entries[index].num >= _num, "invalid num");

        entries[index].amount = entries[index].amount.sub(_amount);
        entries[index].num = entries[index].num.sub(_num);
        if(entries[index].num == 0) {
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
                (exist, pos) = existVoter(dstAddr, msg.sender);
                if(exist) {
                    address[] storage voters = dst2voters[dstAddr];
                    voters[pos] = voters[voters.length - 1];
                    voters.pop();
                }
            } else {
                // decrease vote amount & num
                detail.totalAmounts[pos] = detail.totalAmounts[pos].sub(entries[index].amount);
                detail.totalNums[pos] = detail.totalNums[pos].sub(entries[index].num);
            }
        }

        if(dst2num[dstAddr] > _num) {
            dst2amount[dstAddr] = dst2amount[dstAddr].sub(_amount);
            dst2num[dstAddr] = dst2num[dstAddr].sub(_num);
        } else {
            dst2amount[dstAddr] = 0;
            dst2num[dstAddr] = 0;
        }
    }
}