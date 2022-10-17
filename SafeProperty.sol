// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SysProperty {
    struct Data {
        string name;
        string value;
        string description;
        uint createTime;
        uint updateTime;
    }

    struct UnconfirmedData {
        string name;
        string value;
        address applicant;
        address[] voters;
        uint[] voteResults;
        string reason;
        uint applyTime;
    }

    uint count;
    mapping(string => Data) properties;
    mapping(string => UnconfirmedData) unconfirmedProperties;

    event PropertyAdd(string _name, string _value);
    event PropertyApplyUpdate(string _name, string _newValue, string _oldValue);
    event PropertyUpdateReject(string _name, string _newValue);
    event PropertyUpdateAgree(string _name, string _newValue);
    event PropertyUpdateVote(string _name, string _newValue, address _voters, uint _voteResult);

    function addProperty(string memory _name, string memory _value, string memory _description) public {
        require(!exist(_name), "existent property");
        Data storage data = properties[_name];
        data.name = _name;
        data.value = _value;
        data.description = _description;
        data.createTime = block.timestamp;
        data.updateTime = 0;
        count++;
        emit PropertyAdd(_name, _value);
    }

    function applyUpdateProperty(string memory _name, string memory _value, string memory _reason) public {
        require(exist(_name), "non-existent property");
        require(!existUnconfirmed(_name), "existent unconfirmed property");
        require(!compareValue(_value, properties[_name].value), "exist same property value");
        UnconfirmedData storage data = unconfirmedProperties[_name];
        data.name = _name;
        data.value = _value;
        data.applicant = msg.sender;
        data.voters.push(msg.sender);
        data.voteResults.push(1);
        data.reason = _reason;
        data.applyTime = block.timestamp;
        emit PropertyApplyUpdate(_name, _value, properties[_name].value);
    }

    function vote4property(string memory _name, uint _result, uint smnCount) public {
        require(existUnconfirmed(_name), "non-existent unconfirmed property");
        require(_result == 0 || _result == 1 || _result == 2, "invalue vote result, must be reject(0), agree(1), abstain(2)");
        require(smnCount > 0 && smnCount <= 21, "invalid super-masternode count, must be more than 0, less than 21");
        UnconfirmedData storage data = unconfirmedProperties[_name];
        uint i = 0;
        for(i = 0; i < data.voters.length; i++) {
            if(data.voters[i] == msg.sender) {
                break;
            }
        }
        if(i != data.voters.length) {
            data.voteResults[i] = _result;
        } else {
            data.voters.push(msg.sender);
            data.voteResults.push(_result);
        }
        uint agreeCount = 0;
        uint rejectCount = 0;
        for(i = 0; i < data.voters.length; i++) {
            if(data.voteResults[i] == 0) {
                rejectCount++;
            } else if(data.voteResults[i] == 1) {
                agreeCount++;
            }
            if(rejectCount >= smnCount * 2 / 3) {
                removeUnconfirmed(_name);
                emit PropertyUpdateReject(_name, data.value);
                return;
            } else if(agreeCount >= smnCount * 2 / 3) {
                updateProperty(_name, data.value);
                removeUnconfirmed(_name);
                emit PropertyUpdateAgree(_name, data.value);
                return;
            }
        }
        emit PropertyUpdateVote(_name, data.value, msg.sender, _result);
    }

    function getProperty(string memory _name) public view returns (Data memory) {
        require(exist(_name), "non-existent property");
        return properties[_name];
    }

    function getUnconfirmedProperty(string memory _name) public view returns (UnconfirmedData memory) {
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

    function updateProperty(string memory _name, string memory _value) internal {
        Data storage data = properties[_name];
        data.value = _value;
        data.updateTime = block.timestamp;
    }

    function removeUnconfirmed(string memory _name) internal {
        delete unconfirmedProperties[_name];
    }

    function compareValue(string memory _v1, string memory _v2) internal pure returns (bool) {
        return keccak256(bytes(_v1)) == keccak256(bytes(_v2));
    }
}