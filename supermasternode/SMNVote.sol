// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SMNVote {
    struct ProxyInfo {
        address addr;
        address proxyAddr;
        uint amount;
        uint time;
    }

    mapping(address => address) internal addr2smn; // address to super masternode
    mapping(address => address[]) internal smn2addrs; // supermode to address list

    mapping(address => ProxyInfo) internal addr2proxy; // approval to masternode
    mapping(address => ProxyInfo[]) internal proxy2addrs; // masternode to address list

    function existVoter(address _smnAddr, address _voterAddr) internal view returns (bool) {
        address[] memory addrs = smn2addrs[_smnAddr];
        for(uint i = 0; i < addrs.length; i++) {
            if(_voterAddr == addrs[i]) {
                return true;
            }
        }
        return false;
    }

    // vote for super masternode
    function vote(address _smnAddr) public {
        if(existVoter(_smnAddr, msg.sender)) {
            return;
        }
        addr2smn[msg.sender] = _smnAddr;
        smn2addrs[_smnAddr].push(msg.sender);
    }

    // remove vote
    function removeVote() public {
        if(addr2smn[msg.sender] == address(0)) {
            return;
        }
        address[] storage addrs = smn2addrs[addr2smn[msg.sender]];
        uint i = 0;
        bool exist = false;
        for(i = 0; i < addrs.length; i++) {
            if(addrs[i] == msg.sender) {
                exist = true;
                break;
            }
        }
        if(exist) {
            for(uint k = i; k < addrs.length - 1; k++) {
                addrs[k] = addrs[k + 1];
            }
            delete addrs[addrs.length - 1];
        }

        delete addr2smn[msg.sender];
    }

    // approval to masternode
    function approval(address _proxyAddr) public {
        require(_proxyAddr != msg.sender, "proxy address can't be yourself");
        if(_proxyAddr == address(0)) { // remove approval
            if(addr2proxy[msg.sender].time == 0) {
                return;
            }
            ProxyInfo[] storage infos = proxy2addrs[addr2proxy[msg.sender].proxyAddr];
            uint i = 0;
            bool exist = false;
            for(i = 0; i < infos.length; i++) {
                if(infos[i].addr == msg.sender) {
                    exist = true;
                    break;
                }
            }
            if(exist) {
                for(uint k = i; k < infos.length - 1; k++) {
                    infos[k] = infos[k + 1];
                }
                delete infos[infos.length - 1];
            }
            delete addr2proxy[msg.sender];
        } else { // add approval
            ProxyInfo storage info = addr2proxy[msg.sender];
            if(info.time != 0) {
                // clear proxy
                approval(address(0));
            }
            info.addr = msg.sender;
            info.proxyAddr = _proxyAddr;
            info.amount = 10;
            info.time = block.timestamp;
            proxy2addrs[_proxyAddr].push(info);
        }
    }

    function proxyVote(address _smnAddr) public {
        ProxyInfo[] memory infos = proxy2addrs[msg.sender];
        for(uint i = 0; i < infos.length; i++) {
            if(existVoter(_smnAddr, infos[i].addr)) {
                continue;
            }
            addr2smn[infos[i].addr] = _smnAddr;
            address[] storage temp = smn2addrs[_smnAddr];
            temp.push(infos[i].addr);
        }
    }

    function getProxy() public view returns (ProxyInfo memory) {
        return addr2proxy[msg.sender];
    }

    function getApprovals() public view returns (ProxyInfo[] memory) {
        return proxy2addrs[msg.sender];
    }

    function getSMN() public view returns (address) {
        return addr2smn[msg.sender];
    }

    function getVoters() public view returns (address[] memory) {
        return smn2addrs[msg.sender];
    }
}