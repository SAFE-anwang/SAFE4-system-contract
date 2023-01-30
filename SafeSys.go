// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SafeSys

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
)

// AccountRecordBindInfo is an auto generated low-level Go binding around an user-defined struct.
type AccountRecordBindInfo struct {
	BindHeight   *big.Int
	UnbindHeight *big.Int
}

// AccountRecordData is an auto generated low-level Go binding around an user-defined struct.
type AccountRecordData struct {
	Id           [20]byte
	Addr         common.Address
	Amount       *big.Int
	LockDay      *big.Int
	StartHeight  *big.Int
	UnlockHeight *big.Int
	CreateTime   *big.Int
	UpdateTime   *big.Int
	BindInfo     AccountRecordBindInfo
}

// MasterNodeInfoData is an auto generated low-level Go binding around an user-defined struct.
type MasterNodeInfoData struct {
	Id          *big.Int
	Creator     common.Address
	Amount      *big.Int
	Addr        common.Address
	Ip          string
	Pubkey      string
	Description string
	State       *big.Int
	Founders    []MasterNodeInfoMemberInfo
	CreateTime  *big.Int
	UpdateTime  *big.Int
}

// MasterNodeInfoMemberInfo is an auto generated low-level Go binding around an user-defined struct.
type MasterNodeInfoMemberInfo struct {
	LockID [20]byte
	Addr   common.Address
	Amount *big.Int
}

// SuperMasterNodeInfoData is an auto generated low-level Go binding around an user-defined struct.
type SuperMasterNodeInfoData struct {
	Id               [20]byte
	Creator          common.Address
	Amount           *big.Int
	Addr             common.Address
	Ip               string
	Pubkey           string
	Description      string
	State            *big.Int
	Founders         []SuperMasterNodeInfoMemberInfo
	TotalVoterAmount *big.Int
	Voters           []SuperMasterNodeInfoMemberInfo
	IncentivePlan    SuperMasterNodeInfoIncentivePlan
	CreateTime       *big.Int
	UpdateTime       *big.Int
}

// SuperMasterNodeInfoIncentivePlan is an auto generated low-level Go binding around an user-defined struct.
type SuperMasterNodeInfoIncentivePlan struct {
	Creator *big.Int
	Partner *big.Int
	Voter   *big.Int
}

// SuperMasterNodeInfoMemberInfo is an auto generated low-level Go binding around an user-defined struct.
type SuperMasterNodeInfoMemberInfo struct {
	LockID [20]byte
	Addr   common.Address
	Amount *big.Int
}

// SafeSysMetaData contains all meta data concerning the SafeSys contract.
var SafeSysMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint8\",\"name\":\"version\",\"type\":\"uint8\"}],\"name\":\"Initialized\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"previousOwner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"OwnershipTransferred\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"GetInitializeData\",\"outputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\"}],\"stateMutability\":\"pure\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes20\",\"name\":\"_lockID\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"_mnAddr\",\"type\":\"address\"}],\"name\":\"appendRegisteMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_mnAddr\",\"type\":\"address\"}],\"name\":\"appendRegisteMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"}],\"name\":\"appendRegisteSMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes20\",\"name\":\"_lockID\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"}],\"name\":\"appendRegisteSMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"applyProposal\",\"outputs\":[{\"internalType\":\"bytes20\",\"name\":\"\",\"type\":\"bytes20\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_name\",\"type\":\"string\"},{\"internalType\":\"bytes\",\"name\":\"_value\",\"type\":\"bytes\"},{\"internalType\":\"string\",\"name\":\"_reason\",\"type\":\"string\"}],\"name\":\"applyUpdateProperty\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_proxyAddr\",\"type\":\"address\"},{\"internalType\":\"bytes20\",\"name\":\"_recordID\",\"type\":\"bytes20\"}],\"name\":\"approvalVote4SMN\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_newAddr\",\"type\":\"address\"}],\"name\":\"changeMNAddress\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_newDescription\",\"type\":\"string\"}],\"name\":\"changeMNDescription\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_newIP\",\"type\":\"string\"}],\"name\":\"changeMNIP\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_newPubkey\",\"type\":\"string\"}],\"name\":\"changeMNPubkey\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_newAddr\",\"type\":\"address\"}],\"name\":\"changeSMNAddress\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_newDescription\",\"type\":\"string\"}],\"name\":\"changeSMNDescription\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_newIP\",\"type\":\"string\"}],\"name\":\"changeSMNIP\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_newPubkey\",\"type\":\"string\"}],\"name\":\"changeSMNPubkey\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"deposit\",\"outputs\":[{\"internalType\":\"bytes20\",\"name\":\"\",\"type\":\"bytes20\"}],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAccountRecords\",\"outputs\":[{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"id\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"lockDay\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"startHeight\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"unlockHeight\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"createTime\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"updateTime\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"uint256\",\"name\":\"bindHeight\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"unbindHeight\",\"type\":\"uint256\"}],\"internalType\":\"structAccountRecord.BindInfo\",\"name\":\"bindInfo\",\"type\":\"tuple\"}],\"internalType\":\"structAccountRecord.Data[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getApprovalVote4SMN\",\"outputs\":[{\"internalType\":\"address[]\",\"name\":\"\",\"type\":\"address[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAvailableAmount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"bytes20[]\",\"name\":\"\",\"type\":\"bytes20[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getBindAMount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"bytes20[]\",\"name\":\"\",\"type\":\"bytes20[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getLockAmount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"bytes20[]\",\"name\":\"\",\"type\":\"bytes20[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_mnAddr\",\"type\":\"address\"}],\"name\":\"getMNInfo\",\"outputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"creator\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"string\",\"name\":\"ip\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"pubkey\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"description\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"state\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"lockID\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"internalType\":\"structMasterNodeInfo.MemberInfo[]\",\"name\":\"founders\",\"type\":\"tuple[]\"},{\"internalType\":\"uint256\",\"name\":\"createTime\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"updateTime\",\"type\":\"uint256\"}],\"internalType\":\"structMasterNodeInfo.Data\",\"name\":\"\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"}],\"name\":\"getSMNInfo\",\"outputs\":[{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"id\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"creator\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"string\",\"name\":\"ip\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"pubkey\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"description\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"state\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"lockID\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.MemberInfo[]\",\"name\":\"founders\",\"type\":\"tuple[]\"},{\"internalType\":\"uint256\",\"name\":\"totalVoterAmount\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"lockID\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.MemberInfo[]\",\"name\":\"voters\",\"type\":\"tuple[]\"},{\"components\":[{\"internalType\":\"uint256\",\"name\":\"creator\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"partner\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"voter\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.IncentivePlan\",\"name\":\"incentivePlan\",\"type\":\"tuple\"},{\"internalType\":\"uint256\",\"name\":\"createTime\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"updateTime\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.Data\",\"name\":\"\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getTopSMN\",\"outputs\":[{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"id\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"creator\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"string\",\"name\":\"ip\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"pubkey\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"description\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"state\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"lockID\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.MemberInfo[]\",\"name\":\"founders\",\"type\":\"tuple[]\"},{\"internalType\":\"uint256\",\"name\":\"totalVoterAmount\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"bytes20\",\"name\":\"lockID\",\"type\":\"bytes20\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.MemberInfo[]\",\"name\":\"voters\",\"type\":\"tuple[]\"},{\"components\":[{\"internalType\":\"uint256\",\"name\":\"creator\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"partner\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"voter\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.IncentivePlan\",\"name\":\"incentivePlan\",\"type\":\"tuple\"},{\"internalType\":\"uint256\",\"name\":\"createTime\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"updateTime\",\"type\":\"uint256\"}],\"internalType\":\"structSuperMasterNodeInfo.Data[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getTotalAmount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"bytes20[]\",\"name\":\"\",\"type\":\"bytes20[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"initialize\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"}],\"name\":\"lock\",\"outputs\":[{\"internalType\":\"bytes20\",\"name\":\"\",\"type\":\"bytes20\"}],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_mnAddr\",\"type\":\"address\"},{\"internalType\":\"string\",\"name\":\"_ip\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_pubkey\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_description\",\"type\":\"string\"}],\"name\":\"registeMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"},{\"internalType\":\"string\",\"name\":\"_ip\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_pubkey\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_description\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"_creatorIncentive\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_partnerIncentive\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_voterIncentive\",\"type\":\"uint256\"}],\"name\":\"registeSMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"removeAllApprovalVote4SMN\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes20[]\",\"name\":\"_recordIDs\",\"type\":\"bytes20[]\"}],\"name\":\"removeApprovalVote4SMN\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes20[]\",\"name\":\"_recordIDs\",\"type\":\"bytes20[]\"}],\"name\":\"removeVote4SMN\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"removeVote4SMN\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"renounceOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_smnAmount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_mnAddr\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_mnAmount\",\"type\":\"uint256\"}],\"name\":\"reward\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"transfer\",\"outputs\":[{\"internalType\":\"bytes20\",\"name\":\"\",\"type\":\"bytes20\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"}],\"name\":\"transferLock\",\"outputs\":[{\"internalType\":\"bytes20\",\"name\":\"\",\"type\":\"bytes20\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"transferOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_mnAddr\",\"type\":\"address\"},{\"internalType\":\"string\",\"name\":\"_ip\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_pubkey\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_description\",\"type\":\"string\"}],\"name\":\"unionRegisteMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_lockDay\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"},{\"internalType\":\"string\",\"name\":\"_ip\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_pubkey\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"_description\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"_creatorIncentive\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_partnerIncentive\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_voterIncentive\",\"type\":\"uint256\"}],\"name\":\"unionRegisteSMN\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256[]\",\"name\":\"_ids\",\"type\":\"uint256[]\"},{\"internalType\":\"uint8[]\",\"name\":\"_states\",\"type\":\"uint8[]\"}],\"name\":\"uploadMasterNodeState\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes20[]\",\"name\":\"_ids\",\"type\":\"bytes20[]\"},{\"internalType\":\"uint8[]\",\"name\":\"_states\",\"type\":\"uint8[]\"}],\"name\":\"uploadSuperMasterNodeState\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"}],\"name\":\"verifySMN\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_smnAddr\",\"type\":\"address\"},{\"internalType\":\"bytes20\",\"name\":\"_recordID\",\"type\":\"bytes20\"}],\"name\":\"vote4SMN\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes20\",\"name\":\"_proposalID\",\"type\":\"bytes20\"},{\"internalType\":\"uint256\",\"name\":\"_result\",\"type\":\"uint256\"}],\"name\":\"vote4proposal\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_name\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"_result\",\"type\":\"uint256\"}],\"name\":\"vote4updateProperty\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"withdraw\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes20[]\",\"name\":\"recordIDs\",\"type\":\"bytes20[]\"}],\"name\":\"withdraw\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
}

// SafeSysABI is the input ABI used to generate the binding from.
// Deprecated: Use SafeSysMetaData.ABI instead.
var SafeSysABI = SafeSysMetaData.ABI

// SafeSys is an auto generated Go binding around an Ethereum contract.
type SafeSys struct {
	SafeSysCaller     // Read-only binding to the contract
	SafeSysTransactor // Write-only binding to the contract
	SafeSysFilterer   // Log filterer for contract events
}

// SafeSysCaller is an auto generated read-only Go binding around an Ethereum contract.
type SafeSysCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SafeSysTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SafeSysTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SafeSysFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SafeSysFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SafeSysSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SafeSysSession struct {
	Contract     *SafeSys          // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SafeSysCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SafeSysCallerSession struct {
	Contract *SafeSysCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts  // Call options to use throughout this session
}

// SafeSysTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SafeSysTransactorSession struct {
	Contract     *SafeSysTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts  // Transaction auth options to use throughout this session
}

// SafeSysRaw is an auto generated low-level Go binding around an Ethereum contract.
type SafeSysRaw struct {
	Contract *SafeSys // Generic contract binding to access the raw methods on
}

// SafeSysCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SafeSysCallerRaw struct {
	Contract *SafeSysCaller // Generic read-only contract binding to access the raw methods on
}

// SafeSysTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SafeSysTransactorRaw struct {
	Contract *SafeSysTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSafeSys creates a new instance of SafeSys, bound to a specific deployed contract.
func NewSafeSys(address common.Address, backend bind.ContractBackend) (*SafeSys, error) {
	contract, err := bindSafeSys(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SafeSys{SafeSysCaller: SafeSysCaller{contract: contract}, SafeSysTransactor: SafeSysTransactor{contract: contract}, SafeSysFilterer: SafeSysFilterer{contract: contract}}, nil
}

// NewSafeSysCaller creates a new read-only instance of SafeSys, bound to a specific deployed contract.
func NewSafeSysCaller(address common.Address, caller bind.ContractCaller) (*SafeSysCaller, error) {
	contract, err := bindSafeSys(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SafeSysCaller{contract: contract}, nil
}

// NewSafeSysTransactor creates a new write-only instance of SafeSys, bound to a specific deployed contract.
func NewSafeSysTransactor(address common.Address, transactor bind.ContractTransactor) (*SafeSysTransactor, error) {
	contract, err := bindSafeSys(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SafeSysTransactor{contract: contract}, nil
}

// NewSafeSysFilterer creates a new log filterer instance of SafeSys, bound to a specific deployed contract.
func NewSafeSysFilterer(address common.Address, filterer bind.ContractFilterer) (*SafeSysFilterer, error) {
	contract, err := bindSafeSys(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SafeSysFilterer{contract: contract}, nil
}

// bindSafeSys binds a generic wrapper to an already deployed contract.
func bindSafeSys(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(SafeSysABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SafeSys *SafeSysRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SafeSys.Contract.SafeSysCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SafeSys *SafeSysRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.Contract.SafeSysTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SafeSys *SafeSysRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SafeSys.Contract.SafeSysTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SafeSys *SafeSysCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SafeSys.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SafeSys *SafeSysTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SafeSys *SafeSysTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SafeSys.Contract.contract.Transact(opts, method, params...)
}

// GetInitializeData is a free data retrieval call binding the contract method 0xd3d655f8.
//
// Solidity: function GetInitializeData() pure returns(bytes)
func (_SafeSys *SafeSysCaller) GetInitializeData(opts *bind.CallOpts) ([]byte, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "GetInitializeData")

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// GetInitializeData is a free data retrieval call binding the contract method 0xd3d655f8.
//
// Solidity: function GetInitializeData() pure returns(bytes)
func (_SafeSys *SafeSysSession) GetInitializeData() ([]byte, error) {
	return _SafeSys.Contract.GetInitializeData(&_SafeSys.CallOpts)
}

// GetInitializeData is a free data retrieval call binding the contract method 0xd3d655f8.
//
// Solidity: function GetInitializeData() pure returns(bytes)
func (_SafeSys *SafeSysCallerSession) GetInitializeData() ([]byte, error) {
	return _SafeSys.Contract.GetInitializeData(&_SafeSys.CallOpts)
}

// ApplyProposal is a free data retrieval call binding the contract method 0x0ad5c979.
//
// Solidity: function applyProposal() view returns(bytes20)
func (_SafeSys *SafeSysCaller) ApplyProposal(opts *bind.CallOpts) ([20]byte, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "applyProposal")

	if err != nil {
		return *new([20]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([20]byte)).(*[20]byte)

	return out0, err

}

// ApplyProposal is a free data retrieval call binding the contract method 0x0ad5c979.
//
// Solidity: function applyProposal() view returns(bytes20)
func (_SafeSys *SafeSysSession) ApplyProposal() ([20]byte, error) {
	return _SafeSys.Contract.ApplyProposal(&_SafeSys.CallOpts)
}

// ApplyProposal is a free data retrieval call binding the contract method 0x0ad5c979.
//
// Solidity: function applyProposal() view returns(bytes20)
func (_SafeSys *SafeSysCallerSession) ApplyProposal() ([20]byte, error) {
	return _SafeSys.Contract.ApplyProposal(&_SafeSys.CallOpts)
}

// GetAccountRecords is a free data retrieval call binding the contract method 0xa208001a.
//
// Solidity: function getAccountRecords() view returns((bytes20,address,uint256,uint256,uint256,uint256,uint256,uint256,(uint256,uint256))[])
func (_SafeSys *SafeSysCaller) GetAccountRecords(opts *bind.CallOpts) ([]AccountRecordData, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getAccountRecords")

	if err != nil {
		return *new([]AccountRecordData), err
	}

	out0 := *abi.ConvertType(out[0], new([]AccountRecordData)).(*[]AccountRecordData)

	return out0, err

}

// GetAccountRecords is a free data retrieval call binding the contract method 0xa208001a.
//
// Solidity: function getAccountRecords() view returns((bytes20,address,uint256,uint256,uint256,uint256,uint256,uint256,(uint256,uint256))[])
func (_SafeSys *SafeSysSession) GetAccountRecords() ([]AccountRecordData, error) {
	return _SafeSys.Contract.GetAccountRecords(&_SafeSys.CallOpts)
}

// GetAccountRecords is a free data retrieval call binding the contract method 0xa208001a.
//
// Solidity: function getAccountRecords() view returns((bytes20,address,uint256,uint256,uint256,uint256,uint256,uint256,(uint256,uint256))[])
func (_SafeSys *SafeSysCallerSession) GetAccountRecords() ([]AccountRecordData, error) {
	return _SafeSys.Contract.GetAccountRecords(&_SafeSys.CallOpts)
}

// GetApprovalVote4SMN is a free data retrieval call binding the contract method 0x0ec79f2a.
//
// Solidity: function getApprovalVote4SMN() view returns(address[])
func (_SafeSys *SafeSysCaller) GetApprovalVote4SMN(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getApprovalVote4SMN")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetApprovalVote4SMN is a free data retrieval call binding the contract method 0x0ec79f2a.
//
// Solidity: function getApprovalVote4SMN() view returns(address[])
func (_SafeSys *SafeSysSession) GetApprovalVote4SMN() ([]common.Address, error) {
	return _SafeSys.Contract.GetApprovalVote4SMN(&_SafeSys.CallOpts)
}

// GetApprovalVote4SMN is a free data retrieval call binding the contract method 0x0ec79f2a.
//
// Solidity: function getApprovalVote4SMN() view returns(address[])
func (_SafeSys *SafeSysCallerSession) GetApprovalVote4SMN() ([]common.Address, error) {
	return _SafeSys.Contract.GetApprovalVote4SMN(&_SafeSys.CallOpts)
}

// GetAvailableAmount is a free data retrieval call binding the contract method 0x7bb476f5.
//
// Solidity: function getAvailableAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCaller) GetAvailableAmount(opts *bind.CallOpts) (*big.Int, [][20]byte, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getAvailableAmount")

	if err != nil {
		return *new(*big.Int), *new([][20]byte), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new([][20]byte)).(*[][20]byte)

	return out0, out1, err

}

// GetAvailableAmount is a free data retrieval call binding the contract method 0x7bb476f5.
//
// Solidity: function getAvailableAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysSession) GetAvailableAmount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetAvailableAmount(&_SafeSys.CallOpts)
}

// GetAvailableAmount is a free data retrieval call binding the contract method 0x7bb476f5.
//
// Solidity: function getAvailableAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCallerSession) GetAvailableAmount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetAvailableAmount(&_SafeSys.CallOpts)
}

// GetBindAMount is a free data retrieval call binding the contract method 0x8a29ebd9.
//
// Solidity: function getBindAMount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCaller) GetBindAMount(opts *bind.CallOpts) (*big.Int, [][20]byte, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getBindAMount")

	if err != nil {
		return *new(*big.Int), *new([][20]byte), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new([][20]byte)).(*[][20]byte)

	return out0, out1, err

}

// GetBindAMount is a free data retrieval call binding the contract method 0x8a29ebd9.
//
// Solidity: function getBindAMount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysSession) GetBindAMount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetBindAMount(&_SafeSys.CallOpts)
}

// GetBindAMount is a free data retrieval call binding the contract method 0x8a29ebd9.
//
// Solidity: function getBindAMount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCallerSession) GetBindAMount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetBindAMount(&_SafeSys.CallOpts)
}

// GetLockAmount is a free data retrieval call binding the contract method 0xd64c34fc.
//
// Solidity: function getLockAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCaller) GetLockAmount(opts *bind.CallOpts) (*big.Int, [][20]byte, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getLockAmount")

	if err != nil {
		return *new(*big.Int), *new([][20]byte), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new([][20]byte)).(*[][20]byte)

	return out0, out1, err

}

// GetLockAmount is a free data retrieval call binding the contract method 0xd64c34fc.
//
// Solidity: function getLockAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysSession) GetLockAmount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetLockAmount(&_SafeSys.CallOpts)
}

// GetLockAmount is a free data retrieval call binding the contract method 0xd64c34fc.
//
// Solidity: function getLockAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCallerSession) GetLockAmount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetLockAmount(&_SafeSys.CallOpts)
}

// GetMNInfo is a free data retrieval call binding the contract method 0x885abebd.
//
// Solidity: function getMNInfo(address _mnAddr) view returns((uint256,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,uint256))
func (_SafeSys *SafeSysCaller) GetMNInfo(opts *bind.CallOpts, _mnAddr common.Address) (MasterNodeInfoData, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getMNInfo", _mnAddr)

	if err != nil {
		return *new(MasterNodeInfoData), err
	}

	out0 := *abi.ConvertType(out[0], new(MasterNodeInfoData)).(*MasterNodeInfoData)

	return out0, err

}

// GetMNInfo is a free data retrieval call binding the contract method 0x885abebd.
//
// Solidity: function getMNInfo(address _mnAddr) view returns((uint256,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,uint256))
func (_SafeSys *SafeSysSession) GetMNInfo(_mnAddr common.Address) (MasterNodeInfoData, error) {
	return _SafeSys.Contract.GetMNInfo(&_SafeSys.CallOpts, _mnAddr)
}

// GetMNInfo is a free data retrieval call binding the contract method 0x885abebd.
//
// Solidity: function getMNInfo(address _mnAddr) view returns((uint256,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,uint256))
func (_SafeSys *SafeSysCallerSession) GetMNInfo(_mnAddr common.Address) (MasterNodeInfoData, error) {
	return _SafeSys.Contract.GetMNInfo(&_SafeSys.CallOpts, _mnAddr)
}

// GetSMNInfo is a free data retrieval call binding the contract method 0x8c1ad5b8.
//
// Solidity: function getSMNInfo(address _smnAddr) view returns((bytes20,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,(bytes20,address,uint256)[],(uint256,uint256,uint256),uint256,uint256))
func (_SafeSys *SafeSysCaller) GetSMNInfo(opts *bind.CallOpts, _smnAddr common.Address) (SuperMasterNodeInfoData, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getSMNInfo", _smnAddr)

	if err != nil {
		return *new(SuperMasterNodeInfoData), err
	}

	out0 := *abi.ConvertType(out[0], new(SuperMasterNodeInfoData)).(*SuperMasterNodeInfoData)

	return out0, err

}

// GetSMNInfo is a free data retrieval call binding the contract method 0x8c1ad5b8.
//
// Solidity: function getSMNInfo(address _smnAddr) view returns((bytes20,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,(bytes20,address,uint256)[],(uint256,uint256,uint256),uint256,uint256))
func (_SafeSys *SafeSysSession) GetSMNInfo(_smnAddr common.Address) (SuperMasterNodeInfoData, error) {
	return _SafeSys.Contract.GetSMNInfo(&_SafeSys.CallOpts, _smnAddr)
}

// GetSMNInfo is a free data retrieval call binding the contract method 0x8c1ad5b8.
//
// Solidity: function getSMNInfo(address _smnAddr) view returns((bytes20,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,(bytes20,address,uint256)[],(uint256,uint256,uint256),uint256,uint256))
func (_SafeSys *SafeSysCallerSession) GetSMNInfo(_smnAddr common.Address) (SuperMasterNodeInfoData, error) {
	return _SafeSys.Contract.GetSMNInfo(&_SafeSys.CallOpts, _smnAddr)
}

// GetTopSMN is a free data retrieval call binding the contract method 0xeb2eed3a.
//
// Solidity: function getTopSMN() view returns((bytes20,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,(bytes20,address,uint256)[],(uint256,uint256,uint256),uint256,uint256)[])
func (_SafeSys *SafeSysCaller) GetTopSMN(opts *bind.CallOpts) ([]SuperMasterNodeInfoData, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getTopSMN")

	if err != nil {
		return *new([]SuperMasterNodeInfoData), err
	}

	out0 := *abi.ConvertType(out[0], new([]SuperMasterNodeInfoData)).(*[]SuperMasterNodeInfoData)

	return out0, err

}

// GetTopSMN is a free data retrieval call binding the contract method 0xeb2eed3a.
//
// Solidity: function getTopSMN() view returns((bytes20,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,(bytes20,address,uint256)[],(uint256,uint256,uint256),uint256,uint256)[])
func (_SafeSys *SafeSysSession) GetTopSMN() ([]SuperMasterNodeInfoData, error) {
	return _SafeSys.Contract.GetTopSMN(&_SafeSys.CallOpts)
}

// GetTopSMN is a free data retrieval call binding the contract method 0xeb2eed3a.
//
// Solidity: function getTopSMN() view returns((bytes20,address,uint256,address,string,string,string,uint256,(bytes20,address,uint256)[],uint256,(bytes20,address,uint256)[],(uint256,uint256,uint256),uint256,uint256)[])
func (_SafeSys *SafeSysCallerSession) GetTopSMN() ([]SuperMasterNodeInfoData, error) {
	return _SafeSys.Contract.GetTopSMN(&_SafeSys.CallOpts)
}

// GetTotalAmount is a free data retrieval call binding the contract method 0x65ac4341.
//
// Solidity: function getTotalAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCaller) GetTotalAmount(opts *bind.CallOpts) (*big.Int, [][20]byte, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "getTotalAmount")

	if err != nil {
		return *new(*big.Int), *new([][20]byte), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new([][20]byte)).(*[][20]byte)

	return out0, out1, err

}

// GetTotalAmount is a free data retrieval call binding the contract method 0x65ac4341.
//
// Solidity: function getTotalAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysSession) GetTotalAmount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetTotalAmount(&_SafeSys.CallOpts)
}

// GetTotalAmount is a free data retrieval call binding the contract method 0x65ac4341.
//
// Solidity: function getTotalAmount() view returns(uint256, bytes20[])
func (_SafeSys *SafeSysCallerSession) GetTotalAmount() (*big.Int, [][20]byte, error) {
	return _SafeSys.Contract.GetTotalAmount(&_SafeSys.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_SafeSys *SafeSysCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SafeSys.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_SafeSys *SafeSysSession) Owner() (common.Address, error) {
	return _SafeSys.Contract.Owner(&_SafeSys.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_SafeSys *SafeSysCallerSession) Owner() (common.Address, error) {
	return _SafeSys.Contract.Owner(&_SafeSys.CallOpts)
}

// AppendRegisteMN is a paid mutator transaction binding the contract method 0x01070bb2.
//
// Solidity: function appendRegisteMN(bytes20 _lockID, address _mnAddr) payable returns()
func (_SafeSys *SafeSysTransactor) AppendRegisteMN(opts *bind.TransactOpts, _lockID [20]byte, _mnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "appendRegisteMN", _lockID, _mnAddr)
}

// AppendRegisteMN is a paid mutator transaction binding the contract method 0x01070bb2.
//
// Solidity: function appendRegisteMN(bytes20 _lockID, address _mnAddr) payable returns()
func (_SafeSys *SafeSysSession) AppendRegisteMN(_lockID [20]byte, _mnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteMN(&_SafeSys.TransactOpts, _lockID, _mnAddr)
}

// AppendRegisteMN is a paid mutator transaction binding the contract method 0x01070bb2.
//
// Solidity: function appendRegisteMN(bytes20 _lockID, address _mnAddr) payable returns()
func (_SafeSys *SafeSysTransactorSession) AppendRegisteMN(_lockID [20]byte, _mnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteMN(&_SafeSys.TransactOpts, _lockID, _mnAddr)
}

// AppendRegisteMN0 is a paid mutator transaction binding the contract method 0xaed16180.
//
// Solidity: function appendRegisteMN(uint256 _lockDay, address _mnAddr) payable returns()
func (_SafeSys *SafeSysTransactor) AppendRegisteMN0(opts *bind.TransactOpts, _lockDay *big.Int, _mnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "appendRegisteMN0", _lockDay, _mnAddr)
}

// AppendRegisteMN0 is a paid mutator transaction binding the contract method 0xaed16180.
//
// Solidity: function appendRegisteMN(uint256 _lockDay, address _mnAddr) payable returns()
func (_SafeSys *SafeSysSession) AppendRegisteMN0(_lockDay *big.Int, _mnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteMN0(&_SafeSys.TransactOpts, _lockDay, _mnAddr)
}

// AppendRegisteMN0 is a paid mutator transaction binding the contract method 0xaed16180.
//
// Solidity: function appendRegisteMN(uint256 _lockDay, address _mnAddr) payable returns()
func (_SafeSys *SafeSysTransactorSession) AppendRegisteMN0(_lockDay *big.Int, _mnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteMN0(&_SafeSys.TransactOpts, _lockDay, _mnAddr)
}

// AppendRegisteSMN is a paid mutator transaction binding the contract method 0x0de1008f.
//
// Solidity: function appendRegisteSMN(uint256 _lockDay, address _smnAddr) payable returns()
func (_SafeSys *SafeSysTransactor) AppendRegisteSMN(opts *bind.TransactOpts, _lockDay *big.Int, _smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "appendRegisteSMN", _lockDay, _smnAddr)
}

// AppendRegisteSMN is a paid mutator transaction binding the contract method 0x0de1008f.
//
// Solidity: function appendRegisteSMN(uint256 _lockDay, address _smnAddr) payable returns()
func (_SafeSys *SafeSysSession) AppendRegisteSMN(_lockDay *big.Int, _smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteSMN(&_SafeSys.TransactOpts, _lockDay, _smnAddr)
}

// AppendRegisteSMN is a paid mutator transaction binding the contract method 0x0de1008f.
//
// Solidity: function appendRegisteSMN(uint256 _lockDay, address _smnAddr) payable returns()
func (_SafeSys *SafeSysTransactorSession) AppendRegisteSMN(_lockDay *big.Int, _smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteSMN(&_SafeSys.TransactOpts, _lockDay, _smnAddr)
}

// AppendRegisteSMN0 is a paid mutator transaction binding the contract method 0xd121f126.
//
// Solidity: function appendRegisteSMN(bytes20 _lockID, address _smnAddr) payable returns()
func (_SafeSys *SafeSysTransactor) AppendRegisteSMN0(opts *bind.TransactOpts, _lockID [20]byte, _smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "appendRegisteSMN0", _lockID, _smnAddr)
}

// AppendRegisteSMN0 is a paid mutator transaction binding the contract method 0xd121f126.
//
// Solidity: function appendRegisteSMN(bytes20 _lockID, address _smnAddr) payable returns()
func (_SafeSys *SafeSysSession) AppendRegisteSMN0(_lockID [20]byte, _smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteSMN0(&_SafeSys.TransactOpts, _lockID, _smnAddr)
}

// AppendRegisteSMN0 is a paid mutator transaction binding the contract method 0xd121f126.
//
// Solidity: function appendRegisteSMN(bytes20 _lockID, address _smnAddr) payable returns()
func (_SafeSys *SafeSysTransactorSession) AppendRegisteSMN0(_lockID [20]byte, _smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.AppendRegisteSMN0(&_SafeSys.TransactOpts, _lockID, _smnAddr)
}

// ApplyUpdateProperty is a paid mutator transaction binding the contract method 0x62df9ea6.
//
// Solidity: function applyUpdateProperty(string _name, bytes _value, string _reason) returns()
func (_SafeSys *SafeSysTransactor) ApplyUpdateProperty(opts *bind.TransactOpts, _name string, _value []byte, _reason string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "applyUpdateProperty", _name, _value, _reason)
}

// ApplyUpdateProperty is a paid mutator transaction binding the contract method 0x62df9ea6.
//
// Solidity: function applyUpdateProperty(string _name, bytes _value, string _reason) returns()
func (_SafeSys *SafeSysSession) ApplyUpdateProperty(_name string, _value []byte, _reason string) (*types.Transaction, error) {
	return _SafeSys.Contract.ApplyUpdateProperty(&_SafeSys.TransactOpts, _name, _value, _reason)
}

// ApplyUpdateProperty is a paid mutator transaction binding the contract method 0x62df9ea6.
//
// Solidity: function applyUpdateProperty(string _name, bytes _value, string _reason) returns()
func (_SafeSys *SafeSysTransactorSession) ApplyUpdateProperty(_name string, _value []byte, _reason string) (*types.Transaction, error) {
	return _SafeSys.Contract.ApplyUpdateProperty(&_SafeSys.TransactOpts, _name, _value, _reason)
}

// ApprovalVote4SMN is a paid mutator transaction binding the contract method 0xcf1f4dd2.
//
// Solidity: function approvalVote4SMN(address _proxyAddr, bytes20 _recordID) returns()
func (_SafeSys *SafeSysTransactor) ApprovalVote4SMN(opts *bind.TransactOpts, _proxyAddr common.Address, _recordID [20]byte) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "approvalVote4SMN", _proxyAddr, _recordID)
}

// ApprovalVote4SMN is a paid mutator transaction binding the contract method 0xcf1f4dd2.
//
// Solidity: function approvalVote4SMN(address _proxyAddr, bytes20 _recordID) returns()
func (_SafeSys *SafeSysSession) ApprovalVote4SMN(_proxyAddr common.Address, _recordID [20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.ApprovalVote4SMN(&_SafeSys.TransactOpts, _proxyAddr, _recordID)
}

// ApprovalVote4SMN is a paid mutator transaction binding the contract method 0xcf1f4dd2.
//
// Solidity: function approvalVote4SMN(address _proxyAddr, bytes20 _recordID) returns()
func (_SafeSys *SafeSysTransactorSession) ApprovalVote4SMN(_proxyAddr common.Address, _recordID [20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.ApprovalVote4SMN(&_SafeSys.TransactOpts, _proxyAddr, _recordID)
}

// ChangeMNAddress is a paid mutator transaction binding the contract method 0x7f9c2fa7.
//
// Solidity: function changeMNAddress(address _newAddr) returns()
func (_SafeSys *SafeSysTransactor) ChangeMNAddress(opts *bind.TransactOpts, _newAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeMNAddress", _newAddr)
}

// ChangeMNAddress is a paid mutator transaction binding the contract method 0x7f9c2fa7.
//
// Solidity: function changeMNAddress(address _newAddr) returns()
func (_SafeSys *SafeSysSession) ChangeMNAddress(_newAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNAddress(&_SafeSys.TransactOpts, _newAddr)
}

// ChangeMNAddress is a paid mutator transaction binding the contract method 0x7f9c2fa7.
//
// Solidity: function changeMNAddress(address _newAddr) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeMNAddress(_newAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNAddress(&_SafeSys.TransactOpts, _newAddr)
}

// ChangeMNDescription is a paid mutator transaction binding the contract method 0x504942fb.
//
// Solidity: function changeMNDescription(string _newDescription) returns()
func (_SafeSys *SafeSysTransactor) ChangeMNDescription(opts *bind.TransactOpts, _newDescription string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeMNDescription", _newDescription)
}

// ChangeMNDescription is a paid mutator transaction binding the contract method 0x504942fb.
//
// Solidity: function changeMNDescription(string _newDescription) returns()
func (_SafeSys *SafeSysSession) ChangeMNDescription(_newDescription string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNDescription(&_SafeSys.TransactOpts, _newDescription)
}

// ChangeMNDescription is a paid mutator transaction binding the contract method 0x504942fb.
//
// Solidity: function changeMNDescription(string _newDescription) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeMNDescription(_newDescription string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNDescription(&_SafeSys.TransactOpts, _newDescription)
}

// ChangeMNIP is a paid mutator transaction binding the contract method 0xabeaedbe.
//
// Solidity: function changeMNIP(string _newIP) returns()
func (_SafeSys *SafeSysTransactor) ChangeMNIP(opts *bind.TransactOpts, _newIP string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeMNIP", _newIP)
}

// ChangeMNIP is a paid mutator transaction binding the contract method 0xabeaedbe.
//
// Solidity: function changeMNIP(string _newIP) returns()
func (_SafeSys *SafeSysSession) ChangeMNIP(_newIP string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNIP(&_SafeSys.TransactOpts, _newIP)
}

// ChangeMNIP is a paid mutator transaction binding the contract method 0xabeaedbe.
//
// Solidity: function changeMNIP(string _newIP) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeMNIP(_newIP string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNIP(&_SafeSys.TransactOpts, _newIP)
}

// ChangeMNPubkey is a paid mutator transaction binding the contract method 0xc34ae301.
//
// Solidity: function changeMNPubkey(string _newPubkey) returns()
func (_SafeSys *SafeSysTransactor) ChangeMNPubkey(opts *bind.TransactOpts, _newPubkey string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeMNPubkey", _newPubkey)
}

// ChangeMNPubkey is a paid mutator transaction binding the contract method 0xc34ae301.
//
// Solidity: function changeMNPubkey(string _newPubkey) returns()
func (_SafeSys *SafeSysSession) ChangeMNPubkey(_newPubkey string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNPubkey(&_SafeSys.TransactOpts, _newPubkey)
}

// ChangeMNPubkey is a paid mutator transaction binding the contract method 0xc34ae301.
//
// Solidity: function changeMNPubkey(string _newPubkey) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeMNPubkey(_newPubkey string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeMNPubkey(&_SafeSys.TransactOpts, _newPubkey)
}

// ChangeSMNAddress is a paid mutator transaction binding the contract method 0xf90db405.
//
// Solidity: function changeSMNAddress(address _newAddr) returns()
func (_SafeSys *SafeSysTransactor) ChangeSMNAddress(opts *bind.TransactOpts, _newAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeSMNAddress", _newAddr)
}

// ChangeSMNAddress is a paid mutator transaction binding the contract method 0xf90db405.
//
// Solidity: function changeSMNAddress(address _newAddr) returns()
func (_SafeSys *SafeSysSession) ChangeSMNAddress(_newAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNAddress(&_SafeSys.TransactOpts, _newAddr)
}

// ChangeSMNAddress is a paid mutator transaction binding the contract method 0xf90db405.
//
// Solidity: function changeSMNAddress(address _newAddr) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeSMNAddress(_newAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNAddress(&_SafeSys.TransactOpts, _newAddr)
}

// ChangeSMNDescription is a paid mutator transaction binding the contract method 0x2939aecd.
//
// Solidity: function changeSMNDescription(string _newDescription) returns()
func (_SafeSys *SafeSysTransactor) ChangeSMNDescription(opts *bind.TransactOpts, _newDescription string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeSMNDescription", _newDescription)
}

// ChangeSMNDescription is a paid mutator transaction binding the contract method 0x2939aecd.
//
// Solidity: function changeSMNDescription(string _newDescription) returns()
func (_SafeSys *SafeSysSession) ChangeSMNDescription(_newDescription string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNDescription(&_SafeSys.TransactOpts, _newDescription)
}

// ChangeSMNDescription is a paid mutator transaction binding the contract method 0x2939aecd.
//
// Solidity: function changeSMNDescription(string _newDescription) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeSMNDescription(_newDescription string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNDescription(&_SafeSys.TransactOpts, _newDescription)
}

// ChangeSMNIP is a paid mutator transaction binding the contract method 0x3821b23f.
//
// Solidity: function changeSMNIP(string _newIP) returns()
func (_SafeSys *SafeSysTransactor) ChangeSMNIP(opts *bind.TransactOpts, _newIP string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeSMNIP", _newIP)
}

// ChangeSMNIP is a paid mutator transaction binding the contract method 0x3821b23f.
//
// Solidity: function changeSMNIP(string _newIP) returns()
func (_SafeSys *SafeSysSession) ChangeSMNIP(_newIP string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNIP(&_SafeSys.TransactOpts, _newIP)
}

// ChangeSMNIP is a paid mutator transaction binding the contract method 0x3821b23f.
//
// Solidity: function changeSMNIP(string _newIP) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeSMNIP(_newIP string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNIP(&_SafeSys.TransactOpts, _newIP)
}

// ChangeSMNPubkey is a paid mutator transaction binding the contract method 0x3ae96ab7.
//
// Solidity: function changeSMNPubkey(string _newPubkey) returns()
func (_SafeSys *SafeSysTransactor) ChangeSMNPubkey(opts *bind.TransactOpts, _newPubkey string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "changeSMNPubkey", _newPubkey)
}

// ChangeSMNPubkey is a paid mutator transaction binding the contract method 0x3ae96ab7.
//
// Solidity: function changeSMNPubkey(string _newPubkey) returns()
func (_SafeSys *SafeSysSession) ChangeSMNPubkey(_newPubkey string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNPubkey(&_SafeSys.TransactOpts, _newPubkey)
}

// ChangeSMNPubkey is a paid mutator transaction binding the contract method 0x3ae96ab7.
//
// Solidity: function changeSMNPubkey(string _newPubkey) returns()
func (_SafeSys *SafeSysTransactorSession) ChangeSMNPubkey(_newPubkey string) (*types.Transaction, error) {
	return _SafeSys.Contract.ChangeSMNPubkey(&_SafeSys.TransactOpts, _newPubkey)
}

// Deposit is a paid mutator transaction binding the contract method 0xd0e30db0.
//
// Solidity: function deposit() payable returns(bytes20)
func (_SafeSys *SafeSysTransactor) Deposit(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "deposit")
}

// Deposit is a paid mutator transaction binding the contract method 0xd0e30db0.
//
// Solidity: function deposit() payable returns(bytes20)
func (_SafeSys *SafeSysSession) Deposit() (*types.Transaction, error) {
	return _SafeSys.Contract.Deposit(&_SafeSys.TransactOpts)
}

// Deposit is a paid mutator transaction binding the contract method 0xd0e30db0.
//
// Solidity: function deposit() payable returns(bytes20)
func (_SafeSys *SafeSysTransactorSession) Deposit() (*types.Transaction, error) {
	return _SafeSys.Contract.Deposit(&_SafeSys.TransactOpts)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_SafeSys *SafeSysTransactor) Initialize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "initialize")
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_SafeSys *SafeSysSession) Initialize() (*types.Transaction, error) {
	return _SafeSys.Contract.Initialize(&_SafeSys.TransactOpts)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_SafeSys *SafeSysTransactorSession) Initialize() (*types.Transaction, error) {
	return _SafeSys.Contract.Initialize(&_SafeSys.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xdd467064.
//
// Solidity: function lock(uint256 _lockDay) payable returns(bytes20)
func (_SafeSys *SafeSysTransactor) Lock(opts *bind.TransactOpts, _lockDay *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "lock", _lockDay)
}

// Lock is a paid mutator transaction binding the contract method 0xdd467064.
//
// Solidity: function lock(uint256 _lockDay) payable returns(bytes20)
func (_SafeSys *SafeSysSession) Lock(_lockDay *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Lock(&_SafeSys.TransactOpts, _lockDay)
}

// Lock is a paid mutator transaction binding the contract method 0xdd467064.
//
// Solidity: function lock(uint256 _lockDay) payable returns(bytes20)
func (_SafeSys *SafeSysTransactorSession) Lock(_lockDay *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Lock(&_SafeSys.TransactOpts, _lockDay)
}

// RegisteMN is a paid mutator transaction binding the contract method 0x011e7290.
//
// Solidity: function registeMN(uint256 _lockDay, address _mnAddr, string _ip, string _pubkey, string _description) payable returns()
func (_SafeSys *SafeSysTransactor) RegisteMN(opts *bind.TransactOpts, _lockDay *big.Int, _mnAddr common.Address, _ip string, _pubkey string, _description string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "registeMN", _lockDay, _mnAddr, _ip, _pubkey, _description)
}

// RegisteMN is a paid mutator transaction binding the contract method 0x011e7290.
//
// Solidity: function registeMN(uint256 _lockDay, address _mnAddr, string _ip, string _pubkey, string _description) payable returns()
func (_SafeSys *SafeSysSession) RegisteMN(_lockDay *big.Int, _mnAddr common.Address, _ip string, _pubkey string, _description string) (*types.Transaction, error) {
	return _SafeSys.Contract.RegisteMN(&_SafeSys.TransactOpts, _lockDay, _mnAddr, _ip, _pubkey, _description)
}

// RegisteMN is a paid mutator transaction binding the contract method 0x011e7290.
//
// Solidity: function registeMN(uint256 _lockDay, address _mnAddr, string _ip, string _pubkey, string _description) payable returns()
func (_SafeSys *SafeSysTransactorSession) RegisteMN(_lockDay *big.Int, _mnAddr common.Address, _ip string, _pubkey string, _description string) (*types.Transaction, error) {
	return _SafeSys.Contract.RegisteMN(&_SafeSys.TransactOpts, _lockDay, _mnAddr, _ip, _pubkey, _description)
}

// RegisteSMN is a paid mutator transaction binding the contract method 0x7c0d4474.
//
// Solidity: function registeSMN(uint256 _lockDay, address _smnAddr, string _ip, string _pubkey, string _description, uint256 _creatorIncentive, uint256 _partnerIncentive, uint256 _voterIncentive) payable returns()
func (_SafeSys *SafeSysTransactor) RegisteSMN(opts *bind.TransactOpts, _lockDay *big.Int, _smnAddr common.Address, _ip string, _pubkey string, _description string, _creatorIncentive *big.Int, _partnerIncentive *big.Int, _voterIncentive *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "registeSMN", _lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive)
}

// RegisteSMN is a paid mutator transaction binding the contract method 0x7c0d4474.
//
// Solidity: function registeSMN(uint256 _lockDay, address _smnAddr, string _ip, string _pubkey, string _description, uint256 _creatorIncentive, uint256 _partnerIncentive, uint256 _voterIncentive) payable returns()
func (_SafeSys *SafeSysSession) RegisteSMN(_lockDay *big.Int, _smnAddr common.Address, _ip string, _pubkey string, _description string, _creatorIncentive *big.Int, _partnerIncentive *big.Int, _voterIncentive *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.RegisteSMN(&_SafeSys.TransactOpts, _lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive)
}

// RegisteSMN is a paid mutator transaction binding the contract method 0x7c0d4474.
//
// Solidity: function registeSMN(uint256 _lockDay, address _smnAddr, string _ip, string _pubkey, string _description, uint256 _creatorIncentive, uint256 _partnerIncentive, uint256 _voterIncentive) payable returns()
func (_SafeSys *SafeSysTransactorSession) RegisteSMN(_lockDay *big.Int, _smnAddr common.Address, _ip string, _pubkey string, _description string, _creatorIncentive *big.Int, _partnerIncentive *big.Int, _voterIncentive *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.RegisteSMN(&_SafeSys.TransactOpts, _lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive)
}

// RemoveAllApprovalVote4SMN is a paid mutator transaction binding the contract method 0x7ea58f87.
//
// Solidity: function removeAllApprovalVote4SMN() returns()
func (_SafeSys *SafeSysTransactor) RemoveAllApprovalVote4SMN(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "removeAllApprovalVote4SMN")
}

// RemoveAllApprovalVote4SMN is a paid mutator transaction binding the contract method 0x7ea58f87.
//
// Solidity: function removeAllApprovalVote4SMN() returns()
func (_SafeSys *SafeSysSession) RemoveAllApprovalVote4SMN() (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveAllApprovalVote4SMN(&_SafeSys.TransactOpts)
}

// RemoveAllApprovalVote4SMN is a paid mutator transaction binding the contract method 0x7ea58f87.
//
// Solidity: function removeAllApprovalVote4SMN() returns()
func (_SafeSys *SafeSysTransactorSession) RemoveAllApprovalVote4SMN() (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveAllApprovalVote4SMN(&_SafeSys.TransactOpts)
}

// RemoveApprovalVote4SMN is a paid mutator transaction binding the contract method 0xf5348ac2.
//
// Solidity: function removeApprovalVote4SMN(bytes20[] _recordIDs) returns()
func (_SafeSys *SafeSysTransactor) RemoveApprovalVote4SMN(opts *bind.TransactOpts, _recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "removeApprovalVote4SMN", _recordIDs)
}

// RemoveApprovalVote4SMN is a paid mutator transaction binding the contract method 0xf5348ac2.
//
// Solidity: function removeApprovalVote4SMN(bytes20[] _recordIDs) returns()
func (_SafeSys *SafeSysSession) RemoveApprovalVote4SMN(_recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveApprovalVote4SMN(&_SafeSys.TransactOpts, _recordIDs)
}

// RemoveApprovalVote4SMN is a paid mutator transaction binding the contract method 0xf5348ac2.
//
// Solidity: function removeApprovalVote4SMN(bytes20[] _recordIDs) returns()
func (_SafeSys *SafeSysTransactorSession) RemoveApprovalVote4SMN(_recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveApprovalVote4SMN(&_SafeSys.TransactOpts, _recordIDs)
}

// RemoveVote4SMN is a paid mutator transaction binding the contract method 0x185340ad.
//
// Solidity: function removeVote4SMN(bytes20[] _recordIDs) returns()
func (_SafeSys *SafeSysTransactor) RemoveVote4SMN(opts *bind.TransactOpts, _recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "removeVote4SMN", _recordIDs)
}

// RemoveVote4SMN is a paid mutator transaction binding the contract method 0x185340ad.
//
// Solidity: function removeVote4SMN(bytes20[] _recordIDs) returns()
func (_SafeSys *SafeSysSession) RemoveVote4SMN(_recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveVote4SMN(&_SafeSys.TransactOpts, _recordIDs)
}

// RemoveVote4SMN is a paid mutator transaction binding the contract method 0x185340ad.
//
// Solidity: function removeVote4SMN(bytes20[] _recordIDs) returns()
func (_SafeSys *SafeSysTransactorSession) RemoveVote4SMN(_recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveVote4SMN(&_SafeSys.TransactOpts, _recordIDs)
}

// RemoveVote4SMN0 is a paid mutator transaction binding the contract method 0xe914c77a.
//
// Solidity: function removeVote4SMN() returns()
func (_SafeSys *SafeSysTransactor) RemoveVote4SMN0(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "removeVote4SMN0")
}

// RemoveVote4SMN0 is a paid mutator transaction binding the contract method 0xe914c77a.
//
// Solidity: function removeVote4SMN() returns()
func (_SafeSys *SafeSysSession) RemoveVote4SMN0() (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveVote4SMN0(&_SafeSys.TransactOpts)
}

// RemoveVote4SMN0 is a paid mutator transaction binding the contract method 0xe914c77a.
//
// Solidity: function removeVote4SMN() returns()
func (_SafeSys *SafeSysTransactorSession) RemoveVote4SMN0() (*types.Transaction, error) {
	return _SafeSys.Contract.RemoveVote4SMN0(&_SafeSys.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_SafeSys *SafeSysTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_SafeSys *SafeSysSession) RenounceOwnership() (*types.Transaction, error) {
	return _SafeSys.Contract.RenounceOwnership(&_SafeSys.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_SafeSys *SafeSysTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _SafeSys.Contract.RenounceOwnership(&_SafeSys.TransactOpts)
}

// Reward is a paid mutator transaction binding the contract method 0x26240f10.
//
// Solidity: function reward(address _smnAddr, uint256 _smnAmount, address _mnAddr, uint256 _mnAmount) returns()
func (_SafeSys *SafeSysTransactor) Reward(opts *bind.TransactOpts, _smnAddr common.Address, _smnAmount *big.Int, _mnAddr common.Address, _mnAmount *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "reward", _smnAddr, _smnAmount, _mnAddr, _mnAmount)
}

// Reward is a paid mutator transaction binding the contract method 0x26240f10.
//
// Solidity: function reward(address _smnAddr, uint256 _smnAmount, address _mnAddr, uint256 _mnAmount) returns()
func (_SafeSys *SafeSysSession) Reward(_smnAddr common.Address, _smnAmount *big.Int, _mnAddr common.Address, _mnAmount *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Reward(&_SafeSys.TransactOpts, _smnAddr, _smnAmount, _mnAddr, _mnAmount)
}

// Reward is a paid mutator transaction binding the contract method 0x26240f10.
//
// Solidity: function reward(address _smnAddr, uint256 _smnAmount, address _mnAddr, uint256 _mnAmount) returns()
func (_SafeSys *SafeSysTransactorSession) Reward(_smnAddr common.Address, _smnAmount *big.Int, _mnAddr common.Address, _mnAmount *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Reward(&_SafeSys.TransactOpts, _smnAddr, _smnAmount, _mnAddr, _mnAmount)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address _to, uint256 _amount) returns(bytes20)
func (_SafeSys *SafeSysTransactor) Transfer(opts *bind.TransactOpts, _to common.Address, _amount *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "transfer", _to, _amount)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address _to, uint256 _amount) returns(bytes20)
func (_SafeSys *SafeSysSession) Transfer(_to common.Address, _amount *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Transfer(&_SafeSys.TransactOpts, _to, _amount)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address _to, uint256 _amount) returns(bytes20)
func (_SafeSys *SafeSysTransactorSession) Transfer(_to common.Address, _amount *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Transfer(&_SafeSys.TransactOpts, _to, _amount)
}

// TransferLock is a paid mutator transaction binding the contract method 0xd72896db.
//
// Solidity: function transferLock(address _to, uint256 _amount, uint256 _lockDay) returns(bytes20)
func (_SafeSys *SafeSysTransactor) TransferLock(opts *bind.TransactOpts, _to common.Address, _amount *big.Int, _lockDay *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "transferLock", _to, _amount, _lockDay)
}

// TransferLock is a paid mutator transaction binding the contract method 0xd72896db.
//
// Solidity: function transferLock(address _to, uint256 _amount, uint256 _lockDay) returns(bytes20)
func (_SafeSys *SafeSysSession) TransferLock(_to common.Address, _amount *big.Int, _lockDay *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.TransferLock(&_SafeSys.TransactOpts, _to, _amount, _lockDay)
}

// TransferLock is a paid mutator transaction binding the contract method 0xd72896db.
//
// Solidity: function transferLock(address _to, uint256 _amount, uint256 _lockDay) returns(bytes20)
func (_SafeSys *SafeSysTransactorSession) TransferLock(_to common.Address, _amount *big.Int, _lockDay *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.TransferLock(&_SafeSys.TransactOpts, _to, _amount, _lockDay)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_SafeSys *SafeSysTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_SafeSys *SafeSysSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.TransferOwnership(&_SafeSys.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_SafeSys *SafeSysTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.TransferOwnership(&_SafeSys.TransactOpts, newOwner)
}

// UnionRegisteMN is a paid mutator transaction binding the contract method 0xdd455407.
//
// Solidity: function unionRegisteMN(uint256 _lockDay, address _mnAddr, string _ip, string _pubkey, string _description) payable returns()
func (_SafeSys *SafeSysTransactor) UnionRegisteMN(opts *bind.TransactOpts, _lockDay *big.Int, _mnAddr common.Address, _ip string, _pubkey string, _description string) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "unionRegisteMN", _lockDay, _mnAddr, _ip, _pubkey, _description)
}

// UnionRegisteMN is a paid mutator transaction binding the contract method 0xdd455407.
//
// Solidity: function unionRegisteMN(uint256 _lockDay, address _mnAddr, string _ip, string _pubkey, string _description) payable returns()
func (_SafeSys *SafeSysSession) UnionRegisteMN(_lockDay *big.Int, _mnAddr common.Address, _ip string, _pubkey string, _description string) (*types.Transaction, error) {
	return _SafeSys.Contract.UnionRegisteMN(&_SafeSys.TransactOpts, _lockDay, _mnAddr, _ip, _pubkey, _description)
}

// UnionRegisteMN is a paid mutator transaction binding the contract method 0xdd455407.
//
// Solidity: function unionRegisteMN(uint256 _lockDay, address _mnAddr, string _ip, string _pubkey, string _description) payable returns()
func (_SafeSys *SafeSysTransactorSession) UnionRegisteMN(_lockDay *big.Int, _mnAddr common.Address, _ip string, _pubkey string, _description string) (*types.Transaction, error) {
	return _SafeSys.Contract.UnionRegisteMN(&_SafeSys.TransactOpts, _lockDay, _mnAddr, _ip, _pubkey, _description)
}

// UnionRegisteSMN is a paid mutator transaction binding the contract method 0x7877371c.
//
// Solidity: function unionRegisteSMN(uint256 _lockDay, address _smnAddr, string _ip, string _pubkey, string _description, uint256 _creatorIncentive, uint256 _partnerIncentive, uint256 _voterIncentive) payable returns()
func (_SafeSys *SafeSysTransactor) UnionRegisteSMN(opts *bind.TransactOpts, _lockDay *big.Int, _smnAddr common.Address, _ip string, _pubkey string, _description string, _creatorIncentive *big.Int, _partnerIncentive *big.Int, _voterIncentive *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "unionRegisteSMN", _lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive)
}

// UnionRegisteSMN is a paid mutator transaction binding the contract method 0x7877371c.
//
// Solidity: function unionRegisteSMN(uint256 _lockDay, address _smnAddr, string _ip, string _pubkey, string _description, uint256 _creatorIncentive, uint256 _partnerIncentive, uint256 _voterIncentive) payable returns()
func (_SafeSys *SafeSysSession) UnionRegisteSMN(_lockDay *big.Int, _smnAddr common.Address, _ip string, _pubkey string, _description string, _creatorIncentive *big.Int, _partnerIncentive *big.Int, _voterIncentive *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.UnionRegisteSMN(&_SafeSys.TransactOpts, _lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive)
}

// UnionRegisteSMN is a paid mutator transaction binding the contract method 0x7877371c.
//
// Solidity: function unionRegisteSMN(uint256 _lockDay, address _smnAddr, string _ip, string _pubkey, string _description, uint256 _creatorIncentive, uint256 _partnerIncentive, uint256 _voterIncentive) payable returns()
func (_SafeSys *SafeSysTransactorSession) UnionRegisteSMN(_lockDay *big.Int, _smnAddr common.Address, _ip string, _pubkey string, _description string, _creatorIncentive *big.Int, _partnerIncentive *big.Int, _voterIncentive *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.UnionRegisteSMN(&_SafeSys.TransactOpts, _lockDay, _smnAddr, _ip, _pubkey, _description, _creatorIncentive, _partnerIncentive, _voterIncentive)
}

// UploadMasterNodeState is a paid mutator transaction binding the contract method 0x224e2816.
//
// Solidity: function uploadMasterNodeState(uint256[] _ids, uint8[] _states) returns()
func (_SafeSys *SafeSysTransactor) UploadMasterNodeState(opts *bind.TransactOpts, _ids []*big.Int, _states []uint8) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "uploadMasterNodeState", _ids, _states)
}

// UploadMasterNodeState is a paid mutator transaction binding the contract method 0x224e2816.
//
// Solidity: function uploadMasterNodeState(uint256[] _ids, uint8[] _states) returns()
func (_SafeSys *SafeSysSession) UploadMasterNodeState(_ids []*big.Int, _states []uint8) (*types.Transaction, error) {
	return _SafeSys.Contract.UploadMasterNodeState(&_SafeSys.TransactOpts, _ids, _states)
}

// UploadMasterNodeState is a paid mutator transaction binding the contract method 0x224e2816.
//
// Solidity: function uploadMasterNodeState(uint256[] _ids, uint8[] _states) returns()
func (_SafeSys *SafeSysTransactorSession) UploadMasterNodeState(_ids []*big.Int, _states []uint8) (*types.Transaction, error) {
	return _SafeSys.Contract.UploadMasterNodeState(&_SafeSys.TransactOpts, _ids, _states)
}

// UploadSuperMasterNodeState is a paid mutator transaction binding the contract method 0xd62809f5.
//
// Solidity: function uploadSuperMasterNodeState(bytes20[] _ids, uint8[] _states) returns()
func (_SafeSys *SafeSysTransactor) UploadSuperMasterNodeState(opts *bind.TransactOpts, _ids [][20]byte, _states []uint8) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "uploadSuperMasterNodeState", _ids, _states)
}

// UploadSuperMasterNodeState is a paid mutator transaction binding the contract method 0xd62809f5.
//
// Solidity: function uploadSuperMasterNodeState(bytes20[] _ids, uint8[] _states) returns()
func (_SafeSys *SafeSysSession) UploadSuperMasterNodeState(_ids [][20]byte, _states []uint8) (*types.Transaction, error) {
	return _SafeSys.Contract.UploadSuperMasterNodeState(&_SafeSys.TransactOpts, _ids, _states)
}

// UploadSuperMasterNodeState is a paid mutator transaction binding the contract method 0xd62809f5.
//
// Solidity: function uploadSuperMasterNodeState(bytes20[] _ids, uint8[] _states) returns()
func (_SafeSys *SafeSysTransactorSession) UploadSuperMasterNodeState(_ids [][20]byte, _states []uint8) (*types.Transaction, error) {
	return _SafeSys.Contract.UploadSuperMasterNodeState(&_SafeSys.TransactOpts, _ids, _states)
}

// VerifySMN is a paid mutator transaction binding the contract method 0x9ef66778.
//
// Solidity: function verifySMN(address _smnAddr) returns()
func (_SafeSys *SafeSysTransactor) VerifySMN(opts *bind.TransactOpts, _smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "verifySMN", _smnAddr)
}

// VerifySMN is a paid mutator transaction binding the contract method 0x9ef66778.
//
// Solidity: function verifySMN(address _smnAddr) returns()
func (_SafeSys *SafeSysSession) VerifySMN(_smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.VerifySMN(&_SafeSys.TransactOpts, _smnAddr)
}

// VerifySMN is a paid mutator transaction binding the contract method 0x9ef66778.
//
// Solidity: function verifySMN(address _smnAddr) returns()
func (_SafeSys *SafeSysTransactorSession) VerifySMN(_smnAddr common.Address) (*types.Transaction, error) {
	return _SafeSys.Contract.VerifySMN(&_SafeSys.TransactOpts, _smnAddr)
}

// Vote4SMN is a paid mutator transaction binding the contract method 0x5cb58252.
//
// Solidity: function vote4SMN(address _smnAddr, bytes20 _recordID) returns()
func (_SafeSys *SafeSysTransactor) Vote4SMN(opts *bind.TransactOpts, _smnAddr common.Address, _recordID [20]byte) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "vote4SMN", _smnAddr, _recordID)
}

// Vote4SMN is a paid mutator transaction binding the contract method 0x5cb58252.
//
// Solidity: function vote4SMN(address _smnAddr, bytes20 _recordID) returns()
func (_SafeSys *SafeSysSession) Vote4SMN(_smnAddr common.Address, _recordID [20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.Vote4SMN(&_SafeSys.TransactOpts, _smnAddr, _recordID)
}

// Vote4SMN is a paid mutator transaction binding the contract method 0x5cb58252.
//
// Solidity: function vote4SMN(address _smnAddr, bytes20 _recordID) returns()
func (_SafeSys *SafeSysTransactorSession) Vote4SMN(_smnAddr common.Address, _recordID [20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.Vote4SMN(&_SafeSys.TransactOpts, _smnAddr, _recordID)
}

// Vote4proposal is a paid mutator transaction binding the contract method 0xb4cf5f1f.
//
// Solidity: function vote4proposal(bytes20 _proposalID, uint256 _result) returns()
func (_SafeSys *SafeSysTransactor) Vote4proposal(opts *bind.TransactOpts, _proposalID [20]byte, _result *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "vote4proposal", _proposalID, _result)
}

// Vote4proposal is a paid mutator transaction binding the contract method 0xb4cf5f1f.
//
// Solidity: function vote4proposal(bytes20 _proposalID, uint256 _result) returns()
func (_SafeSys *SafeSysSession) Vote4proposal(_proposalID [20]byte, _result *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Vote4proposal(&_SafeSys.TransactOpts, _proposalID, _result)
}

// Vote4proposal is a paid mutator transaction binding the contract method 0xb4cf5f1f.
//
// Solidity: function vote4proposal(bytes20 _proposalID, uint256 _result) returns()
func (_SafeSys *SafeSysTransactorSession) Vote4proposal(_proposalID [20]byte, _result *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Vote4proposal(&_SafeSys.TransactOpts, _proposalID, _result)
}

// Vote4updateProperty is a paid mutator transaction binding the contract method 0xe572d626.
//
// Solidity: function vote4updateProperty(string _name, uint256 _result) returns()
func (_SafeSys *SafeSysTransactor) Vote4updateProperty(opts *bind.TransactOpts, _name string, _result *big.Int) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "vote4updateProperty", _name, _result)
}

// Vote4updateProperty is a paid mutator transaction binding the contract method 0xe572d626.
//
// Solidity: function vote4updateProperty(string _name, uint256 _result) returns()
func (_SafeSys *SafeSysSession) Vote4updateProperty(_name string, _result *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Vote4updateProperty(&_SafeSys.TransactOpts, _name, _result)
}

// Vote4updateProperty is a paid mutator transaction binding the contract method 0xe572d626.
//
// Solidity: function vote4updateProperty(string _name, uint256 _result) returns()
func (_SafeSys *SafeSysTransactorSession) Vote4updateProperty(_name string, _result *big.Int) (*types.Transaction, error) {
	return _SafeSys.Contract.Vote4updateProperty(&_SafeSys.TransactOpts, _name, _result)
}

// Withdraw is a paid mutator transaction binding the contract method 0x3ccfd60b.
//
// Solidity: function withdraw() returns()
func (_SafeSys *SafeSysTransactor) Withdraw(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "withdraw")
}

// Withdraw is a paid mutator transaction binding the contract method 0x3ccfd60b.
//
// Solidity: function withdraw() returns()
func (_SafeSys *SafeSysSession) Withdraw() (*types.Transaction, error) {
	return _SafeSys.Contract.Withdraw(&_SafeSys.TransactOpts)
}

// Withdraw is a paid mutator transaction binding the contract method 0x3ccfd60b.
//
// Solidity: function withdraw() returns()
func (_SafeSys *SafeSysTransactorSession) Withdraw() (*types.Transaction, error) {
	return _SafeSys.Contract.Withdraw(&_SafeSys.TransactOpts)
}

// Withdraw0 is a paid mutator transaction binding the contract method 0x60a2b8f1.
//
// Solidity: function withdraw(bytes20[] recordIDs) returns()
func (_SafeSys *SafeSysTransactor) Withdraw0(opts *bind.TransactOpts, recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.contract.Transact(opts, "withdraw0", recordIDs)
}

// Withdraw0 is a paid mutator transaction binding the contract method 0x60a2b8f1.
//
// Solidity: function withdraw(bytes20[] recordIDs) returns()
func (_SafeSys *SafeSysSession) Withdraw0(recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.Withdraw0(&_SafeSys.TransactOpts, recordIDs)
}

// Withdraw0 is a paid mutator transaction binding the contract method 0x60a2b8f1.
//
// Solidity: function withdraw(bytes20[] recordIDs) returns()
func (_SafeSys *SafeSysTransactorSession) Withdraw0(recordIDs [][20]byte) (*types.Transaction, error) {
	return _SafeSys.Contract.Withdraw0(&_SafeSys.TransactOpts, recordIDs)
}

// SafeSysInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the SafeSys contract.
type SafeSysInitializedIterator struct {
	Event *SafeSysInitialized // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SafeSysInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SafeSysInitialized)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SafeSysInitialized)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SafeSysInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SafeSysInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SafeSysInitialized represents a Initialized event raised by the SafeSys contract.
type SafeSysInitialized struct {
	Version uint8
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498.
//
// Solidity: event Initialized(uint8 version)
func (_SafeSys *SafeSysFilterer) FilterInitialized(opts *bind.FilterOpts) (*SafeSysInitializedIterator, error) {

	logs, sub, err := _SafeSys.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &SafeSysInitializedIterator{contract: _SafeSys.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498.
//
// Solidity: event Initialized(uint8 version)
func (_SafeSys *SafeSysFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *SafeSysInitialized) (event.Subscription, error) {

	logs, sub, err := _SafeSys.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SafeSysInitialized)
				if err := _SafeSys.contract.UnpackLog(event, "Initialized", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseInitialized is a log parse operation binding the contract event 0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498.
//
// Solidity: event Initialized(uint8 version)
func (_SafeSys *SafeSysFilterer) ParseInitialized(log types.Log) (*SafeSysInitialized, error) {
	event := new(SafeSysInitialized)
	if err := _SafeSys.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SafeSysOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the SafeSys contract.
type SafeSysOwnershipTransferredIterator struct {
	Event *SafeSysOwnershipTransferred // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SafeSysOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SafeSysOwnershipTransferred)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SafeSysOwnershipTransferred)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SafeSysOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SafeSysOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SafeSysOwnershipTransferred represents a OwnershipTransferred event raised by the SafeSys contract.
type SafeSysOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_SafeSys *SafeSysFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*SafeSysOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _SafeSys.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &SafeSysOwnershipTransferredIterator{contract: _SafeSys.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_SafeSys *SafeSysFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *SafeSysOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _SafeSys.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SafeSysOwnershipTransferred)
				if err := _SafeSys.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseOwnershipTransferred is a log parse operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_SafeSys *SafeSysFilterer) ParseOwnershipTransferred(log types.Log) (*SafeSysOwnershipTransferred, error) {
	event := new(SafeSysOwnershipTransferred)
	if err := _SafeSys.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
