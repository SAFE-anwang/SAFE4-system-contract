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

    function appendRegister(address _addr, uint _lockDay) external payable;

    function changeAddress(address _addr, address _newAddr) external;
    function changeEnode(address _addr, string memory _newEnode) external;
    function changePubkey(address _addr, string memory _newPubkey) external;
    function changeDescription(address _addr, string memory _newDescription) external;

    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existIP(string memory _ip) external view returns (bool);
    function existPubkey(string memory _pubkey) external view returns (bool);
    function existLockID(address _addr, uint _lockID) external view returns (bool);
}