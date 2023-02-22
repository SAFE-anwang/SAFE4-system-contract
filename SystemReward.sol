// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/ISystemReward.sol";
import "./interfaces/IMasterNode.sol";
import "./interfaces/ISuperMasterNode.sol";
import "./utils/SafeMath.sol";

contract SystemReward is ISystemReward, System {
    using SafeMath for uint;

    function reward(address _smnAddr, uint _smnAmount, address _mnAddr, uint _mnAmount) public payable onlySMN {
        require(isSMN(_smnAddr), "invalid supermasternode");
        require(isMN(_mnAddr), "invalid masternode");
        require(_smnAmount > 0, "invalid supermasternode reward"); 
        require(_mnAmount > 0, "invalid masternode reward");
        ISuperMasterNode smn = ISuperMasterNode(SUPERMASTERNODE_PROXY_ADDR);
        smn.reward{value: _smnAmount}(_smnAddr);
        IMasterNode mn = IMasterNode(MASTERNODE_PROXY_ADDR);
        mn.reward{value: _mnAmount}(_mnAddr);
    }
}