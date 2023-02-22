// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/ISMNVote.sol";
import "./interfaces/IAccountManager.sol";
import "./utils/SafeMath.sol";

contract SMNVote is ISMNVote, System {
    using SafeMath for uint256;

    mapping(bytes20 => SMNVoteRecord) record2vote; // record to supermasternode vote
    mapping(address => SMNVoteDetail) voter2smns; // voter to supermasternode list
    mapping(address => uint) smn2num; // supermasternode to total vote number
    mapping(address => uint) smn2amount; // supermasternode to total vote amount
    mapping(address => address[]) smn2voters; // supermasternode to voter list

    mapping(bytes20 => SMNVoteProxyRecord) record2proxy; // record to proxy
    mapping(address => SMNVoteProxyDetail) voter2proxies; // voter to proxy list
    mapping(address => uint) proxy2num; // proxy to total vote number
    mapping(address => uint) proxy2amount; // proxy to total vote amount
    mapping(address => address[]) proxy2voters; // proxy to voter list
    mapping(address => bytes20[]) proxy2recordIDs; // proxy to record list
    mapping(bytes20 => uint) proxiedRecord2index; // record to index of proxy2recordIDs

    function vote(address _smnAddr, bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            vote(msg.sender, _smnAddr, _recordIDs[i]);
        }
    }

    function vote(address _smnAddr, bytes20 _recordID) public {
        vote(msg.sender, _smnAddr, _recordID);
    }

    function removeVote(bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            removeVote(_recordIDs[i]);
        }
    }

    function removeVote(bytes20 _recordID) public {
        if(record2vote[_recordID].voterAddr != msg.sender) {
            return;
        }

        SMNVoteDetail storage detail = voter2smns[msg.sender];
        address smnAddr = record2vote[_recordID].smnAddr;
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existVotedSMN(msg.sender, smnAddr);
        if(!exist) {
            return;
        }

        SMNVoteEntry[] storage entries = detail.entries[pos];
        uint index = record2vote[_recordID].index;
        uint amount = entries[index].amount;
        uint num = entries[index].num;

        // remove vote amount & number
        smn2amount[smnAddr] = smn2amount[smnAddr].sub(amount);
        smn2num[smnAddr] = smn2num[smnAddr].sub(num);

        // remove record id
        record2vote[entries[entries.length - 1].recordID].index = index;
        delete record2vote[_recordID];
        entries[index] = entries[entries.length - 1];
        entries.pop();
        if(entries.length == 0) {
            // remove total amounts & nums
            detail.totalAmounts[pos] = detail.totalAmounts[detail.totalAmounts.length - 1];
            detail.totalAmounts.pop();
            detail.totalNums[pos] = detail.totalNums[detail.totalNums.length - 1];
            detail.totalNums.pop();
            // remove voted smn
            detail.smnAddrs[pos] = detail.smnAddrs[detail.smnAddrs.length -1];
            detail.smnAddrs.pop();
            // remove vote entry
            detail.entries[pos] = detail.entries[detail.entries.length -1];
            detail.entries.pop();
            // remove voter
            (exist, pos) = existVoter(smnAddr, msg.sender);
            if(exist) {
                address[] storage voters = smn2voters[smnAddr];
                voters[pos] = voters[voters.length - 1];
                voters.pop();
            }
        } else {
            // decrease vote amount & num
            detail.totalAmounts[pos] = detail.totalAmounts[pos].sub(amount);
            detail.totalNums[pos] = detail.totalNums[pos].sub(num);
        }
    }

    function DecreaseVoteNum(bytes20 _recordID, uint _amount, uint _num) public {
        if(record2vote[_recordID].voterAddr != msg.sender) {
            return;
        }

        SMNVoteDetail storage detail = voter2smns[msg.sender];
        address smnAddr = record2vote[_recordID].smnAddr;
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existVotedSMN(msg.sender, smnAddr);
        if(!exist) {
            return;
        }

        SMNVoteEntry[] storage entries = detail.entries[pos];
        uint index = record2vote[_recordID].index;
        require(entries[index].amount >= _amount, "invalid vote amount");
        require(entries[index].num >= _num, "invalid vote num");

        if(entries[index].num > _num) {
            entries[index].amount = entries[index].amount.sub(_amount);
            entries[index].num = entries[index].num.sub(_num);
        } else {
            record2vote[entries[entries.length - 1].recordID].index = index;
            delete record2vote[_recordID];
            entries[index] = entries[entries.length - 1];
            entries.pop();
            if(entries.length == 0) {
                // remove total amounts & nums
                detail.totalAmounts[pos] = detail.totalAmounts[detail.totalAmounts.length - 1];
                detail.totalAmounts.pop();
                detail.totalNums[pos] = detail.totalNums[detail.totalNums.length - 1];
                detail.totalNums.pop();
                // remove voted smn
                detail.smnAddrs[pos] = detail.smnAddrs[detail.smnAddrs.length -1];
                detail.smnAddrs.pop();
                // remove vote entry
                detail.entries[pos] = detail.entries[detail.entries.length -1];
                detail.entries.pop();
                // remove voter
                (exist, pos) = existVoter(smnAddr, msg.sender);
                if(exist) {
                    address[] storage voters = smn2voters[smnAddr];
                    voters[pos] = voters[voters.length - 1];
                    voters.pop();
                }
            } else {
                // decrease vote amount & num
                detail.totalAmounts[pos] = detail.totalAmounts[pos].sub(_amount);
                detail.totalNums[pos] = detail.totalNums[pos].sub(_num);
            }
        }

        if(smn2num[smnAddr] > _num) {
            smn2amount[smnAddr] = smn2amount[smnAddr].sub(_amount);
            smn2num[smnAddr] = smn2num[smnAddr].sub(_num);
        } else {
            smn2amount[smnAddr] = 0;
            smn2num[smnAddr] = 0;
        }
    }

    function proxyVote(address _smnAddr) public {
        for(uint i = 0; i < proxy2recordIDs[msg.sender].length; i++) {
            proxyVote(_smnAddr, proxy2recordIDs[msg.sender][i]);
        }
    }

    function approval(address _proxyAddr, bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            approval(_proxyAddr, _recordIDs[i]);
        }
    }

    function approval(address _proxyAddr, bytes20 _recordID) public {
        require(isMN(_proxyAddr), "proxy address isn't masternode");
        require(record2proxy[_recordID].voterAddr == address(0), "record id has been proxied");
        require(record2proxy[_recordID].proxyAddr == _proxyAddr, "proxy address isn't matched with reocrd id");
        uint amount;
        uint num;
        (amount, num) = calcVoteInfo(_recordID);

        SMNVoteProxyDetail storage detail = voter2proxies[msg.sender];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existProxy(msg.sender, _proxyAddr);
        if(exist) {
            // add total proxy
            detail.totalAmounts[pos] = detail.totalAmounts[pos].add(amount);
            detail.totalNums[pos] = detail.totalNums[pos].add(num);
            // add proxy entry
            detail.entries[pos].push(SMNVoteProxyEntry(_recordID, amount, num, block.number));
            // add record detail
            record2proxy[_recordID] = SMNVoteProxyRecord(msg.sender, _proxyAddr, detail.entries[pos].length - 1, block.number);
        } else {
            detail.proxyAddrs.push(_proxyAddr);
            detail.totalAmounts.push(amount);
            detail.totalNums.push(num);
            detail.entries[0].push(SMNVoteProxyEntry(_recordID, amount, num, block.number));
            // add record detail
            record2proxy[_recordID] = SMNVoteProxyRecord(msg.sender, _proxyAddr, 0, block.number);
        }

        (exist, pos) = existApproval(_proxyAddr, msg.sender);
        if(!exist) {
            proxy2voters[_proxyAddr].push(msg.sender);
        }
        proxy2amount[_proxyAddr] = proxy2num[_proxyAddr].add(amount);
        proxy2num[_proxyAddr] = proxy2num[_proxyAddr].add(num);
        proxy2recordIDs[_proxyAddr].push(_recordID);
        proxiedRecord2index[_recordID] = proxy2recordIDs[_proxyAddr].length - 1;
    }

    function removeApproval(bytes20[] memory _recordIDs) public {
        for(uint i = 0; i < _recordIDs.length; i++) {
            removeApproval(_recordIDs[i]);
        }
    }

    // remove specify vote records
    function removeApproval(bytes20 _recordID) public {
        if(record2vote[_recordID].voterAddr != msg.sender) {
            return;
        }
        removeApproval(record2proxy[_recordID].voterAddr, record2proxy[_recordID].proxyAddr, _recordID);
    }

    function DecreaseApprovalNum(bytes20 _recordID, uint _amount, uint _num) public {
        if(record2vote[_recordID].voterAddr != msg.sender) {
            return;
        }

        SMNVoteProxyDetail storage detail = voter2proxies[msg.sender];
        address proxyAddr = record2proxy[_recordID].proxyAddr;
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existProxy(msg.sender, proxyAddr);
        if(!exist) {
            return;
        }

        SMNVoteProxyEntry[] storage entries = detail.entries[pos];
        uint index = record2proxy[_recordID].index;
        require(entries[index].amount >= _amount, "invalid proxied amount");
        require(entries[index].num >= _num, "invalid proxied num");

        if(entries[index].num > _num) {
            entries[index].amount = entries[index].amount.sub(_amount);
            entries[index].num = entries[index].num.sub(_num);
        } else {
            record2proxy[entries[entries.length - 1].recordID].index = index;
            delete record2proxy[_recordID];
            entries[index] = entries[entries.length - 1];
            entries.pop();
            if(entries.length == 0) {
                // remove total amounts & nums
                detail.totalAmounts[pos] = detail.totalAmounts[detail.totalAmounts.length - 1];
                detail.totalAmounts.pop();
                detail.totalNums[pos] = detail.totalNums[detail.totalNums.length - 1];
                detail.totalNums.pop();
                // remove proxied smn
                detail.proxyAddrs[pos] = detail.proxyAddrs[detail.proxyAddrs.length -1];
                detail.proxyAddrs.pop();
                // remove proxied entry
                detail.entries[pos] = detail.entries[detail.entries.length -1];
                detail.entries.pop();
                // remove voter
                (exist, pos) = existApproval(proxyAddr, msg.sender);
                if(exist) {
                    address[] storage voters = proxy2voters[proxyAddr];
                    voters[pos] = voters[voters.length - 1];
                    voters.pop();
                }
            } else {
                // decrease proxied amount & num
                detail.totalAmounts[pos] = detail.totalAmounts[pos].sub(_amount);
                detail.totalNums[pos] = detail.totalNums[pos].sub(_num);
            }
        }

        if(proxy2num[proxyAddr] > _num) {
            proxy2amount[proxyAddr] = proxy2amount[proxyAddr].sub(_amount);
            proxy2num[proxyAddr] = proxy2num[proxyAddr].sub(_num);
        } else {
            proxy2amount[proxyAddr] = 0;
            proxy2num[proxyAddr] = 0;
        }
    }

    function getVotedSMN() public view returns (address[] memory, uint[] memory) {
        return (voter2smns[msg.sender].smnAddrs, voter2smns[msg.sender].totalNums);
    }

    function getVotedRecords() public view returns (bytes20[] memory recordIDs) {
        SMNVoteDetail memory detail = voter2smns[msg.sender];
        uint count = 0;
        for(uint i = 0; i < detail.smnAddrs.length; i++) {
            for(uint k = 0; k < detail.entries[i].length; k++) {
                count++;
            }
        }
        if(count == 0) {
            return recordIDs;
        }
        recordIDs = new bytes20[](count);
        uint index = 0;
        for(uint i = 0; i < detail.smnAddrs.length; i++) {
            for(uint k = 0; k < detail.entries[i].length; k++) {
                recordIDs[index++] = detail.entries[i][k].recordID;
            }
        }
    }

    function getVoters(address _smnAddr) public view returns (address[] memory) {
        return smn2voters[_smnAddr];
    }

    function getVoteNum(address _smnAddr) public view returns (uint) {
        return smn2num[_smnAddr];
    }

    function getApproval() public view returns (address[] memory, uint[] memory) {
        return (voter2proxies[msg.sender].proxyAddrs, voter2proxies[msg.sender].totalNums);
    }

    function getApprovalRecords() public view returns (bytes20[] memory recordIDs) {
        SMNVoteProxyDetail memory detail = voter2proxies[msg.sender];
        uint count = 0;
        for(uint i = 0; i < detail.proxyAddrs.length; i++) {
            for(uint k = 0; k < detail.entries[i].length; k++) {
                count++;
            }
        }
        if(count == 0) {
            return recordIDs;
        }
        recordIDs = new bytes20[](count);
        uint index = 0;
        for(uint i = 0; i < detail.proxyAddrs.length; i++) {
            for(uint k = 0; k < detail.entries[i].length; k++) {
                recordIDs[index++] = detail.entries[i][k].recordID;
            }
        }
    }

    function getProxiedVoters() public view returns (address[] memory) {
        return proxy2voters[msg.sender];
    }

    function getProxiedVoteNum() public view returns (uint) {
        return proxy2num[msg.sender];
    }

    function existVotedSMN(address _voterAddr, address _smnAddr) internal view returns (bool, uint) {
        SMNVoteDetail memory detail = voter2smns[_voterAddr];
        for(uint i = 0; i < detail.smnAddrs.length; i++) {
            if(detail.smnAddrs[i] == _smnAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existVoter(address _smnAddr, address _voterAddr) internal view returns (bool, uint) {
        address[] memory voters = smn2voters[_smnAddr];
        for(uint i = 0; i < voters.length; i++) {
            if(voters[i] == _voterAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existProxy(address _voterAddr, address _proxyAddr) internal view returns (bool, uint) {
        SMNVoteProxyDetail memory detail = voter2proxies[_voterAddr];
        for(uint i = 0; i < detail.proxyAddrs.length; i++) {
            if(detail.proxyAddrs[i] == _proxyAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existApproval(address _proxyAddr, address _voterAddr) internal view returns (bool, uint) {
        address[] memory voters = proxy2voters[_proxyAddr];
        for(uint i = 0; i < voters.length; i++) {
            if(voters[i] == _voterAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function calcVoteInfo(bytes20 _recordID) internal view returns (uint, uint) {
        IAccountManager am = IAccountManager(ACCOUNT_MANAGER_PROXY_ADDR);
        AccountRecord memory record = am.getRecordByID(_recordID);
        if(isMN(msg.sender)) {
            return (record.amount, record.amount.mul(2));
        } else if(record.unlockHeight != 0) {
            return (record.amount, record.amount.mul(15).div(10));
        }
        return (record.amount, record.amount);
    }

    function vote(address _voterAddr, address _smnAddr, bytes20 _recordID) internal {
        require(!isSMN(_voterAddr), "voter can't be a supermasternode");
        require(isSMN(_smnAddr), "target isn't supermasternode");
        require(record2vote[_recordID].voterAddr == address(0), "record id has used, can't vote repeated");
        uint amount;
        uint num;
        (amount, num) = calcVoteInfo(_recordID);

        SMNVoteDetail storage detail = voter2smns[_voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existVotedSMN(_voterAddr, _smnAddr);
        if(exist) {
            // add total
            detail.totalAmounts[pos] = detail.totalAmounts[pos].add(amount);
            detail.totalNums[pos] = detail.totalNums[pos].add(num);
            // add vote entry
            detail.entries[pos].push(SMNVoteEntry(_recordID, amount, num, block.number));
            // add record detail
            record2vote[_recordID] = SMNVoteRecord(msg.sender, _smnAddr, detail.entries[pos].length - 1, block.number);
        } else {
            detail.smnAddrs.push(_smnAddr);
            detail.totalAmounts.push(amount);
            detail.totalNums.push(num);
            detail.entries[0].push(SMNVoteEntry(_recordID, amount, num, block.number));
            // add record detail
            record2vote[_recordID] = SMNVoteRecord(msg.sender, _smnAddr, 0, block.number);
        }

        (exist, pos) = existVoter(_smnAddr, msg.sender);
        if(!exist) {
            smn2voters[msg.sender].push(msg.sender);
        }
        smn2amount[_smnAddr] = smn2amount[_smnAddr].add(amount);
        smn2num[_smnAddr] = smn2num[_smnAddr].add(num);
    }

    function proxyVote(address _smnAddr, bytes20 _recordID) internal {
        require(isSMN(_smnAddr), "target isn't supermasternode");
        SMNVoteProxyRecord memory proxiedRecord = record2proxy[_recordID];
        require(msg.sender == proxiedRecord.proxyAddr, "record's proxy address isn't caller");

        address voterAddr = proxiedRecord.voterAddr;
        SMNVoteProxyDetail storage proxyDetail = voter2proxies[voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existProxy(voterAddr, msg.sender);
        if(!exist) {
            return;
        }

        SMNVoteProxyEntry[] storage entries = proxyDetail.entries[pos];
        SMNVoteProxyEntry memory entry = entries[proxiedRecord.index];
        if(entry.recordID != _recordID) {
            return;
        }

        // vote
        vote(voterAddr, _smnAddr, entry.recordID);

        // remove proxied record
        removeApproval(voterAddr, msg.sender, _recordID);
    }

    function removeApproval(address _voterAddr, address _proxyAddr, bytes20 _recordID) internal {
        SMNVoteProxyDetail storage detail = voter2proxies[_voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existProxy(_voterAddr, _proxyAddr);
        if(!exist) {
            return;
        }

        SMNVoteProxyEntry[] storage entries = detail.entries[pos];
        uint index = record2proxy[_recordID].index;
        uint amount = entries[index].amount;
        uint num = entries[index].num;

        // remove proxied amount & number
        proxy2amount[_proxyAddr] = proxy2amount[_proxyAddr].sub(amount);
        proxy2num[_proxyAddr] = proxy2num[_proxyAddr].sub(num);

        // remove proxied record
        bytes20[] storage recordIDs = proxy2recordIDs[_proxyAddr];
        recordIDs[proxiedRecord2index[_recordID]] = recordIDs[recordIDs.length - 1];
        recordIDs.pop();
        delete proxiedRecord2index[_recordID];

        // remove record id
        record2proxy[entries[entries.length - 1].recordID].index = index;
        delete record2proxy[_recordID];
        entries[index] = entries[entries.length - 1];
        entries.pop();
        if(entries.length == 0) {
            // remove total amounts & nums
            detail.totalAmounts[pos] = detail.totalAmounts[detail.totalAmounts.length - 1];
            detail.totalAmounts.pop();
            detail.totalNums[pos] = detail.totalNums[detail.totalNums.length - 1];
            detail.totalNums.pop();
            // remove proxied smn
            detail.proxyAddrs[pos] = detail.proxyAddrs[detail.proxyAddrs.length -1];
            detail.proxyAddrs.pop();
            // remove proxied entry
            detail.entries[pos] = detail.entries[detail.entries.length -1];
            detail.entries.pop();
            // remove voter
            (exist, pos) = existApproval(_proxyAddr, _voterAddr);
            if(exist) {
                address[] storage voters = proxy2voters[_proxyAddr];
                voters[pos] = voters[voters.length - 1];
                voters.pop();
            }
        } else {
            // decrease proxied amount & num
            detail.totalAmounts[pos] = detail.totalAmounts[pos].sub(amount);
            detail.totalNums[pos] = detail.totalNums[pos].sub(num);
        }

    }
}