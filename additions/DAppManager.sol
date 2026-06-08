// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DAppManager is Initializable, OwnableUpgradeable {
    struct DAppInfo {
        uint256 id;
        string name;
        address contract_addr;
        string run_url;
        string git_url;
        string official_url;
        string official_email;
        address official_account;
        string keyword;
        uint256 fraudNum;
        bool isFrozen;
    }

    uint256 no;

    uint256[] ids;
    mapping(uint256 => uint256) id2index;

    mapping(uint256 => DAppInfo) dapps;
    mapping(uint256 => bytes) logos;

    mapping(string => uint256) name2id;
    mapping(address => uint256) contractAddr2id;
    mapping(string => uint256) runUrl2id;

    mapping(address => uint256[]) account2ids;
    mapping(address => mapping(uint256 => uint256)) accountId2index; // [account][id] = index

    mapping(address => mapping(uint256 => bool)) userMarkedDApps;

    event DAppRegister(uint256 indexed id, string indexed name, address indexed account);
    event DAppRemove(uint256 indexed id, string indexed name, address indexed account);
    event DAppUpdateName(uint256 indexed id, string indexed oldName, string indexed newName);
    event DAppUpdateContractAddr(uint256 indexed id, address indexed oldAddr, address indexed newAddr);
    event DAppUpdateRunUrl(uint256 indexed id, string indexed oldUrl, string indexed newUrl);
    event DAppUpdateGitUrl(uint256 indexed id, string indexed oldUrl, string indexed newUrl);
    event DAppUpdateOfficialUrl(uint256 indexed id, string indexed oldUrl, string indexed newUrl);
    event DAppUpdateOfficialEmail(uint256 indexed id, string indexed odEmail, string indexed newEmail);
    event DAppUpdateOfficialAccount(uint256 indexed id, address indexed oldAccount, address indexed newAccount);
    event DAppUpdateKeyword(uint256 indexed id, string indexed oldKeyword, string indexed newKeyword);
    event DAppUpdateLogo(uint256 indexed id);
    event DAppUpdateFraudNum(uint256 indexed id, uint256 indexed num);
    event DAppFreeze(uint256 indexed id);
    event DAppUnfreeze(uint256 indexed id);

    function initialize() public initializer {
        __Ownable_init();
        transferOwnership(0x0000000000000000000000000000000000001102);
    }

    function GetInitializeData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    function register(string memory name, address contract_addr, string memory run_url, string memory git_url, string memory official_url, string memory official_email) public {
        require(contract_addr != address(0), "invalid contract address");
        require(bytes(name).length >= 5 && bytes(name).length <= 50, "invalid name");
        require(bytes(run_url).length >= 15 && bytes(run_url).length <= 200, "invalid run url");
        require(bytes(git_url).length <= 200, "invalid git url");
        require(bytes(official_url).length <= 200, "invalid official url");
        require(bytes(official_email).length <= 50, "invalid official email");

        uint256 id = ++no;
        ids.push(id);
        id2index[id] = ids.length - 1;

        DAppInfo storage info = dapps[id];
        info.id = id;
        info.name = name;
        info.contract_addr = contract_addr;
        info.run_url = run_url;
        info.git_url = git_url;
        info.official_url = official_url;
        info.official_email = official_email;
        info.official_account = msg.sender;

        name2id[name] = id;
        contractAddr2id[contract_addr] = id;
        runUrl2id[run_url] = id;

        account2ids[msg.sender].push(id);
        accountId2index[msg.sender][id] = account2ids[msg.sender].length - 1;

        emit DAppRegister(id, name, msg.sender);
    }

    function setName(uint256 id, string memory name) public {
        require(bytes(name).length >= 5 && bytes(name).length <= 50, "invalid name");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        string memory old = dapps[id].name;
        dapps[id].name = name;
        name2id[name] = id;
        delete name2id[old];
        emit DAppUpdateName(id, old, name);
    }

    function setContractAddr(uint256 id, address addr) public {
        require(addr != address(0), "invalid contract address");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        address old = dapps[id].contract_addr;
        dapps[id].contract_addr = addr;
        contractAddr2id[addr] = id;
        delete contractAddr2id[old];
        emit DAppUpdateContractAddr(id, old, addr);
    }

    function setRunUrl(uint256 id, string memory url) public {
        require(bytes(url).length >= 15 && bytes(url).length <= 200, "invalid run url");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        string memory old = dapps[id].run_url;
        dapps[id].run_url = url;
        runUrl2id[url] = id;
        delete runUrl2id[old];
        emit DAppUpdateRunUrl(id, old, url);
    }

    function setGitUrl(uint256 id, string memory url) public {
        require(bytes(url).length >= 20 && bytes(url).length <= 200, "invalid git url");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        string memory old = dapps[id].git_url;
        dapps[id].git_url = url;
        emit DAppUpdateGitUrl(id, old, url);
    }

    function setOfficialUrl(uint256 id, string memory url) public {
        require(bytes(url).length >= 15 && bytes(url).length <= 200, "invalid official url");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        string memory old = dapps[id].official_url;
        dapps[id].official_url = url;
        emit DAppUpdateOfficialUrl(id, old, url);
    }

    function setOfficialEmail(uint256 id, string memory email) public {
        require(bytes(email).length >= 5 && bytes(email).length <= 50, "invalid official email");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        string memory old = dapps[id].official_email;
        dapps[id].official_email = email;
        emit DAppUpdateOfficialEmail(id, old, email);
    }

    function setOfficialAccouont(uint256 id, address account) public {
        require(account != address(0), "invalid official account");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        dapps[id].official_account = account;

        account2ids[account].push(id);
        accountId2index[account][id] = account2ids[account].length - 1;

        uint256[] storage mineIds = account2ids[msg.sender];
        uint256 index = accountId2index[msg.sender][id];
        mineIds[index] = mineIds[mineIds.length - 1];
        mineIds.pop();
        delete accountId2index[msg.sender][id];

        emit DAppUpdateOfficialAccount(id, msg.sender, account);
    }

    function setKeyword(uint256 id, string memory keyword) public {
        require(bytes(keyword).length <= 200, "invalid keyword");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        string memory old = dapps[id].keyword;
        dapps[id].keyword = keyword;
        emit DAppUpdateKeyword(id, old, keyword);
    }

    function setLogo(uint256 id, bytes memory logo) public payable {
        require(logo.length > 0 && logo.length <= 512000, "invalid logo");
        require(msg.sender == dapps[id].official_account, "invalid account");
        require(!dapps[id].isFrozen, "frozen");
        require(msg.value >= getLogoPayAmount(), "invalid pay amount");
        (bool success, ) = getLogoPayAddress().call{value: msg.value}("");
        require(success, "pay failed");
        logos[id] = logo;
        emit DAppUpdateLogo(id);
    }

    function remove(uint256 id) public {
        require(dapps[id].id != 0, "non-existent dapp");
        require(msg.sender == dapps[id].official_account, "invalid account");

        uint256 pos = id2index[id];
        ids[pos] = ids[ids.length - 1];
        ids.pop();
        delete id2index[id];

        string memory name = dapps[id].name;
        address addr = dapps[id].contract_addr;
        string memory url = dapps[id].run_url;
        delete dapps[id];
        delete name2id[name];
        delete contractAddr2id[addr];
        delete runUrl2id[url];

        uint256[] storage mineIds = account2ids[msg.sender];
        uint256 index = accountId2index[msg.sender][id];
        mineIds[index] = mineIds[mineIds.length - 1];
        mineIds.pop();
        delete accountId2index[msg.sender][id];

        emit DAppRemove(id, name, msg.sender);
    }

    function markFraud(uint256 id, bool flag) public {
        if(flag) {
            require(!userMarkedDApps[msg.sender][id], "already mark");
            userMarkedDApps[msg.sender][id] = true;
            dapps[id].fraudNum++;
        } else {
            require(userMarkedDApps[msg.sender][id], "non-existent mark");
            userMarkedDApps[msg.sender][id] = false;
            dapps[id].fraudNum--;
        }
        emit DAppUpdateFraudNum(id, dapps[id].fraudNum);
    }

    function freeze(uint256 id, bool flag) public onlyOwner {
        if(flag) {
            require(!dapps[id].isFrozen, "already frozen");
            dapps[id].isFrozen = true;
            emit DAppFreeze(id);
        } else {
            require(dapps[id].isFrozen, "non-existent frozen");
            dapps[id].isFrozen = false;
            emit DAppUnfreeze(id);
        }
    }

    function getInfo(uint256 id) public view returns (DAppInfo memory) {
        return dapps[id];
    }

    function getInfoByName(string memory name) public view returns (DAppInfo memory) {
        return dapps[name2id[name]];
    }

    function getInfoByContractAddr(address addr) public view returns (DAppInfo memory) {
        return dapps[contractAddr2id[addr]];
    }

    function getInfoByRunUrl(string memory url) public view returns (DAppInfo memory) {
        return dapps[runUrl2id[url]];
    }

    function getLogo(uint256 id) public view returns (bytes memory) {
        return logos[id];
    }

    function getNum() public view returns (uint256) {
        return ids.length;
    }

    function getIDs(uint256 start, uint256 count) public view returns (uint256[] memory) {
        require(ids.length > 0, "insufficient quantity");
        require(start < ids.length, "invalid start, must be in [0, getNum())");
        require(count > 0 && count <= 100, "max return 100 ids");

        uint256 num = count;
        if(start + count >= ids.length) {
            num = ids.length - start;
        }
        uint256[] memory ret = new uint256[](num);
        for(uint256 i; i < num; i++) {
            ret[i] = ids[i + start];
        }
        return ret;
    }

    function getMineNum(address account) public view returns (uint256) {
        return account2ids[account].length;
    }

    function getMineIDs(address account, uint256 start, uint256 count) public view returns (uint256[] memory) {
        uint256 mineNum = account2ids[account].length;
        require(mineNum > 0, "insufficient quantity");
        require(start < mineNum, "invalid start, must be in [0, getMineNum())");
        require(count > 0 && count <= 100, "max return 100 ids");

        uint256 num = count;
        if(start + count >= mineNum) {
            num = mineNum - start;
        }
        uint256[] memory ret = new uint256[](num);
        for(uint256 i; i < num; i++) {
            ret[i] = account2ids[account][i + start];
        }
        return ret;
    }

    function existID(uint256 id) public view returns (bool) {
        return dapps[id].id != 0;
    }

    function existName(string memory name) public view returns (bool) {
        return name2id[name] != 0;
    }

    function existContractAddr(address addr) public view returns (bool) {
        return contractAddr2id[addr] != 0;
    }

    function existRunUrl(string memory url) public view returns (bool) {
        return runUrl2id[url] != 0;
    }

    function isMarkedFraud(address account, uint256 id) public view returns (bool) {
        return userMarkedDApps[account][id];
    }

    function isFrozen(uint256 id) public view returns (bool) {
        return dapps[id].isFrozen;
    }

    function getLogoPayAmount() public view returns (uint256) {
        (bool success, bytes memory data) = address(0x0000000000000000000000000000000000001000).staticcall(abi.encodeWithSignature("getOfficialValue(string)", "logo_payamount"));
        require(success, "get logo_payamount failed");
        return abi.decode(data, (uint256));
    }

    function getLogoPayAddress() public view returns (address) {
        (bool success, bytes memory data) = address(0x0000000000000000000000000000000000001000).staticcall(abi.encodeWithSignature("getOfficialValue(string)", "logo_payaddress"));
        require(success, "get logo_payaddress failed");
        return abi.decode(data, (address));
    }
}