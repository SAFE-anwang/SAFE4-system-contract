// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeProperty {
    struct PropertyInfo {
        string name;
        bytes value;
        string description;
        uint createTime;
        uint updateTime;
    }

    struct UnconfirmedPropertyInfo {
        string name;
        bytes value;
        address applicant;
        address[] voters;
        uint[] voteResults;
        string reason;
        uint applyTime;
    }

    uint count;
    mapping(string => PropertyInfo) properties;
    mapping(string => UnconfirmedPropertyInfo) unconfirmedProperties;

    event PropertyAdd(string _name, bytes _value);
    event PropertyApplyUpdate(string _name, bytes _newValue, bytes _oldValue);
    event PropertyUpdateReject(string _name, bytes _newValue);
    event PropertyUpdateAgree(string _name, bytes _newValue);
    event PropertyUpdateVote(string _name, bytes _newValue, address _voters, uint _voteResult);

    function addProperty(string memory _name, bytes memory _value, string memory _description) public {
        require(!exist(_name), "existent property");
        PropertyInfo storage info = properties[_name];
        info.name = _name;
        info.value = _value;
        info.description = _description;
        info.createTime = block.timestamp;
        info.updateTime = 0;
        count++;
        emit PropertyAdd(_name, _value);
    }

    function applyUpdateProperty(string memory _name, bytes memory _value, string memory _reason) public {
        require(exist(_name), "non-existent property");
        require(!existUnconfirmed(_name), "existent unconfirmed property");
        require(!compareValue(_value, properties[_name].value), "exist same property value");
        UnconfirmedPropertyInfo storage info = unconfirmedProperties[_name];
        info.name = _name;
        info.value = _value;
        info.applicant = msg.sender;
        info.voters.push(msg.sender);
        info.voteResults.push(1);
        info.reason = _reason;
        info.applyTime = block.timestamp;
        emit PropertyApplyUpdate(_name, _value, properties[_name].value);
    }

    function vote4UpdateProperty(string memory _name, uint _result, uint smnCount) public {
        require(existUnconfirmed(_name), "non-existent unconfirmed property");
        require(_result == 0 || _result == 1 || _result == 2, "invalue vote result, must be reject(0), agree(1), abstain(2)");
        require(smnCount > 0 && smnCount <= 21, "invalid super-masternode count, must be more than 0, less than 21");
        UnconfirmedPropertyInfo storage info = unconfirmedProperties[_name];
        uint i = 0;
        for(i = 0; i < info.voters.length; i++) {
            if(info.voters[i] == msg.sender) {
                break;
            }
        }
        if(i != info.voters.length) {
            info.voteResults[i] = _result;
        } else {
            info.voters.push(msg.sender);
            info.voteResults.push(_result);
        }
        uint agreeCount = 0;
        uint rejectCount = 0;
        for(i = 0; i < info.voters.length; i++) {
            if(info.voteResults[i] == 0) {
                rejectCount++;
            } else if(info.voteResults[i] == 1) {
                agreeCount++;
            }
            if(rejectCount >= smnCount * 2 / 3) {
                removeUnconfirmed(_name);
                emit PropertyUpdateReject(_name, info.value);
                return;
            } else if(agreeCount >= smnCount * 2 / 3) {
                updateProperty(_name, info.value);
                removeUnconfirmed(_name);
                emit PropertyUpdateAgree(_name, info.value);
                return;
            }
        }
        emit PropertyUpdateVote(_name, info.value, msg.sender, _result);
    }

    function getProperty(string memory _name) public view returns (PropertyInfo memory) {
        require(exist(_name), "non-existent property");
        return properties[_name];
    }

    function getUnconfirmedProperty(string memory _name) public view returns (UnconfirmedPropertyInfo memory) {
        require(exist(_name), "non-existent property");
        require(existUnconfirmed(_name), "non-existent unconfirmed property");
        return unconfirmedProperties[_name];
    }

    /************************************************** internal **************************************************/
    function exist(string memory _name) internal view returns (bool) {
        return properties[_name].createTime != 0;
    }

    function existUnconfirmed(string memory _name) internal view returns (bool) {
        return unconfirmedProperties[_name].applyTime != 0;
    }

    function updateProperty(string memory _name, bytes memory _value) internal {
        PropertyInfo storage info = properties[_name];
        info.value = _value;
        info.updateTime = block.timestamp;
    }

    function removeUnconfirmed(string memory _name) internal {
        delete unconfirmedProperties[_name];
    }

    function compareValue(bytes memory _v1, bytes memory _v2) internal pure returns (bool) {
        return keccak256(_v1) == keccak256(_v2);
    }
}