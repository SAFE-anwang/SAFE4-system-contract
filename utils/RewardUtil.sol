// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

library RewardUtil {
    uint internal constant ALL_REWARD = 0;
    uint internal constant ONLY_SN_REWARD = 1;
    uint internal constant ONLY_MN_REWARD = 2;
    uint internal constant ONLY_PP_REWARD = 3;

    function getAllReward(uint _height) public pure returns (uint) {
        return getReward(_height, ALL_REWARD);
    }

    function getSNReward(uint _height) public pure returns (uint) {
        return getReward(_height, ONLY_SN_REWARD);
    }

    function getMNReward(uint _height) public pure returns (uint) {
        return getReward(_height, ONLY_MN_REWARD);
    }

    function getPPReward(uint _height) public pure returns (uint) {
        return getReward(_height, ONLY_PP_REWARD);
    }

    function getReward(uint _height, uint _flag) internal pure returns (uint) {
        uint amount = 1e18;
        for(uint i = 200; i <= _height; i += 1051200) {
            amount -= amount / 14;
        }

        if(_flag == ALL_REWARD) {
            return amount;
        }

        uint ppAmount = amount / 10;
        if(_flag == ONLY_PP_REWARD) {
            return ppAmount;
        }

        amount -= ppAmount;
        uint mnAmount = amount / 5 + amount / 20 * 3 + amount / 40 * 6;
        if(_flag == ONLY_MN_REWARD) {
            return mnAmount;
        }
        return amount - mnAmount;
    }
}