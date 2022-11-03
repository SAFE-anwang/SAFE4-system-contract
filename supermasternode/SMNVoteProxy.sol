// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SMNVoteLib.sol";

contract SMNVoteProxy {
    mapping(bytes20 => SMNVoteLib.RecordInfo) record2proxy;
    mapping(address => SMNVoteLib.Detail) voter2proxies; // voter to proxy list
    mapping(address => uint) proxy2num; // proxy to total vote number
    mapping(address => address[]) proxy2voters; // proxy to voter list

    // approval to proxy address
    function approval(address _voterAddr, address _proxyAddr, bytes20 _recordID, uint _num) public {
        require(record2proxy[_recordID].voterAddr == address(0), "record id has been proxied, can't proxy repeated");
        SMNVoteLib.Detail storage detail = voter2proxies[_voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existProxy(_voterAddr, _proxyAddr);
        if(exist) {
            // add total proxy number
            detail.totals[pos] += _num;
            // add proxy entry
            detail.entries[pos].push(SMNVoteLib.Entry(_recordID, _num, block.number));
            // add record detail
            record2proxy[_recordID] = SMNVoteLib.RecordInfo(_voterAddr, _proxyAddr, detail.entries[pos].length, block.number);
        } else {
            detail.dstAddrs.push(_proxyAddr);
            detail.totals.push(_num);
            detail.entries[0].push(SMNVoteLib.Entry(_recordID, _num, block.number));
            // add record detail
            record2proxy[_recordID] = SMNVoteLib.RecordInfo(_voterAddr, _proxyAddr, 0, block.number);
        }

        address[] storage voters = proxy2voters[_voterAddr];
        //(exist, pos) = existApproval(_proxyAddr, _voterAddr);
        if(!exist) {
            voters.push(_voterAddr);
        }
        proxy2num[_proxyAddr] += _num;
    }

    // remove all vote num
    function removeApproval(address _voterAddr) public {
        SMNVoteLib.Detail storage detail = voter2proxies[_voterAddr];
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            address proxyAddr = detail.dstAddrs[i];

            // remove smn total vote number
            proxy2num[proxyAddr] -= detail.totals[i];

            // remove record id
            for(uint k = 0; k < detail.entries[i].length; k++) {
                delete record2proxy[detail.entries[i][k].recordID];
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
            (exist, pos) = existApproval(proxyAddr, _voterAddr);
            if(exist) {
                address[] storage voters = proxy2voters[proxyAddr];
                voters[pos] = voters[voters.length - 1];
                voters.pop();
                if(voters.length == 0) {
                    delete proxy2voters[proxyAddr];
                    delete proxy2num[proxyAddr];
                }
            }
        }
        if(detail.dstAddrs.length == 0) {
            delete voter2proxies[_voterAddr];
        }
    }

    // remove specify vote records
    function removeApproval(address _voterAddr, bytes20[] memory _recordIDs) public {
        require(_recordIDs.length > 0, "invalid record ids");
        for(uint i = 0; i < _recordIDs.length; i++) {
            require(record2proxy[_recordIDs[i]].voterAddr == _voterAddr, "voter address isn't matched with record ids");
        }

        SMNVoteLib.Detail storage detail = voter2proxies[_voterAddr];
        for(uint i = 0; i < _recordIDs.length; i++) {
            bytes20 recordID = _recordIDs[i];
            address proxyAddr = record2proxy[recordID].dstAddr;

            bool exist = false;
            uint pos = 0;
            (exist, pos) = existProxy(_voterAddr, proxyAddr);
            if(exist) {
                SMNVoteLib.Entry[] storage entries = detail.entries[pos];
                uint index = record2proxy[recordID].index;
                uint num = entries[index].num;

                // remove vote number
                proxy2num[proxyAddr] -= num;
                if(proxy2num[proxyAddr] == 0) {
                    delete proxy2num[proxyAddr];
                }

                // remove record id
                record2proxy[entries[entries.length - 1].recordID].index = index;
                delete record2proxy[recordID];
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
                    (exist, pos) = existApproval(proxyAddr, _voterAddr);
                    if(exist) {
                        address[] storage voters = proxy2voters[proxyAddr];
                        voters[pos] = voters[voters.length - 1];
                        voters.pop();
                        if(voters.length == 0) {
                            delete proxy2voters[proxyAddr];
                        }
                    }
                } else {
                    // decrease vote num
                    detail.totals[pos] -= num;
                }
            }
        }
        if(detail.dstAddrs.length == 0) {
            delete voter2proxies[_voterAddr];
        }
    }

    function getProxy(address _voterAddr) public view returns (address[] memory, uint[] memory) {
        return (voter2proxies[_voterAddr].dstAddrs, voter2proxies[_voterAddr].totals);
    }

    function getApprovals(address _proxyAddr) public view returns (address[] memory) {
        return proxy2voters[_proxyAddr];
    }

    /**************************************** internal ****************************************/
    function existProxy(address _voterAddr, address _proxyAddr) internal view returns (bool, uint) {
        SMNVoteLib.Detail memory detail = voter2proxies[_voterAddr];
        for(uint i = 0; i < detail.dstAddrs.length; i++) {
            if(detail.dstAddrs[i] == _proxyAddr) {
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
}