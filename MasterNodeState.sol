// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";

contract MasterNodeState is INodeState, System {
    mapping(uint => address[]) id2addrs;
    mapping(uint => uint[]) id2states;

    function upload(uint[] memory _ids, uint[] memory _states) public override onlyFormalSN {
        require(_ids.length == _states.length, "id list isn't matched with state list");
        uint snNum = getSNNum();
        for(uint i; i < _ids.length; i++) {
            if(getMasterNodeStorage().existID(_ids[i])) {
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
            id2states[_id][i] = _state;
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
                    getMasterNodeLogic().changeState(_id, _state);
                    delete id2addrs[_id];
                    delete id2states[_id];
                    return;
                }
            }
        }
    }
}