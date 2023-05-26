// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/ISystemReward.sol";
import "./interfaces/IMasterNode.sol";
import "./interfaces/ISuperNode.sol";
import "./utils/SafeMath.sol";

contract SystemReward is ISystemReward, System {
    using SafeMath for uint;

    function reward(address _snAddr, uint _snAmount, address _mnAddr, uint _mnAmount) public payable onlySN {
        require(isSN(_snAddr), "invalid supernode");
        require(isMN(_mnAddr), "invalid masternode");
        require(_snAmount > 0, "invalid supernode reward");
        require(_mnAmount > 0, "invalid masternode reward");
        require(_snAmount + _mnAmount == msg.value, "invalid amount");
        ISuperNode sn = ISuperNode(SUPERNODE_PROXY_ADDR);
        sn.reward{value: _snAmount}(_snAddr);
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        mn.reward{value: _mnAmount}(_mnAddr);
    }
}