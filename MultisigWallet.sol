// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address indexed _sender, uint indexed _txid);
    event Revocation(address indexed _sender, uint indexed _txid);
    event Submission(address indexed _sender, uint indexed _txid);
    event Execution(address indexed _sender, uint indexed _txid);
    event Deposit(address indexed _sender, uint _value);
    event OwnerAddition(address indexed _owner);
    event OwnerRemoval(address indexed _owner);
    event RequirementChange(uint _required);

    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    uint minDelay;
    uint required;
    address[] owners;
    mapping (address => bool) isOwner;

    uint txCount;
    mapping (uint => Transaction) transactions;
    mapping (uint => mapping (address => bool)) confirmations;

    struct Transaction {
        address from;
        address to;
        uint value;
        bytes data;
        uint timestamp;
        address executor;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this), "invalid caller");
        _;
    }

    modifier ownerNotExist(address _owner) {
        require(!isOwner[_owner], "existent owner");
        _;
    }

    modifier ownerExist(address _owner) {
        require(isOwner[_owner], "non-existent owner");
        _;
    }

    modifier txExist(uint _txid) {
        require(transactions[_txid].to != address(0), "non-existent txid");
        _;
    }

    modifier txConfirmed(uint _txid, address _owner) {
        require(confirmations[_txid][_owner], "unconfirmed txid by caller");
        _;
    }

    modifier txNotConfirmed(uint _txid, address _owner) {
        require(!confirmations[_txid][_owner], "confirmed txid by caller");
        _;
    }

    modifier txNotExecuted(uint _txid) {
        require(!transactions[_txid].executed, "executed txid");
        _;
    }

    modifier txInConfirmDurtion(uint _txid) {
        require(block.timestamp < transactions[_txid].timestamp, "transaction exceed confirm durtion");
        _;
    }

    modifier txInExecuteDurtion(uint _txid) {
        require(block.timestamp >= transactions[_txid].timestamp, "transaction not ready to execute");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "null address");
        _;
    }

    modifier validTimestamp(uint _timestamp) {
        require(_timestamp >= block.timestamp + minDelay, "timestamp too early");
        _;
    }

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(_ownerCount <= MAX_OWNER_COUNT
            && _required <= _ownerCount
            && _required != 0
            && _ownerCount != 0, "invalid required");
        _;
    }

    receive() external payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    constructor(address[] memory _owners, uint _required)
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        minDelay = 600;
    }

    function addOwner(address _owner)
        public
        onlyWallet
        ownerNotExist(_owner)
        notNull(_owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAddition(_owner);
    }

    function removeOwner(address _owner)
        public
        onlyWallet
        ownerExist(_owner)
    {
        isOwner[_owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(_owner);
    }

    function replaceOwner(address _owner, address _newOwner)
        public
        onlyWallet
        ownerExist(_owner)
        ownerNotExist(_newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == _owner) {
                owners[i] = _newOwner;
                break;
            }
        isOwner[_owner] = false;
        isOwner[_newOwner] = true;
        emit OwnerRemoval(_owner);
        emit OwnerAddition(_newOwner);
    }

    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    function submitTransaction(address _to, uint _value, bytes calldata _data, uint _timestamp)
        public
        returns (uint txid)
    {
        txid = addTransaction(_to, _value, _data, _timestamp);
        confirmTransaction(txid);
    }

    function confirmTransaction(uint _txid)
        public
        ownerExist(msg.sender)
        txExist(_txid)
        txNotConfirmed(_txid, msg.sender)
        txInConfirmDurtion(_txid)
    {
        confirmations[_txid][msg.sender] = true;
        emit Confirmation(msg.sender, _txid);
    }

    function revokeConfirmation(uint _txid)
        public
        ownerExist(msg.sender)
        txConfirmed(_txid, msg.sender)
        txNotExecuted(_txid)
        txInConfirmDurtion(_txid)
    {
        confirmations[_txid][msg.sender] = false;
        emit Revocation(msg.sender, _txid);
    }

    function executeTransaction(uint _txid)
        public
        ownerExist(msg.sender)
        txNotExecuted(_txid)
        txInExecuteDurtion(_txid)
    {
        if (isConfirmed(_txid)) {
            Transaction storage txn = transactions[_txid];
            (bool success, ) = txn.to.call{value: txn.value}(txn.data);
            require(success, "execute transaction - call target failed, please check target contract and data");
            txn.executor = msg.sender;
            txn.executed = true;
            emit Execution(msg.sender, _txid);
        }
    }

    function getRequired()
        public
        view
        returns (uint)
    {
        return required;
    }

    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    function existOwner(address _addr)
        public
        view
        returns (bool)
    {
        return isOwner[_addr];
    }

    function getAllTransactionCount()
        public
        view
        returns (uint)
    {
        return txCount;
    }

    function getTransactionCount(bool _pending, bool _executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<txCount; i++)
            if (   _pending && !transactions[i].executed
                || _executed && transactions[i].executed)
                count += 1;
    }

    function getTransactionIds(uint _start, uint _end, bool _pending, bool _executed)
        public
        view
        returns (uint[] memory txids)
    {
        require(_end > _start, "invalid start and end");
        uint[] memory temps = new uint[](txCount);
        uint count = 0;
        uint i;
        for (i=0; i<txCount; i++)
            if (   _pending && !transactions[i].executed
                || _executed && transactions[i].executed)
            {
                temps[count] = i;
                count += 1;
            }
        if (_start >= count)
            return txids;
        uint size = _end - _start;
        if (_end > count) {
            size = count - _start;
        }
        txids = new uint[](size);
        for (i=0; i<size; i++)
            txids[i] = temps[i + _start];
    }

    function getTransaction(uint _txid)
        public
        view
        returns (Transaction memory)
    {
        return transactions[_txid];
    }

    function getConfirmationCount(uint _txid)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[_txid][owners[i]])
                count += 1;
    }

    function getConfirmations(uint _txid)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[_txid][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    function isCanExecute(uint _txid)
        public
        view
        returns (bool)
    {
        return block.timestamp >= transactions[_txid].timestamp;
    }

    function isExecuted(uint _txid)
        public
        view
        returns (bool)
    {
        return transactions[_txid].executed;
    }

    function isConfirmed(uint _txid)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[_txid][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    function addTransaction(address _to, uint _value, bytes calldata _data, uint _timestamp)
        internal
        notNull(_to)
        validTimestamp(_timestamp)
        returns (uint txid)
    {
        txid = txCount;
        transactions[txid] = Transaction({
            from: msg.sender,
            to: _to,
            value: _value,
            data: _data,
            timestamp: _timestamp,
            executor: address(0),
            executed: false
        });
        txCount += 1;
        emit Submission(msg.sender, txid);
    }
}