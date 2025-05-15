// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./System.sol";

contract SuperNodeState is INodeState, System {
    mapping(uint => address[]) id2addrs;
    mapping(uint => uint[]) id2states;
    mapping(address => uint) sn2height;

    mapping(uint => mapping(address => uint)) id2addr2state;

    bool internal lock; // re-entrant lock
    modifier noReentrant() {
        require(!lock, "Error: reentrant call");
        lock = true;
        _;
        lock = false;
    }

    function upload(uint[] memory _ids, uint[] memory _states) public override onlyFormalSN noReentrant {
        require(_ids.length > 0, "empty ids");
        require(_ids.length <= 20, "too more ids");
        require(_ids.length == _states.length, "id list isn't matched with state list");

        address[] memory sns = getSuperNodeStorage().getTops();
        ISuperNodeStorage.SuperNodeInfo memory info;
        for(uint i; i < _ids.length; i++) {
            info = getSuperNodeStorage().getInfoByID(_ids[i]);
            if(info.id == 0 || info.state == _states[i]) {
                continue;
            }
            id2addr2state[_ids[i]][msg.sender] = _states[i];
            update(_ids[i], _states[i], sns);
        }
    }

    function get(uint _id) public view override returns (StateEntry[] memory) {
        address[] memory sns = getSuperNodeStorage().getTops();
        StateEntry[] memory ret = new StateEntry[](sns.length);
        for(uint i; i < ret.length; i++) {
            ret[i] = StateEntry(sns[i], id2addr2state[_id][sns[i]]);
        }
        return ret;
    }

    function getByAddr(uint _id, address _addr) public view override returns(uint) {
        return id2addr2state[_id][_addr];
    }

    function update(uint _id, uint _state, address[] memory _sns) internal {
        uint num;
        bool ok;
        for(uint i; i < _sns.length; i++) {
            if(_state == id2addr2state[_id][_sns[i]]) {
                num+=1;
            }
            if(num > _sns.length * 2 /3) {
                ok = true;
                break;
            }
        }
        if(ok) {
            getSuperNodeLogic().changeState(_id, _state);
            for(uint i; i < _sns.length; i++) {
                id2addr2state[_id][_sns[i]] = 0;
            }
        }
    }
}