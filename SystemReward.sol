// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";

contract SystemReward is ISystemReward, System {
    function reward(address _snAddr, uint _snAmount, address _mnAddr, uint _mnAmount, address _ppAddr, uint _ppAmount) public payable override onlyFormalSN {
        require(isFormalSN(_snAddr), "invalid supernode");
        require(isValidMN(_mnAddr), "invalid masternode");
        require(_ppAddr == Constant.PROPOSAL_ADDR, "invalid proposal contract");
        require(_snAmount > 0, "invalid supernode reward");
        require(_mnAmount > 0, "invalid masternode reward");
        require(_snAmount + _mnAmount + _ppAmount == msg.value, "invalid amount");
        getSuperNodeLogic().reward{value: _snAmount}(_snAddr);
        getMasterNodeLogic().reward{value: _mnAmount}(_mnAddr);
        getProposal().reward{value: _ppAmount}();
    }
}