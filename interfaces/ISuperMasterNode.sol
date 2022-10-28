// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafeProperty.sol";
import "../account/AccountManager.sol";
import "../supermasternode/SuperMasterNodeInfo.sol";

interface ISuperMasterNode {
    event SMNRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event SMNUnionRegiste(address _addr, string _ip, string _pubkey, string _msg);
    event SMNAppendRegiste(address _addr, bytes20 _lockID, string _msg);

    function registe(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function unionRegiste(uint _lockDay, address _addr, string memory _ip, string memory _pubkey, string memory _description, uint _creatorIncentive, uint _partnerIncentive, uint _voterIncentive) external payable;
    function appendRegiste(uint _lockDay, address _addr) external payable;
    function appendRegiste(bytes20 _lockID, address _addr) external;

    function verify(address _addr) external;

    function reward(address _addr, uint _amount) external;

    function applyUpdateProperty(SafeProperty _property, string memory _name, bytes memory _value, string memory _reason) external;
    function vote4UpdateProperty(SafeProperty _property, string memory _name, uint _result) external;

    function uploadMasternodeState(uint[] memory _ids, uint8[] memory _states) external;
    function uploadSuperMasternodeState(bytes20[] memory _ids, uint8[] memory _states) external;

    function changeAddress(address _addr, address _newAddr) external;
    function changeIP(address _addr, string memory _newIP) external;
    function changePubkey(address _addr, string memory _newPubkey) external;
    function changeDescription(address _addr, string memory _newDescription) external;

    function getInfo(address _addr) external view returns (SuperMasterNodeInfo.Data memory);
    function getTop() external view returns (SuperMasterNodeInfo.Data[] memory);
}