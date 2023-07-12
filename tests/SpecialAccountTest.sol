// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./utils/SafeMath.sol";

contract SpecialAccountTest is System {
    using SafeMath for uint;

    struct WithdrawPlan {
        bool isEffective;
        uint times; // withdraw times
        uint[] percents; // withdraw percent every time
        uint space; // withdraw space: days
        uint[] startHeight; // start withdraw height every time
        bool[] isWithdraw;
        address[] voters;
        uint[] voteResults;
    }

    struct AccountInfo {
        address addr;
        uint amount;
        uint remainAmount;
    }

    mapping(address => AccountInfo) addr2account;
    mapping(address => WithdrawPlan) addr2plan;

    event SpecialWithdraw(address _addr, uint _amount);

    receive() external payable {}
    fallback() external payable {}

    constructor() payable {
        addr2account[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = AccountInfo(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 3000000000000000000, 3000000000000000000);
        addr2account[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = AccountInfo(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 1000000000000000000, 1000000000000000000);
    }

    // apply withdraw
    function applyWithdraw(uint times, uint[] memory percents, uint space) public {
        require(addr2plan[msg.sender].times == 0, "existent withdraw plan");
        require(addr2account[msg.sender].remainAmount > 0, "non-exist account or insufficient balance");
        require(times > 0 && times <= 120, "invalid times, min: 1, max: 120");
        require(percents.length == times, "times isn't matched with percents");
        uint totalPercent = 0;
        for(uint i = 0; i < times; i++) {
            totalPercent += percents[i];
        }
        require(totalPercent == 100, "invalid percents, total percent isn't 100%");
        WithdrawPlan storage plan = addr2plan[msg.sender];
        plan.isEffective = false;
        plan.times = times;
        plan.percents = percents;
        plan.space = space;
    }

    // vote for withdraw
    function voteWithderaw(address _accountAddr, uint _voteResult) public {
        require(addr2account[_accountAddr].amount > 0, "non-existent account");
        require(addr2plan[_accountAddr].times > 0, "non-existent withdraw plan");
        require(!addr2plan[_accountAddr].isEffective, "need ineffective withdraw plan");
        require(_voteResult == 1 || _voteResult == 2 || _voteResult == 3, "invalue vote result, must be agree(1), reject(2), abstain(3)");
        WithdrawPlan storage plan = addr2plan[_accountAddr];
        uint i = 0;
        for(i = 0; i < plan.voters.length; i++) {
            if(plan.voters[i] == msg.sender) {
                break;
            }
        }
        if(i != plan.voters.length) {
            plan.voteResults[i] = _voteResult;
        } else {
            plan.voters.push(msg.sender);
            plan.voteResults.push(_voteResult);
        }
        uint agreeCount = 0;
        uint rejectCount = 0;
        uint snCount = 3;
        for(i = 0; i < plan.voters.length; i++) {
            if(plan.voteResults[i] == 1) {
                agreeCount++;
            } else if(plan.voteResults[i] == 2) {
                rejectCount++;
            }
            if(agreeCount > snCount * 2 / 3) {
                plan.isEffective = true;
                uint lastHeight = block.number + 1;
                for(uint k = 0; k < plan.times; k++) {
                    //plan.startHeight.push(lastHeight + plan.space.mul(86400).div(getPropertyValue("block_space").mul(k)));
                    plan.startHeight.push(lastHeight + plan.space.mul(k));
                    plan.isWithdraw.push(false);
                }
                break;
            }
            if(rejectCount >= snCount / 3) { // remove withdraw plan
                delete addr2plan[_accountAddr];
                break;
            }
        }
    }

    // withdraw all
    function tryWithdraw() public {
        require(addr2account[msg.sender].remainAmount > 0, "non-existent account or insufficient balance");
        require(addr2plan[msg.sender].isEffective, "non-effective withdraw plan");
        WithdrawPlan storage plan = addr2plan[msg.sender];
        for(uint i = 0; i < plan.times; i++) {
            if(plan.isWithdraw[i]) {
                continue;
            }
            if(block.number < plan.startHeight[i]) {
                break;
            }
            uint amount = addr2account[msg.sender].amount.mul(plan.percents[i]).div(100);
            payable(msg.sender).transfer(amount);
            plan.isWithdraw[i] = true;
            AccountInfo storage info = addr2account[msg.sender];
            if(info.remainAmount < amount) {
                info.remainAmount = 0;
            } else {
                info.remainAmount -= amount;
            }
        }
        bool isFinish = true;
        for(uint i = 0; i < plan.times; i++) {
            if(!plan.isWithdraw[i]) {
                isFinish = false;
                break;
            }
        }
        if(isFinish) { // remove withdraw plan when user withdraw finish
            delete addr2plan[msg.sender];
        }
    }

    function getAccountInfo(address _addr) public view returns (AccountInfo memory) {
        require(addr2account[_addr].amount);
        return addr2account[_addr];
    }

    function getWithdrawPlan(address _addr) public view returns (WithdrawPlan memory) {
        return addr2plan[_addr];
    }
}