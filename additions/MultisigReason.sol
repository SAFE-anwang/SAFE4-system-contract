// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./MultisigWallet.sol";

contract MultiSigReason {
    mapping (uint => string) id2reason;

    address multiSig;

    constructor() {
        multiSig = 0x0000000000000000000000000000000000001102;
    }

    function add(uint _txid, string memory _reason) public {
        require(bytes(_reason).length >= 10 && bytes(_reason).length <= 512, "invalid reason length: [10, 512]");
        (bool success, bytes memory data) = multiSig.call(abi.encodeWithSignature("existOwner(address)", msg.sender));
        require(success, "call existOwner failed");
        bool flag = abi.decode(data, (bool));
        require(flag, "non-existent owner");
        id2reason[_txid] = _reason;
    }

    function get(uint _txid) public view returns (string memory) {
        return id2reason[_txid];
    }
}