// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./System.sol";
import "./utils/RewardUtil.sol";

contract Proposal is IProposal, System {
    uint pp_no;
    mapping(uint => ProposalInfo) proposals;
    mapping(uint => VoteInfo[]) voteInfos;
    mapping(address => uint[]) addr2ids;
    mapping(uint => address) id2addr;
    uint[] ids;

    mapping(uint => uint) mature2amount; // key: mature height, value: amount

    event ProposalAdd(uint _id, string _title);
    event ProposalVote(uint _id, address _voter, uint _voteResult);
    event ProposalState(uint _id, uint _state);

    function reward() public payable override {
        require(msg.value >= RewardUtil.getPPReward(block.number, getPropertyValue("block_space")), "invalid reward");
        mature2amount[block.number + getPropertyValue("reward_maturity")] = msg.value;
        delete mature2amount[block.number];
    }

    function getBalance() public view override returns (uint) {
        return address(this).balance - getImmatureBalance();
    }

    function getImmatureBalance() public view override returns (uint) {
        uint immatureAmount;
        uint rewardMaturity = getPropertyValue("reward_maturity");
        for(uint i = rewardMaturity; i > 0; i--) {
            immatureAmount += mature2amount[block.number + i];
        }
        return immatureAmount;
    }

    function create(string memory _title, uint _payAmount, uint _payTimes, uint _startPayTime, uint _endPayTime, string memory _description) public payable override returns (uint) {
        require(block.number > 86400, "proposal is unopened");
        require(bytes(_title).length >= Constant.MIN_PP_TITLE_LEN && bytes(_title).length <= Constant.MAX_PP_TITLE_LEN, "invalid title");
        require(_payAmount > 0 && _payAmount <= getBalance(), "invalid pay amount");
        require(_payTimes > 0 && _payTimes <= Constant.MAX_PP_PAY_TIMES, "invalid pay times");
        require(_payAmount / _payTimes >= getPropertyValue("deposit_min_amount"), "payAmount/payTimes is less than 1SAFE");
        require(_startPayTime >= block.timestamp, "invalid start pay time");
        require(_endPayTime >= _startPayTime, "invalid end pay time");
        require(bytes(_description).length >= Constant.MIN_PP_DESCRIPTIO_LEN && bytes(_description).length <= Constant.MAX_PP_DESCRIPTIO_LEN, "invalid description");
        require(msg.value >= 1 * Constant.COIN, "need pay 1 SAFE");

        ProposalInfo storage pp = proposals[++pp_no];
        pp.id = pp_no;
        pp.creator = msg.sender;
        pp.title = _title;
        pp.payAmount = _payAmount;
        pp.payTimes = _payTimes;
        pp.startPayTime = _startPayTime;
        pp.endPayTime = _endPayTime;
        pp.description = _description;
        pp.createHeight = block.number;
        pp.updateHeight = 0;
        addr2ids[msg.sender].push(pp.id);
        id2addr[pp.id] = msg.sender;
        ids.push(pp.id);
        emit ProposalAdd(pp.id, pp.title);
        payable(0x0000000000000000000000000000000000000000).transfer(msg.value); // burn 1 SAFE at least
        return pp.id;
    }

    function vote(uint _id, uint _voteResult) public override { // only for creator of formal supernodes
        require(exist(_id), "non-existent proprosal");
        require(proposals[_id].state == 0, "proposal has been confirmed");
        require(_voteResult == Constant.VOTE_AGREE || _voteResult == Constant.VOTE_REJECT || _voteResult == Constant.VOTE_ABSTAIN, "invalue vote result, must be agree(1), reject(2), abstain(3)");
        require(block.timestamp < proposals[_id].startPayTime, "proposal is out of day");
        require(proposals[_id].payAmount <= getBalance(), "insufficient balance, wait sufficient balance");
        address[] memory sns = getSuperNodeStorage().getTops4Creator(msg.sender);
        require(sns.length > 0, "caller isn't creator of formal supernodes");
        for(uint i; i < sns.length; i++) {
            updateVoteInfo(_id, sns[i], _voteResult);
        }

        uint agreeCount;
        uint rejectCount;
        //uint snCount = getSNNum();
        for(uint i = 0; i < voteInfos[_id].length; i++) {
             if(voteInfos[_id][i].voteResult == Constant.VOTE_AGREE) {
                agreeCount++;
            } else { // reject or abstain
                rejectCount++;
            }
            //if(agreeCount > snCount * 1 / 2) {
            if(agreeCount > 24) {
                handle(_id);
                proposals[_id].state = Constant.VOTE_AGREE;
                proposals[_id].updateHeight = block.number;
                emit ProposalState(_id, Constant.VOTE_AGREE);
                return;
            }
            //if(rejectCount > snCount * 1 / 2) {
            if(rejectCount > 24) {
                proposals[_id].state = Constant.VOTE_REJECT;
                proposals[_id].updateHeight = block.number;
                emit ProposalState(_id, Constant.VOTE_REJECT);
                return;
            }
        }
    }

    function changeTitle(uint _id, string memory _title) public override {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(bytes(_title).length >= Constant.MIN_PP_TITLE_LEN && bytes(_title).length <= Constant.MAX_PP_TITLE_LEN, "invalid title");
        require(voteInfos[_id].length == 0, "voted proposal can't update title");
        proposals[_id].title = _title;
        proposals[_id].updateHeight = block.number;
    }

    function changePayAmount(uint _id, uint _payAmount) public override {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_payAmount > 0 && _payAmount <= getBalance(), "invalid pay amount");
        require(_payAmount / proposals[_id].payTimes >= getPropertyValue("deposit_min_amount"), "new payAmout/payTimes is less than 1SAFE");
        require(voteInfos[_id].length == 0, "voted proposal can't update pay-amount");
        proposals[_id].payAmount = _payAmount;
        proposals[_id].updateHeight = block.number;
    }

    function changePayTimes(uint _id, uint _payTimes) public override {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_payTimes > 0 && _payTimes <= Constant.MAX_PP_PAY_TIMES, "invalid pay times");
        require(proposals[_id].payAmount / _payTimes >= getPropertyValue("depoist_min_amount"), "new payAmount/payTimes is less than 1SAFE");
        require(voteInfos[_id].length == 0, "voted proposal can't update pay-times");
        proposals[_id].payTimes = _payTimes;
        proposals[_id].updateHeight = block.number;
    }

    function changeStartPayTime(uint _id, uint _startPayTime) public override {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_startPayTime >= block.timestamp && _startPayTime <= proposals[_id].endPayTime, "invalid start pay time");
        require(voteInfos[_id].length == 0, "voted proposal can't update start-pay-time");
        proposals[_id].startPayTime = _startPayTime;
        proposals[_id].updateHeight = block.number;
    }

    function changeEndPayTime(uint _id, uint _endPayTime) public override {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_endPayTime >= proposals[_id].startPayTime && _endPayTime >= block.timestamp, "invalid end pay time");
        require(voteInfos[_id].length == 0, "voted proposal can't update end-pay-time");
        proposals[_id].endPayTime = _endPayTime;
        proposals[_id].updateHeight = block.number;
    }

    function changeDescription(uint _id, string memory _description) public override {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(bytes(_description).length >= Constant.MIN_PP_DESCRIPTIO_LEN && bytes(_description).length <= Constant.MAX_PP_DESCRIPTIO_LEN, "invalid description");
        require(voteInfos[_id].length == 0, "voted proposal can't update description");
        proposals[_id].description = _description;
        proposals[_id].updateHeight = block.number;
    }

    function getInfo(uint _id) public view override returns (ProposalInfo memory) {
        return proposals[_id];
    }

    function getVoterNum(uint _id) public view override returns (uint) {
        return voteInfos[_id].length;
    }

    function getVoteInfo(uint _id, uint _start, uint _count) public view override returns (VoteInfo[] memory) {
        require(voteInfos[_id].length > 0, "insufficient quantity");
        require(_start < voteInfos[_id].length, "invalid _start, must be in [0, getVoterNum())");
        require(_count > 0 && _count <= 100, "max return 100 voteInfos");

        uint num = _count;
        if(_start + _count >= voteInfos[_id].length) {
            num = voteInfos[_id].length - _start;
        }
        VoteInfo[] memory ret = new VoteInfo[](num);
        for(uint i; i < num; i++) {
            ret[i] = voteInfos[_id][i + _start];
        }
        return ret;
    }

    function getNum() public view override returns (uint) {
        return ids.length;
    }

    function getAll(uint _start, uint _count) public view override returns (uint[] memory) {
        require(ids.length > 0, "insufficient quantity");
        require(_start < ids.length, "invalid _start, must be in [0, getNum())");
        require(_count > 0 && _count <= 100, "max return 100 proposals");

        uint num = _count;
        if(_start + _count >= ids.length) {
            num = ids.length - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = ids[i + _start];
        }
        return ret;
    }

    function getMineNum(address _creator) public view override returns (uint) {
        return addr2ids[_creator].length;
    }

    function getMines(address _creator, uint _start, uint _count) public view override returns (uint[] memory) {
        uint[] memory mineIDs = addr2ids[_creator];
        require(mineIDs.length > 0, "insufficient quantity");
        require(_start < mineIDs.length, "invalid _start, must be in [0, getMineNum())");
        require(_count > 0 && _count <= 100, "max return 100 proposals");

        uint num = _count;
        if(_start + _count >= mineIDs.length) {
            num = mineIDs.length - _start;
        }
        uint[] memory ret = new uint[](num);
        for(uint i; i < num; i++) {
            ret[i] = mineIDs[i + _start];
        }
        return ret;
    }

    function exist(uint _id) public view override returns (bool) {
        return proposals[_id].creator != address(0);
    }

    function handle(uint _id) internal {
        ProposalInfo memory pp = proposals[_id];
        if(pp.payTimes == 1) {
            getAccountManager().depositWithSecond{value: pp.payAmount}(pp.creator, pp.startPayTime - block.timestamp);
            return;
        }
        uint space = (pp.endPayTime - pp.startPayTime) / (pp.payTimes - 1);
        uint usedAmount;
        for(uint i; i < pp.payTimes - 1; i++) {
            getAccountManager().depositWithSecond{value: pp.payAmount / pp.payTimes}(pp.creator, pp.startPayTime + space * i - block.timestamp);
            usedAmount += pp.payAmount / pp.payTimes;
        }
        getAccountManager().depositWithSecond{value: pp.payAmount - usedAmount}(pp.creator, pp.endPayTime - block.timestamp);
    }

    function updateVoteInfo(uint _id, address _voter, uint _voteResult) internal {
        VoteInfo[] storage votes = voteInfos[_id];
        uint i;
        for(; i < votes.length; i++) {
            if(votes[i].voter == _voter) {
                break;
            }
        }
        if(i != votes.length) {
            votes[i].voteResult = _voteResult;
        } else {
            votes.push(VoteInfo(_voter, _voteResult));
        }
        emit ProposalVote(_id, _voter, _voteResult);
    }
}