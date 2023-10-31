// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.2;

import "./System.sol";

contract SuperNodeState is INodeState, System {
    uint[] ids; // all node id
    mapping(uint => uint) id2index; // index in ids
    mapping(uint => uint) id2state; // id to state
    mapping(uint => StateEntry[]) id2entries; // id to upload informations

    function uploadState(uint[] memory _ids, uint[] memory _states) public override onlySN {
        require(_ids.length == _states.length, "id list isn't matched with state list");
        bool flag = false;
        uint pos = 0;
        for(uint i = 0; i < _ids.length; i++) {
            uint id = _ids[i];
            if(!getSuperNode().existID(id)) {
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
            updateState(id, state);
        }
    }

    function getAllState() public view override returns (StateInfo[] memory) {
        StateInfo[] memory infos = new StateInfo[](ids.length);
        for(uint i = 0; i < infos.length; i++) {
            uint id = ids[i];
            ISuperNode.SuperNodeInfo memory sn = getSuperNode().getInfoByID(id);
            infos[i] = StateInfo(sn.addr, id, id2state[id]);
        }
        return infos;
    }

    function getEntries(uint _id) public view override returns (StateEntry[] memory) {
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

    function updateState(uint _id, uint _state) internal {
        StateEntry[] storage entries = id2entries[_id];
        uint num = 0;
        for(uint i = 0; i < entries.length; i++) {
            if(_state == entries[i].state) {
                if(++num > getSNNum() * 2 / 3) {
                    if(id2index[_id] == 0) {
                        ids.push(_id);
                        id2index[_id] = ids.length;
                    }
                    id2state[_id] = _state;
                    delete id2entries[_id];
                    getSuperNode().changeState(_id, _state);
                    break;
                }
            }
        }
    }
}