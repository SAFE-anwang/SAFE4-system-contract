// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(address indexed sender, uint indexed transactionId);
    event Execution(address indexed sender, uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

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

    uint transactionCount;
    mapping (uint => Transaction) transactions;
    mapping (uint => mapping (address => bool)) confirmations;

    struct Transaction {
        address from;
        address destination;
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

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "existent owner");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "non-existent owner");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0), "non-existent transactionId");
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner], "unconfirmed transactionId by caller");
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner], "confirmed transactionId by caller");
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, "executed transactionId");
        _;
    }

    modifier validTimestamp(uint transactionId) {
        require(transactions[transactionId].timestamp >= block.timestamp + minDelay, "timestamp too early");
        _;
    }

    modifier inConfirmDurtion(uint transactionId) {
        require(block.timestamp < transactions[transactionId].timestamp, "transaction exceed confirm durtion");
        _;
    }

    modifier inExecuteDurtion(uint transactionId) {
        require(block.timestamp >= transactions[transactionId].timestamp, "transaction not ready to execute");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "null address");
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0, "invalid required");
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
        minDelay = 24*2600;
    }

    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    function submitTransaction(address destination, uint value, bytes calldata data, uint timestamp)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data, timestamp);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        inConfirmDurtion(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
    }

    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
        inConfirmDurtion(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        notExecuted(transactionId)
        inExecuteDurtion(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
            if (success) {
                txn.executor = msg.sender;
                txn.executed = true;
                emit Execution(msg.sender, transactionId);
            }
            else {
                txn.executed = false;
                emit ExecutionFailure(transactionId);
            }
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
        return transactionCount;
    }

    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] memory _transactionIds)
    {
        require(to > from, "invalid from and to");
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        if (from >= count)
            return _transactionIds;
        uint size = to - from;
        if (to > count) {
            size = count - from;
        }
        _transactionIds = new uint[](size);
        for (i=0; i<size; i++)
            _transactionIds[i] = transactionIdsTemp[i + from];
    }

    function getTransaction(uint transactionId)
        public
        view
        returns (Transaction memory)
    {
        return transactions[transactionId];
    }

    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    function getConfirmations(uint transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    function canExecute(uint transactionId)
        public
        view
        returns (bool)
    {
        return block.timestamp >= transactions[transactionId].timestamp;
    }

    function isExecuted(uint transactionId)
        public
        view
        returns (bool)
    {
        return transactions[transactionId].executed;
    }

    function isConfirmed(uint transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    function addTransaction(address destination, uint value, bytes calldata data, uint timestamp)
        internal
        notNull(destination)
        validTimestamp(timestamp)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            from: msg.sender,
            destination: destination,
            value: value,
            data: data,
            timestamp: timestamp,
            executor: address(0),
            executed: false
        });
        transactionCount += 1;
        emit Submission(msg.sender, transactionId);
    }
}