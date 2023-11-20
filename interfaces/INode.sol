// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INode {
    struct MemberInfo {
        uint lockID; // lock id
        address addr; // member address
        uint amount; // lock amount
        uint height; // add height
    }

    struct IncentivePlan {
        uint creator; // creator percent [0, 10%]
        uint partner; // partner percent [40%, 50$]
        uint voter; // voter percent [40%, 50%]
    }

    struct StateInfo {
        uint state;
        uint height;
    }

    function appendRegister(address _addr, uint _lockDay) external payable;
    function turnRegister(address _addr, uint _lockID) external;
    function reward(address _addr) external payable;
    function removeMember(address _addr, uint _lockID) external;

    function changeAddress(address _addr, address _newAddr) external;
    function changeEnode(address _addr, string memory _enode) external;
    function changeDescription(address _addr, string memory _description) external;
    function changeIsOfficial(address _addr, bool _flag) external;
    function changeState(uint _id, uint _state) external;

    function getNum() external view returns (uint);

    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existEnode(string memory _enode) external view returns (bool);
    function existLockID(address _addr, uint _lockID) external view returns (bool);
    function isValid(address _addr) external view returns (bool);
}