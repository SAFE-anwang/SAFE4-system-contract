// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <=0.8.19;

import "./System.sol";
import "./interfaces/IProperty.sol";
import "./utils/StringUtil.sol";

contract Property is IProperty, System {
    using StringUtil for string;

    mapping(string => PropertyInfo) properties;
    string[] confirmedNames;
    mapping(string => UnconfirmedPropertyInfo) unconfirmedProperties;
    string[] unconfirmedNames;

    event PropertyAdd(string _name, uint _value);
    event PropertyUpdateApply(string _name, uint _newValue, uint _oldValue);
    event PropertyUpdateReject(string _name, uint _newValue);
    event PropertyUpdateAgree(string _name, uint _newValue);
    event PropertyUpdateVote(string _name, uint _newValue, address _voter, uint _voteResult);

    function add(string memory _name, uint _value, string memory _description) public override onlyOwner {
        require(bytes(_name).length >= Constant.MIN_PROPERTY_NAME_LEN && bytes(_name).length <= Constant.MAX_PROPERTY_NAME_LEN, "invalid name");
        require(!exist(_name), "existent property");
        require(bytes(_description).length >= Constant.MIN_PROPERTY_DESCRIPTION_LEN && bytes(_description).length <= Constant.MAX_PROPERTY_DESCRIPTION_LEN, "invalid description");
        properties[_name] = PropertyInfo(_name, _value, _description, block.number, 0);
        confirmedNames.push(_name);
        emit PropertyAdd(_name, _value);
    }

    function applyUpdate(string memory _name, uint _value, string memory _reason) public override { // only for creator of formal supernodes
        require(block.number > 86400, "property-update is unopened");
        require(exist(_name), "non-existent property");
        require(!existUnconfirmed(_name), "existent unconfirmed property");
        require(bytes(_reason).length >= Constant.MIN_PROPERTY_REASON_LEN && bytes(_reason).length <= Constant.MAX_PROPERTY_REASON_LEN, "invalid reason");
        require(getSuperNodeStorage().getTops4Creator(msg.sender).length > 0, "caller isn't creator of formal supernodes");
        UnconfirmedPropertyInfo storage info = unconfirmedProperties[_name];
        info.name = _name;
        info.value = _value;
        info.applicant = msg.sender;
        info.reason = _reason;
        info.applyHeight = block.number;
        unconfirmedNames.push(_name);
        emit PropertyUpdateApply(_name, _value, properties[_name].value);
    }

    function vote4Update(string memory _name, uint _voteResult) public override { // only for creator of formal supernodes
        require(existUnconfirmed(_name), "non-existent unconfirmed property");
        require(_voteResult == Constant.VOTE_AGREE || _voteResult == Constant.VOTE_REJECT || _voteResult == Constant.VOTE_ABSTAIN, "invalue vote result, must be agree(1), reject(2), abstain(3)");
        address[] memory sns = getSuperNodeStorage().getTops4Creator(msg.sender);
        require(sns.length > 0, "caller isn't creator of formal supernodes");
        for(uint i; i < sns.length; i++) {
            updateVoteInfo(_name, sns[i], _voteResult);
        }
        UnconfirmedPropertyInfo memory info = unconfirmedProperties[_name];
        uint agreeCount;
        uint rejectCount;
        //uint snCount = getSNNum();
        for(uint i = 0; i < info.voters.length; i++) {
            if(info.voteResults[i] == Constant.VOTE_AGREE) {
                agreeCount++;
            } else { // reject or abstain
                rejectCount++;
            }
            //if(agreeCount > snCount * 2 / 3) {
            if(agreeCount > 32) {
                properties[_name].value = info.value;
                properties[_name].updateHeight = block.number;
                removeUnconfirmedName(_name);
                emit PropertyUpdateAgree(_name, info.value);
                return;
            }
            //if(rejectCount > snCount / 3) {
            if(rejectCount > 16) {
                removeUnconfirmedName(_name);
                emit PropertyUpdateReject(_name, info.value);
                return;
            }
        }
    }

    function getInfo(string memory _name) public view override returns (PropertyInfo memory) {
        return properties[_name];
    }

    function getUnconfirmedInfo(string memory _name) public view override returns (UnconfirmedPropertyInfo memory) {
        return unconfirmedProperties[_name];
    }

    function getValue(string memory _name) public view override returns (uint) {
        return properties[_name].value;
    }

    function getNum() public view override returns (uint) {
        return confirmedNames.length;
    }

    function getAll(uint _start, uint _count) public view override returns (string[] memory) {
        require(_start < confirmedNames.length, "invalid _start, must be in [0, getNum())");
        require(_count > 0 && _count <= 100, "max return 100 properties");
        uint num = _count;
        if(_start + _count >= confirmedNames.length) {
            num = confirmedNames.length - _start;
        }
        string[] memory ret = new string[](num);
        for(uint i; i < num; i++) {
            ret[i] = confirmedNames[i + _start];
        }
        return ret;
    }

    function getUnconfirmedNum() public view override returns (uint) {
        return unconfirmedNames.length;
    }

    function getAllUnconfirmed(uint _start, uint _count) public view override returns (string[] memory) {
        require(_start < unconfirmedNames.length, "invalid _start, must be in [0, getUnconfirmedNum())");
        require(_count > 0 && _count <= 100, "max return 100 properties");
        uint num = _count;
        if(_start + _count >= unconfirmedNames.length) {
            num = unconfirmedNames.length - _start;
        }
        string[] memory ret = new string[](num);
        for(uint i; i < num; i++) {
            ret[i] = unconfirmedNames[i + _start];
        }
        return ret;
    }

    function exist(string memory _name) public view override returns (bool) {
        return bytes(properties[_name].name).length != 0;
    }

    function existUnconfirmed(string memory _name) public view override returns (bool) {
        return bytes(unconfirmedProperties[_name].name).length != 0;
    }

    function removeUnconfirmedName(string memory _name) internal {
        delete unconfirmedProperties[_name];
        for(uint i; i < unconfirmedNames.length; i++) {
            if(unconfirmedNames[i].equal(_name)) {
                unconfirmedNames[i] = unconfirmedNames[unconfirmedNames.length - 1];
                unconfirmedNames.pop();
                break;
            }
        }
    }

    function updateVoteInfo(string memory _name, address _voter, uint _voteResult) internal {
        UnconfirmedPropertyInfo storage info = unconfirmedProperties[_name];
        uint i;
        for(; i < info.voters.length; i++) {
            if(info.voters[i] == _voter) {
                break;
            }
        }
        if(i != info.voters.length) {
            info.voteResults[i] = _voteResult;
        } else {
            info.voters.push(_voter);
            info.voteResults.push(_voteResult);
        }
        emit PropertyUpdateVote(_name, info.value, _voter, _voteResult);
    }
}