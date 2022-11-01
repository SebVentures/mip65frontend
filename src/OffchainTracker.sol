// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";


/// @notice Work in progrees
contract OffchainTracker is AccessControl {
    event InitItem(string item);
    event InitFeature(string item, string feature, int value);
    event Update(string item, string feature, uint date, int value);

    struct Item {
        mapping (string => int) featureValues;
        mapping (string => uint) featureDates; // Shouldn't be 0, which mean the feature wasn't set
        string[] features;
        bool exists;
    }
    bytes32 public constant OPS_ROLE = keccak256(abi.encode("offchain.ops.role"));
    bytes32 public constant ORACLE_ROLE = keccak256(abi.encode("offchain.oracle.role"));

    mapping (string => Item) private _items;
    string[] private _itemsNames;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(OPS_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function initItem(string calldata itemName) onlyRole(OPS_ROLE) external {
        _items[item] = Item([], [],[], true);
        _itemsNames.push(item);
        emit InitItem(item);
    }

    function initFeature(string calldata itemName, string calldata feature) onlyRole(OPS_ROLE) external {
        Item storage item =  _items[itemName];
        requiere(item.exists = )
        _itemsNames.push(itemName);
        emit InitItem(item);
    }

    function update(string calldata item, string calldata feature, uint date, int value) onlyRole(ORACLE_ROLE) external {
        require(date != 0, "The timestamp can't be 0");
        require(date % 24*3600 == 0, "The timestamp should be at UTC midnight");
        require(date < block.timestamp, "The timestamp should not be in the future");
        Item storage item = _items[item];
        require(date < block.timestamp, "The timestamp should not be in the future");
        item.features[feature] = value;
        item.dates[feature] = date;
        emit Update(item, feature, date, value);
    }

    function items() view external returns (uint) {
        uint val = 0;
        for(uint i = 0; i < _assetsIds.length; i++) {
            Asset memory item = _assets[_assetsIds[i]];
            val += (item.qty * item.price) / 10**18;
        }
        return val;
    }

    function assets() view external returns (string[] memory) {
        return _assetsIds;
    }

    function detail(string calldata asset) view external returns (uint qty, uint price) {
        Asset memory item = _assets[asset];
        return (item.qty, item.price);
    }
}
