// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract LogoPay is Initializable, OwnableUpgradeable {
    address[] _froms;
    mapping(address => uint256) _received;

    event Received(address from, uint256 amount);
    event Withdraw(address to, uint256 amount);

    function initialize() public initializer {
        __Ownable_init();
        transferOwnership(0x0000000000000000000000000000000000001102);
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    receive() external payable {
        require(msg.value != 0, "invalid amount");
        if(_received[msg.sender] == 0) {
            _froms.push(msg.sender);
        }
        _received[msg.sender] += msg.value;
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        require(msg.value != 0, "invalid amount");
        if(_received[msg.sender] == 0) {
            _froms.push(msg.sender);
        }
        _received[msg.sender] += msg.value;
        emit Received(msg.sender, msg.value);
    }

    function withdraw(address to_) external onlyOwner {
        require(to_ != address(0), "invalid target address");
        uint256 balance = getBalance();
        require(balance > 0, "insufficient balance");
        payable(to_).transfer(balance);
        emit Withdraw(to_, balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getReceived(address from_) public view returns (uint256) {
        return _received[from_];
    }

    function getFromNum() public view returns (uint256) {
        return _froms.length;
    }

    function getFroms(uint256 _start, uint256 _count) public view returns (address[] memory) {
        require(_froms.length > 0, "insufficient quantity");
        require(_start < _froms.length, "invalid _start, must be in [0, getFromNum())");
        require(_count > 0 && _count <= 100, "max return 100 froms");
        uint num = _count;
        if(_start + _count >= _froms.length) {
            num = _froms.length - _start;
        }
        address[] memory ret = new address[](num);
        for(uint i; i < num; i++) {
            ret[i] = _froms[i + _start];
        }
        return ret;
    }
}