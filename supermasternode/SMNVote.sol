// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SMNVote {
    struct VoteDetail {
        address addr;
        uint num;
    }

    mapping(address => VoteDetail[]) internal voter2smns; // voters to supermasternode
    mapping(address => uint) smn2num; // supermasternode to total vote number
    mapping(address => VoteDetail[]) internal smn2voters; // supermasternode to voter list

    struct ProxyInfo {
        address addr;
        uint num;
        bool used;
    }

    mapping(address => ProxyInfo) internal addr2proxy; // approval to masternode
    mapping(address => ProxyInfo[]) internal proxy2addrs; // masternode to address list

    // vote for supermasternode
    function vote(address _voterAddr, address _smnAddr, uint _num) public {
        VoteDetail[] storage smnDetails = voter2smns[_voterAddr];
        bool exist = false;
        uint pos = 0;
        (exist, pos) = existSMN(_voterAddr, _smnAddr);
        if(exist) {
            smnDetails[pos].num += _num;
        } else {
            smnDetails.push(VoteDetail(_smnAddr, _num));
        }

        VoteDetail[] storage voterDetails = smn2voters[_voterAddr];
        (exist, pos) = existVoter(_smnAddr, _voterAddr);
        if(exist) {
            voterDetails[pos].num += _num;
        } else {
            voterDetails.push(VoteDetail(_smnAddr, _num));
        }
        smn2num[_smnAddr] += _num;
    }

    // remove all vote num
    function removeVote(address _voterAddr, address _smnAddr) public {
        bool exist = false;
        uint pos = 0;

        (exist, pos) = existSMN(_voterAddr, _smnAddr);
        if(exist) {
            VoteDetail[] storage smnDetails = voter2smns[_voterAddr];
            smnDetails[pos] = smnDetails[smnDetails.length - 1];
            smnDetails.pop();
        }

        (exist, pos) = existVoter(_smnAddr, _voterAddr);
        if(exist) {
            VoteDetail[] storage voterDetails = smn2voters[_smnAddr];
            voterDetails[pos] = voterDetails[voterDetails.length - 1];
            voterDetails.pop();
        }
    }

    // remove specify vote num
    function removeVote(address _voterAddr, address _smnAddr, uint _num) public {
        bool exist = false;
        uint pos = 0;

        (exist, pos) = existSMN(_voterAddr, _smnAddr);
        if(exist) {
            VoteDetail[] storage smnDetails = voter2smns[_voterAddr];
            // require(smnDetails[pos].num >= _num, "vote number is less than target removed number");
            if(smnDetails[pos].num > _num) {
                smnDetails[pos].num -= _num;
            } else {
                smnDetails[pos] = smnDetails[smnDetails.length - 1];
                smnDetails.pop();
            }
        }

        (exist, pos) = existVoter(_smnAddr, _voterAddr);
        if(exist) {
            VoteDetail[] storage voterDetails = smn2voters[_smnAddr];
            // require(voterDetails[pos].num >= _num, "vote number is leass than target removed number");
            if(voterDetails[pos].num > _num) {
                voterDetails[pos].num -= _num;
            } else {
                voterDetails[pos] = voterDetails[voterDetails.length - 1];
                voterDetails.pop();
            }
        }
    }

    // approval to masternode
    function approval(address _voterAddr, address _proxyAddr, uint _num) public {
        require(_proxyAddr != _voterAddr, "proxy address can't be voter");
        if(_proxyAddr == address(0)) { // remove approval
            removeApproval(_voterAddr);
            return;
        }

        ProxyInfo storage info = addr2proxy[_voterAddr];
        if(info.addr == address(0)) {
            info.addr = _proxyAddr;
            info.num = _num;
        } else {
            if(info.addr != _proxyAddr) { // new proxy
                removeApproval(_voterAddr);
                addr2proxy[_voterAddr] = ProxyInfo(_proxyAddr, _num, false);
            } else { // old proxy, append approval
                if(info.used) {
                    info.num = _num;
                } else {
                    info.num += _num;
                }
            }
        }

        ProxyInfo[] storage infos = proxy2addrs[_proxyAddr];
        for(uint i = 0; i < infos.length; i++) {
            if(infos[i].addr == _voterAddr) {
                if(infos[i].used) {
                    infos[i].num = _num;
                }
                return;
            }
        }
        infos.push(ProxyInfo(_voterAddr, _num, false));
    }

    // clear approval
    function removeApproval(address _voterAddr) internal {
        address proxyAddr = addr2proxy[_voterAddr].addr;
        delete addr2proxy[_voterAddr];

        ProxyInfo[] storage infos = proxy2addrs[proxyAddr];
        uint i = 0;
        bool exist = false;
        for(i = 0; i < infos.length; i++) {
            if(infos[i].addr == _voterAddr) {
                exist = true;
                break;
            }
        }
        if(exist) {
            infos[i] = infos[infos.length - 1];
            infos.pop();
        }
    }

    function proxyVote(address _smnAddr, address _proxyAddr) public {
        ProxyInfo[] memory infos = proxy2addrs[_proxyAddr];
        for(uint i = 0; i < infos.length; i++) {
            if(infos[i].used) {
                continue;
            }
            vote(infos[i].addr, _smnAddr, infos[i].num);
            infos[i].used = true;
            addr2proxy[infos[i].addr].used = true;
        }
    }

    function getProxy(address _voterAddr) public view returns (ProxyInfo memory) {
        return addr2proxy[_voterAddr];
    }

    function getApprovals(address _proxyAddr) public view returns (ProxyInfo[] memory) {
        return proxy2addrs[_proxyAddr];
    }

    function getVotedSMN(address _voterAddr) public view returns (VoteDetail[] memory) {
        return voter2smns[_voterAddr];
    }

    function getVoters(address _smnAddr) public view returns (VoteDetail[] memory) {
        return smn2voters[_smnAddr];
    }

    /**************************************** internal ****************************************/
    function existSMN(address _voterAddr, address _smnAddr) internal view returns (bool, uint) {
        VoteDetail[] memory details = voter2smns[_voterAddr];
        for(uint i = 0; i < details.length; i++) {
            if(details[i].addr == _smnAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function existVoter(address _smnAddr, address _voterAddr) internal view returns (bool, uint) {
        VoteDetail[] memory details = smn2voters[_smnAddr];
        for(uint i = 0; i < details.length; i++) {
            if(details[i].addr == _voterAddr) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}