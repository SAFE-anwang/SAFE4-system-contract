// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./System.sol";
import "./utils/RewardUtil.sol";

contract SystemReward is ISystemReward, System {
    function reward(address _snAddr, uint _snAmount, address _mnAddr, uint _mnAmount, address _ppAddr, uint _ppAmount) public payable override onlyFormalSN {
        require(isFormalSN(_snAddr), "invalid supernode");
        require(isValidMN(_mnAddr), "invalid masternode");
        require(_ppAddr == Constant.PROPOSAL_ADDR, "invalid proposal contract");
        uint blockSpace = getPropertyValue("block_space");
        require(_snAmount >= RewardUtil.getSNReward(block.number, blockSpace), "invalid supernode reward");
        require(_mnAmount >= RewardUtil.getMNReward(block.number, blockSpace), "invalid masternode reward");
        require(_ppAmount >= RewardUtil.getPPReward(block.number, blockSpace), "invalid proposal reward");
        require(msg.value >= RewardUtil.getAllReward(block.number, blockSpace), "invalid amount for all reward");
        require(_snAmount + _mnAmount + _ppAmount == msg.value, "invalid amount");
        getSuperNodeLogic().reward{value: _snAmount}(_snAddr);
        getMasterNodeLogic().reward{value: _mnAmount}(_mnAddr);
        getProposal().reward{value: _ppAmount}();
    }
}