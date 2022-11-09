// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SMNVoteProxy.sol";

contract SMNVote is SMNVoteProxy {
    mapping(bytes20 => SMNVoteLib.RecordInfo) record2vote;
    mapping(address => SMNVoteLib.Detail) voter2smns; // voter to supermasternode list
    mapping(address => uint) smn2num; // supermasternode to total vote number
    mapping(address => address[]) smn2voters; // supermasternode to voter list

    // vote for supermasternode
    function vote(address _voterAddr, address _smnAddr, bytes20 _recordID, uint _num) public {
        require(record2vote[_recordID].voterAddr == address(0), "record id has used, can't vote repeated");
        SMNVoteLib.Detail storage detail = voter2smns[_voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existSMN(_voterAddr, _smnAddr);
        if(exist) {
            // add total vote number
            detail.totals[pos] += _num;
            // add vote entry
            detail.entries[pos].push(SMNVoteLib.Entry(_recordID, _num, block.number));
            // add record detail
            record2vote[_recordID] = SMNVoteLib.RecordInfo(_voterAddr, _smnAddr, detail.entries[pos].length, block.number);
        } else {
            detail.dstAddrs.push(_smnAddr);
            detail.totals.push(_num);
            detail.entries[0].push(SMNVoteLib.Entry(_recordID, _num, block.number));
            // add record detail
            record2vote[_recordID] = SMNVoteLib.RecordInfo(_voterAddr, _smnAddr, 0, block.number);
        }

        address[] storage voters = smn2voters[_voterAddr];
        (exist, pos) = existVoter(_smnAddr, _voterAddr);
        if(!exist) {
            voters.push(_voterAddr);
        }
        smn2num[_smnAddr] += _num;
    }

    // remove all vote num
    function removeVote(address _voterAddr) public {
        SMNVoteLib.Detail storage detail = voter2smns[_voterAddr];
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            address smnAddr = detail.dstAddrs[i];

            // remove smn total vote number
            smn2num[smnAddr] -= detail.totals[i];

            // remove record id
            for(uint k = 0; k < detail.entries[i].length; k++) {
                delete record2vote[detail.entries[i][k].recordID];
            }

            // remove voted smn
            detail.dstAddrs[i] = detail.dstAddrs[detail.dstAddrs.length -1];
            detail.dstAddrs.pop();

            // remove vote total num
            detail.totals[i] = detail.totals[detail.totals.length -1];
            detail.totals.pop();

            // remove vote entry
            detail.entries[i] = detail.entries[detail.entries.length -1];
            detail.entries.pop();

            bool exist = false;
            uint pos = 0;
            (exist, pos) = existVoter(smnAddr, _voterAddr);
            if(exist) {
                address[] storage voters = smn2voters[smnAddr];
                voters[pos] = voters[voters.length - 1];
                voters.pop();
                if(voters.length == 0) {
                    delete smn2voters[smnAddr];
                    delete smn2num[smnAddr];
                }
            }
        }
        if(detail.dstAddrs.length == 0) {
            delete voter2smns[_voterAddr];
        }
    }

    // remove specify vote records
    function removeVote(address _voterAddr, bytes20[] memory _recordIDs) public {
        require(_recordIDs.length > 0, "invalid record ids");
        for(uint i = 0; i < _recordIDs.length; i++) {
            require(record2vote[_recordIDs[i]].voterAddr == _voterAddr, "voter address isn't matched with record ids");
        }

        SMNVoteLib.Detail storage detail = voter2smns[_voterAddr];
        for(uint i = 0; i < _recordIDs.length; i++) {
            bytes20 recordID = _recordIDs[i];
            address smnAddr = record2vote[recordID].dstAddr;

            bool exist = false;
            uint pos = 0;
            (exist, pos) = existSMN(_voterAddr, smnAddr);
            if(exist) {
                SMNVoteLib.Entry[] storage entries = detail.entries[pos];
                uint index = record2vote[recordID].index;
                uint num = entries[index].num;

                // remove vote number
                smn2num[smnAddr] -= num;
                if(smn2num[smnAddr] == 0) {
                    delete smn2num[smnAddr];
                }

                // remove record id
                record2vote[entries[entries.length - 1].recordID].index = index;
                delete record2vote[recordID];
                entries[index] = entries[entries.length - 1];
                entries.pop();
                if(entries.length == 0) {
                    // remove total amount
                    detail.totals[pos] = detail.totals[detail.totals.length - 1];
                    detail.totals.pop();
                    // remove voted smn
                    detail.dstAddrs[pos] = detail.dstAddrs[detail.dstAddrs.length -1];
                    detail.dstAddrs.pop();
                    // remove vote entry
                    detail.entries[pos] = detail.entries[detail.entries.length -1];
                    detail.entries.pop();
                    // remove voter
                    (exist, pos) = existVoter(smnAddr, _voterAddr);
                    if(exist) {
                        address[] storage voters = smn2voters[smnAddr];
                        voters[pos] = voters[voters.length - 1];
                        voters.pop();
                        if(voters.length == 0) {
                            delete smn2voters[smnAddr];
                        }
                    }
                } else {
                    // decrease vote num
                    detail.totals[pos] -= num;
                }
            }
        }
        if(detail.dstAddrs.length == 0) {
            delete voter2smns[_voterAddr];
        }
    }

    function proxyVote(address _proxyAddr, address _smnAddr) public {
        address[] storage voters = proxy2voters[_proxyAddr];
        for(uint i = 0; i < voters.length; i++) {
            address voterAddr = voters[i];
            SMNVoteLib.Detail storage proxyDetail = voter2proxies[voterAddr];
            bool exist = false;
            uint pos = 0;
            (exist, pos) = existProxy(voterAddr, _proxyAddr);
            if(!exist) {
                continue;
            }
            SMNVoteLib.Entry[] storage entries = proxyDetail.entries[i];
            for(uint j = 0; j < entries.length; j++) {
                SMNVoteLib.Entry memory entry = entries[j];
                vote(voterAddr, _smnAddr, entry.recordID, entry.num);
                delete record2proxy[entry.recordID];
            }
            proxyDetail.totals[i] = 0;
            delete voter2proxies[voterAddr];
        }
        delete proxy2voters[_proxyAddr];
    }

    function getVotedSMN(address _voterAddr) public view returns (address[] memory, uint[] memory) {
        return (voter2smns[_voterAddr].dstAddrs, voter2smns[_voterAddr].totals);
    }

    function getVoters(address _smnAddr) public view returns (address[] memory) {
        return smn2voters[_smnAddr];
    }

    function getVoteNum(address _smnAddr) public view returns (uint) {
        return smn2num[_smnAddr];
    }

    /**************************************** internal ****************************************/
    function existSMN(address _voterAddr, address _smnAddr) internal view returns (bool, uint) {
        SMNVoteLib.Detail memory voteDetail = voter2smns[_voterAddr];
        for(uint i = 0; i < voteDetail.dstAddrs.length; i++) {
            if(voteDetail.dstAddrs[i] == _smnAddr) {
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
}