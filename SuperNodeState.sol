// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./System.sol";

contract SuperNodeState is INodeState, System {
    mapping(uint => address[]) id2addrs;
    mapping(uint => uint[]) id2states;

    function upload(uint[] memory _ids, uint[] memory _states) public override onlyFormalSN {
        require(_ids.length == _states.length, "id list isn't matched with state list");
        uint snNum = getSNNum();
        for(uint i; i < _ids.length; i++) {
            if(getSuperNodeStorage().existID(_ids[i])) {
                save(_ids[i], _states[i]);
                update(_ids[i], _states[i], snNum);
            }
        }
    }

    function get(uint _id) public view override returns (StateEntry[] memory) {
        address[] memory addrs = id2addrs[_id];
        uint[] memory states = id2states[_id];
        StateEntry[] memory entries = new StateEntry[](addrs.length);
        for(uint i; i < addrs.length; i++) {
            entries[i] = StateEntry(addrs[i], states[i]);
        }
        return entries;
    }

    function save(uint _id, uint _state) internal {
        bool exist;
        uint i;
        for(; i < id2addrs[_id].length; i++) {
            if(id2addrs[_id][i] == msg.sender) {
                exist = true;
                break;
            }
        }
        if(exist) {
            if(getSuperNodeStorage().getInfoByID(_id).state == _state) {
                remove(_id);
            } else {
                id2states[_id][i] = _state;
            }
        } else {
            id2addrs[_id].push(msg.sender);
            id2states[_id].push(_state);
        }
    }

    function update(uint _id, uint _state, uint _snNum) internal {
        uint num;
        for(uint i; i < id2states[_id].length; i++) {
            if(_state == id2states[_id][i]) {
                num += 1;
                if(num > _snNum * 2 / 3) {
                    getSuperNodeLogic().changeState(_id, _state);
                    delete id2addrs[_id];
                    delete id2states[_id];
                    return;
                }
            }
        }
    }

    function remove(uint _id) internal {
        address[] storage addrs = id2addrs[_id];
        uint[] storage states = id2states[_id];
        for(uint i; i < addrs.length; i++) {
            if(addrs[i] == msg.sender) {
                addrs[i] = addrs[addrs.length - 1];
                addrs.pop();
                states[i] = states[states.length - 1];
                states.pop();
                break;
            }
        }
    }
}