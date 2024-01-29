// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";

contract SuperNodeState is INodeState, System {
    mapping(uint => mapping(address => uint)) id2entry;
    mapping(uint => address[]) id2addrs;

    function upload(uint[] memory _ids, uint[] memory _states) public override onlySN {
        require(_ids.length == _states.length, "id list isn't matched with state list");
        for(uint i; i < _ids.length; i++) {
            uint id = _ids[i];
            if(!getSuperNodeStorage().existID(id)) {
                continue;
            }
            id2entry[id][msg.sender] = _states[i];

            bool exist;
            for(uint k; k < id2addrs[id].length; k++) {
                if(id2addrs[id][k] == msg.sender) {
                    exist = true;
                    break;
                }
            }
            if(!exist) {
                id2addrs[id].push(msg.sender);
            }

            update(id, _states[i]);
        }
    }

    function get(uint _id) public view override returns (StateEntry[] memory) {
        address[] memory addrs = id2addrs[_id];
        uint count;
        for(uint i; i < addrs.length; i++) {
            if(id2entry[_id][addrs[i]] != 0) {
                count++;
            }
        }
        StateEntry[] memory entries = new StateEntry[](count);
        uint k;
        for(uint i; i < addrs.length; i++) {
            if(id2entry[_id][addrs[i]] != 0) {
                entries[k++] = StateEntry(addrs[i], id2entry[_id][addrs[i]]);
            }
        }
        return entries;
    }

    function update(uint _id, uint _state) internal {
        uint num;
        uint snNum = getSNNum();
        address[] memory addrs = id2addrs[_id];
        bool flag;
        for(uint i; i < addrs.length; i++) {
            if(_state == id2entry[_id][addrs[i]]) {
                if(++num > snNum * 2 / 3) {
                    flag = true;
                    break;
                }
            }
        }
        if(flag) {
            for(uint i; i < addrs.length; i++) {
                id2entry[_id][addrs[i]] = 0;
            }
            // delete id2addrs[_id];
            getSuperNodeLogic().changeState(_id, _state);
        }
    }
}