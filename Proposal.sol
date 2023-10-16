// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";

contract Proposal is IProposal, System {
    uint pp_no;

    mapping(uint => ProposalInfo) proposals;
    mapping(address => uint[]) addr2ids;
    mapping(uint => address) id2addr;
    uint[] ids;

    event ProposalAdd(uint _id, string _title);
    event ProposalVote(uint _id, address _voter, uint _voteResult);
    event ProposalState(uint _id, uint _state);

    function create(string memory _title, uint _payAmount, uint _payTimes, uint _startPayTime, uint _endPayTime, string memory _description, string memory _detail) public payable returns (uint) {
        require(bytes(_title).length != 0, "invalid title");
        require(_payAmount > 0, "invalid pay amount");
        require(_payTimes > 0, "invalid pay times");
        require(_startPayTime >= block.timestamp, "invalid start pay time");
        require(_endPayTime >= _startPayTime, "invalid end pay time");
        require(bytes(_description).length != 0, "invalid description");
        require(bytes(_detail).length != 0, "invalid detail");
        require(msg.value >= 1, "need pay 1 SAFE");

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
        pp.detail = _detail;
        pp.createHeight = block.number;
        pp.updateHeight = 0;
        addr2ids[msg.sender].push(pp.id);
        id2addr[pp.id] = msg.sender;
        ids.push(pp.id);
        return pp.id;
    }

    function vote(uint _id, uint _voteResult) public onlySN {
        require(existUnconfirmed(_id), "proposal has been confirmed");
        require(_voteResult == 0 || _voteResult == 1 || _voteResult == 2, "invalue vote result, must be agree(1), reject(2), abstain(3)");
        address[] storage voters = proposals[_id].voters;
        uint i = 0;
        bool flag = false;
        for(i = 0; i < voters.length; i++) {
            if(voters[i] == msg.sender) {
                flag = true;
                break;
            }
        }
        uint[] storage voteResults = proposals[_id].voteResults;
        if(flag) {
            voteResults[i] = _voteResult;
        } else {
            voters.push(msg.sender);
            voteResults.push(_voteResult);
        }
        emit ProposalVote(_id, msg.sender, _voteResult);

        uint agreeCount = 0;
        uint rejectCount = 0;
        uint snCount = getSNNum();
        for(i = 0; i < voteResults.length; i++) {
             if(voteResults[i] == 1) {
                agreeCount++;
            }
            else if(voteResults[i] == 2) {
                rejectCount++;
            }
            if(agreeCount > snCount * 2 / 3) {
                proposals[_id].state == 1;
                emit ProposalState(_id, 1);
                return;
            }
            if(rejectCount >= snCount * 1 / 3) {
                proposals[_id].state = 2;
                emit ProposalState(_id, 2);
                return;
            }
        }
    }

    function changeTitle(uint _id, string memory _title) public {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(bytes(_title).length != 0, "invalid title");
        require(proposals[_id].state == 0, "confirmed proposal can't update title");
        proposals[_id].title = _title;
        proposals[_id].updateHeight = block.number;
    }

    function changePayAmount(uint _id, uint _payAmount) public {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_payAmount != 0, "invalid pay amount");
        require(proposals[_id].state == 0, "confirmed proposal can't update pay amount");
        proposals[_id].payAmount = _payAmount;
        proposals[_id].updateHeight = block.number;
    }

    function changePayTimes(uint _id, uint _payTimes) public {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_payTimes != 0, "invalid pay times");
        require(proposals[_id].state == 0, "confirmed proposal can't update pay times");
        proposals[_id].payTimes = _payTimes;
        proposals[_id].updateHeight = block.number;
    }

    function changeStartPayTime(uint _id, uint _startPayTime) public {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_startPayTime >= proposals[_id].startPayTime && _startPayTime >= block.timestamp, "invalid start pay time");
        require(proposals[_id].state == 0, "confirmed proposal can't update pay times");
        proposals[_id].startPayTime = _startPayTime;
        proposals[_id].updateHeight = block.number;
    }

    function changeEndPayTime(uint _id, uint _endPayTime) public {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(_endPayTime >= proposals[_id].startPayTime && _endPayTime >= block.timestamp, "invalid end pay time");
        require(proposals[_id].state == 0, "confirmed proposal can't update pay times");
        proposals[_id].endPayTime = _endPayTime;
        proposals[_id].updateHeight = block.number;
    }

    function changeDescription(uint _id, string memory _description) public {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(bytes(_description).length != 0, "invalid description");
        require(proposals[_id].state == 0, "confirmed proposal can't update title");
        proposals[_id].description = _description;
        proposals[_id].updateHeight = block.number;
    }

    function changeDetail(uint _id, string memory _detail) public {
        require(exist(_id), "non-existent proposal");
        require(id2addr[_id] == msg.sender, "caller isn't proposal owner");
        require(bytes(_detail).length != 0, "invalid detail");
        require(proposals[_id].state == 0, "confirmed proposal can't update title");
        proposals[_id].detail = _detail;
        proposals[_id].updateHeight = block.number;
    }

    function getInfo(uint _id) public view returns (ProposalInfo memory) {
        require(exist(_id), "non-existent proposal");
        return proposals[_id];
    }

    function getAll() public view returns (ProposalInfo[] memory) {
        ProposalInfo[] memory  pps = new ProposalInfo[](ids.length);
        for(uint i = 0; i < ids.length; i++) {
            pps[i] = proposals[ids[i]];
        }
        return pps;
    }

    function getMine() public view returns (ProposalInfo[] memory) {
        uint[] memory mineIDs = addr2ids[msg.sender];
        ProposalInfo[] memory pps = new ProposalInfo[](mineIDs.length);
        for(uint i = 0; i < mineIDs.length; i++) {
            pps[i] = proposals[mineIDs[i]];
        }
        return pps;
    }

    function exist(uint _id) internal view returns (bool) {
        return proposals[_id].createHeight != 0;
    }

    function existUnconfirmed(uint _id) internal view returns (bool) {
        return proposals[_id].createHeight != 0 && proposals[_id].state == 0;
    }
}