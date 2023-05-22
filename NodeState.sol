// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/INodeState.sol";

contract NodeState is INodeState, System {
    struct Entry {
        address caller;
        uint8 state;
    }

    mapping(uint => Entry[]) id2states;

    function uploadState(uint[] memory _ids, uint8[] memory _states) public {
        require(_ids.length == _states.length, "id list isn't matched with state list");

        bool exist = false;
        uint pos = 0;
        for(uint i = 0; i < _ids.length; i++) {
            (exist, pos) = existCaller(_ids[i], msg.sender);
            if(exist) {
                id2states[_ids[i]][pos].state = _states[i];
            } else {
                id2states[_ids[i]].push(Entry(msg.sender, _states[i]));
            }
            updateState(_ids[i], _states[i]);
        }
    }

    function existCaller(uint _id, address _caller) internal view returns (bool, uint) {
        for(uint i = 0; i < id2states[_id].length; i++) {
            if(id2states[_id][i].caller == _caller) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function updateState(uint _id, uint8 _state) internal {
        Entry[] storage entries = id2states[_id];
        uint num = 0;
        for(uint i = 0; i < entries.length; i++) {
            if(_state == entries[i].state) {
                if(++num >= getSNNum() * 2 / 3) {
                    entries[i].state = _state;
                    return;
                }
            }
        }
    }
}