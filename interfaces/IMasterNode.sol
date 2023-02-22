// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../types/SpecialNodeType.sol";

interface IMasterNode {
    function register(address _addr, bool _isUnion, uint _lockDay, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive) external payable;
    function appendRegister(address _addr, uint _lockDay) external payable;
    function reward(address _addr) external payable;
    function changeAddress(address _addr, address _newAddr) external;
    function changeIP(address _addr, string memory _newIP) external;
    function changePubkey(address _addr, string memory _newPubkey) external;
    function changeDescription(address _addr, string memory _newDescription) external;
    function getInfo(address _addr) external view returns (MasterNodeInfo memory);
    function getNext() external view returns (address);
    function exist(address _addr) external view returns (bool);
    function existID(uint _id) external view returns (bool);
    function existIP(string memory _ip) external view returns (bool);
    function existPubkey(string memory _pubkey) external view returns (bool);
    function existLockID(address _addr, bytes20 _lokcID) external view returns (bool);
}