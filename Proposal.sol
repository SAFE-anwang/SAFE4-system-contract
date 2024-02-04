// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";

contract Proposal is IProposal, System {
    uint pp_no;
    mapping(uint => ProposalInfo) proposals;
    mapping(uint => VoteInfo[]) voteInfos;
    mapping(address => uint[]) addr2ids;
    mapping(uint => address) id2addr;
    uint[] ids;

    event ProposalAdd(uint _id, string _title);
    event ProposalVote(uint _id, address _voter, uint _voteResult);
    event ProposalState(uint _id, uint _state);

    function reward() public payable override {}

    function getBalance() public view override returns (uint) {
        return address(this).balance;
    }

    function create(string memory _title, uint _payAmount, uint _payTimes, uint _startPayTime, uint _endPayTime, string memory _description) public payable override returns (uint) {
        require(bytes(_title).length >= Constant.MIN_PP_TITLE_LEN && bytes(_title).length <= Constant.MAX_PP_TITLE_LEN, "invalid title");
        require(_payAmount > 0 && _payAmount <= getBalance(), "invalid pay amount");
        require(_payTimes > 0 && _payTimes <= Constant.MAX_PP_PAY_TIMES, "invalid pay times");
        require(_payAmount / _payTimes != 0, "invalid pay amount and times");
        require(_startPayTime >= block.timestamp, "invalid start pay time");
        require(_endPayTime >= _startPayTime, "invalid end pay time");
        require(bytes(_description).length >= Constant.MIN_PP_DESCRIPTIO_LEN && bytes(_description).length <= Constant.MAX_PP_DESCRIPTIO_LEN, "invalid description");
        require(msg.value >= 1 * Constant.COIN, "need pay 1 SAFE");

        // burn 1 SAFE at least
        getAccountManager().deposit{value: msg.value}(0x0000000000000000000000000000000000000000, 0);

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
        return pp.id;
    }

    function vote(uint _id, uint _voteResult) public override onlySN {
        require(exist(_id), "non-existent proprosal");
        require(proposals[_id].state == 0, "proposal has been confirmed");
        require(_voteResult == Constant.VOTE_AGREE || _voteResult == Constant.VOTE_REJECT || _voteResult == Constant.VOTE_ABSTAIN, "invalue vote result, must be agree(1), reject(2), abstain(3)");
        require(block.timestamp < proposals[_id].startPayTime, "proposal is out of day");
        VoteInfo[] storage votes = voteInfos[_id];
        uint i;
        bool flag;
        for(; i < votes.length; i++) {
            if(votes[i].voter == msg.sender) {
                flag = true;
                break;
            }
        }
        if(flag) {
            votes[i].voteResult = _voteResult;
        } else {
            votes.push(VoteInfo(msg.sender, _voteResult));
        }
        emit ProposalVote(_id, msg.sender, _voteResult);

        if (proposals[_id].state != 0) {
            return;
        }

        uint agreeCount;
        uint rejectCount;
        uint snCount = getSNNum();
        for(i = 0; i < votes.length; i++) {
             if(votes[i].voteResult == Constant.VOTE_AGREE) {
                agreeCount++;
            } else { // reject or abstain
                rejectCount++;
            }
            if(agreeCount > snCount * 2 / 3) {
                handle(_id);
                proposals[_id].state = Constant.VOTE_AGREE;
                emit ProposalState(_id, Constant.VOTE_AGREE);
                return;
            }
            if(rejectCount >= snCount * 1 / 3) {
                proposals[_id].state = Constant.VOTE_REJECT;
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
        require(_payAmount / proposals[_id].payTimes != 0, "pay amount is too small");
        require(voteInfos[_id].length == 0, "voted proposal can't update pay-amount");
        proposals[_id].payAmount = _payAmount;
        proposals[_id].updateHeight = block.number;
    }

    function changePayTimes(uint _id, uint _payTimes) public override {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_payTimes > 0 && _payTimes <= Constant.MAX_PP_PAY_TIMES, "invalid pay times");
        require(proposals[_id].payAmount / _payTimes != 0, "pay times is too big");
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

    function getMineNum() public view override returns (uint) {
        return addr2ids[msg.sender].length;
    }

    function getMines(uint _start, uint _count) public view override returns (uint[] memory) {
        uint[] memory mineIDs = addr2ids[msg.sender];
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
}