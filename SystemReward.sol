// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";

contract SystemReward is ISystemReward, System {
    function reward(address _snAddr, uint _snAmount, address _mnAddr, uint _mnAmount, address _ppAddr, uint _ppAmount) public payable onlySN {
        require(isSN(msg.sender), "caller isn't supernode");
        require(isSN(_snAddr), "invalid supernode");
        require(isMN(_mnAddr), "invalid masternode");
        require(_ppAddr == PROPOSAL_PROXY_ADDR, "invalid proposal contract");
        require(_snAmount > 0, "invalid supernode reward");
        require(_mnAmount > 0, "invalid masternode reward");
        require(_snAmount + _mnAmount + _ppAmount == msg.value, "invalid amount");
        getSuperNode().reward{value: _snAmount}(_snAddr);
        getMasterNode().reward{value: _mnAmount}(_mnAddr);
        getProposal().reward{value: _ppAmount}();
    }
}