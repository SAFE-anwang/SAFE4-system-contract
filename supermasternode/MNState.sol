// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MNState {
    struct Entry {
        address caller;
        uint8 state;
    }

    mapping(uint => Entry[]) id2states;

    function uploadState(uint[] memory _ids, uint8[] memory _states, uint total) public {
        require(_ids.length == _states.length, "masternode id list is incompatible with state list");

        bool exist = false;
        uint pos = 0;
        for(uint i = 0; i < _ids.length; i++) {
            (exist, pos) = existCaller(_ids[i], msg.sender);
            if(exist) {
                id2states[_ids[i]][pos].state = _states[i];
            } else {
                Entry memory entry = Entry(msg.sender, _states[i]);
                id2states[_ids[i]].push(entry);
            }
            updateState(_ids[i], _states[i], total);
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

    function updateState(uint _id, uint8 _state, uint total) internal {
        Entry[] storage entries = id2states[_id];
        uint num = 0;
        for(uint i = 0; i < entries.length; i++) {
            if(_state == entries[i].state) {
                if(++num >= total * 2 / 3) {
                    entries[i].state = _state;
                    return;
                }
            }
        }
    }
}