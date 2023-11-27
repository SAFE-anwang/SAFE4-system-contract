// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";

contract MasterNodeState is INodeState, System {
    mapping(uint => StateEntry[]) id2entries; // id to upload informations

    function upload(uint[] memory _ids, uint[] memory _states) public override onlySN {
        require(_ids.length == _states.length, "id list isn't matched with state list");
        bool flag = false;
        uint pos = 0;
        for(uint i = 0; i < _ids.length; i++) {
            uint id = _ids[i];
            if(!getMasterNodeStorage().existID(id)) {
                continue;
            }
            uint state = _states[i];
            flag = false;
            pos = 0;
            (flag, pos) = existCaller(id, msg.sender);
            if(flag) {
                id2entries[id][pos].state = state;
            } else {
                id2entries[id].push(StateEntry(msg.sender, state));
            }
            update(id, state);
        }
    }

    function get(uint _id) public view override returns (StateEntry[] memory) {
        return id2entries[_id];
    }

    function existCaller(uint _id, address _caller) internal view returns (bool, uint) {
        for(uint i = 0; i < id2entries[_id].length; i++) {
            if(id2entries[_id][i].caller == _caller) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function update(uint _id, uint _state) internal {
        StateEntry[] storage entries = id2entries[_id];
        uint num = 0;
        for(uint i = 0; i < entries.length; i++) {
            if(_state == entries[i].state) {
                if(++num > getSNNum() * 2 / 3) {
                    delete id2entries[_id];
                    getMasterNodeLogic().changeState(_id, _state);
                    break;
                }
            }
        }
    }
}