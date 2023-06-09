// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./System.sol";
import "./interfaces/IProperty.sol";
import "./utils/StringUtil.sol";

contract Property is IProperty, System {
    using StringUtil for string;

    mapping(string => PropertyInfo) properties;
    string[] confirmedNames;
    mapping(string => UnconfirmedPropertyInfo) unconfirmedProperties;
    string[] unconfirmedNames;

    function add(string memory _name, uint _value, string memory _description) public onlyOwner {
        require(!exist(_name), "existent property");
        properties[_name] = PropertyInfo(_name, _value, _description, block.number, 0);
        confirmedNames.push(_name);
        emit PropertyAdd(_name, _value);
    }

    function applyUpdate(string memory _name, uint _value, string memory _reason) public onlySN {
        require(exist(_name), "non-existent property");
        require(!existUnconfirmed(_name), "existent unconfirmed property");
        require(_value != properties[_name].value, "same property value");
        UnconfirmedPropertyInfo storage info = unconfirmedProperties[_name];
        info.name = _name;
        info.value = _value;
        info.applicant = msg.sender;
        info.voters.push(msg.sender);
        info.voteResults.push(1);
        info.reason = _reason;
        info.applyHeight = block.number;
        unconfirmedNames.push(_name);
        emit PropertyUpdateApply(_name, _value, properties[_name].value);
    }

    function vote4Update(string memory _name, uint _voteResult) public onlySN {
        require(existUnconfirmed(_name), "non-existent unconfirmed property");
        require(_voteResult == 1 || _voteResult == 2 || _voteResult == 3, "invalue vote result, must be agree(1), reject(2), abstain(3)");
        UnconfirmedPropertyInfo storage info = unconfirmedProperties[_name];
        uint i = 0;
        for(i = 0; i < info.voters.length; i++) {
            if(info.voters[i] == msg.sender) {
                break;
            }
        }
        if(i != info.voters.length) {
            info.voteResults[i] = _voteResult;
        } else {
            info.voters.push(msg.sender);
            info.voteResults.push(_voteResult);
        }
        uint agreeCount = 0;
        uint rejectCount = 0;
        uint snCount = getSNNum();
        for(i = 0; i < info.voters.length; i++) {
            if(info.voteResults[i] == 1) {
                agreeCount++;
            } else if(info.voteResults[i] == 2) {
                rejectCount++;
            }
            if(agreeCount > snCount * 2 / 3) {
                PropertyInfo storage info2 = properties[_name];
                info2.value = info.value;
                info2.updateHeight = block.timestamp;
                removeUnconfirmedName(_name);
                emit PropertyUpdateAgree(_name, info.value);
                return;
            }
            if(rejectCount >= snCount / 3) {
                removeUnconfirmedName(_name);
                emit PropertyUpdateReject(_name, info.value);
                return;
            }
        }
        emit PropertyUpdateVote(_name, info.value, msg.sender, _voteResult);
    }

    function getInfo(string memory _name) public view returns (PropertyInfo memory) {
        require(exist(_name), "non-existent property");
        return properties[_name];
    }

    function getUnconfirmedInfo(string memory _name) public view returns (UnconfirmedPropertyInfo memory) {
        require(!exist(_name), "non-existent property");
        require(existUnconfirmed(_name), "non-existent unconfirmed property");
        return unconfirmedProperties[_name];
    }

    function getValue(string memory _name) public view returns (uint) {
        return getInfo(_name).value;
    }

    function getAllConfirmed() public view returns (PropertyInfo[] memory) {
        PropertyInfo[] memory ret = new PropertyInfo[](confirmedNames.length);
        for(uint i = 0; i < confirmedNames.length; i++) {
            ret[i] = properties[confirmedNames[i]];
        }
        return ret;
    }

    function getAllUnConfirmed() public view returns (UnconfirmedPropertyInfo[] memory) {
        UnconfirmedPropertyInfo[] memory ret = new UnconfirmedPropertyInfo[](unconfirmedNames.length);
        for(uint i = 0; i < unconfirmedNames.length; i++) {
            ret[i] = unconfirmedProperties[unconfirmedNames[i]];
        }
        return ret;
    }

    function exist(string memory _name) internal view returns (bool) {
        return bytes(properties[_name].name).length != 0;
    }

    function existUnconfirmed(string memory _name) internal view returns (bool) {
        return bytes(unconfirmedProperties[_name].name).length != 0;
    }

    function removeUnconfirmedName(string memory _name) internal {
        require(existUnconfirmed(_name), "non-existent unconfirmed property");
        delete unconfirmedProperties[_name];
        for(uint i = 0; i < unconfirmedNames.length; i++) {
            if(unconfirmedNames[i].equal(_name)) {
                unconfirmedNames[i] = unconfirmedNames[unconfirmedNames.length - 1];
                unconfirmedNames.pop();
                break;
            }
        }
    }
}