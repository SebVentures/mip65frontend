// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 * @notice all timestamp are date, i.e.  UTC midnight, this allow to more easily correct wrong data
 * @notice most operations use int for quantities/amounts so you can correct a mistake by submitting -value.
 */
contract MIP65TrackerV2 is AccessControl {
    event AssetInit(string asset);
    event AssetBuy(string asset, uint date, int qty, int price);
    event AssetSell(string asset, uint date, int qty, int price);
    event AssetUpdate(string asset, uint date, int nav, int yield, int duration, int maturity);

    // When a draw on the vault
    event CapitalIn(uint date, int amount);
    // When sending to the vaul or the RWAJar
    event CapitalOut(uint date, int amount);

    // Any kind of expense, amount could be negative
    event Expense(uint date, int amount, string reason);
    event Income(uint date, int amount, string reason);

    // Tracking for an asset
    struct Asset {
        string name;
        // updated with buy/sell operations
        int qty;
        // updated with update operaion
        uint date;
        int nav;
        int yield;
        int duration;
        int maturity;
    }

    // Light admin able to manage DATA and OPS roles.
    bytes32 public constant GUARDIAN_ROLE = keccak256(abi.encode("mip65.guardian.role"));
    // Able to update asset data (nav, yield, duration)
    bytes32 public constant DATA_ROLE = keccak256(abi.encode("mip65.data.role"));
    // Able to execute transactions (buy/se/capital in/capital out/expense/income)
    bytes32 public constant OPS_ROLE = keccak256(abi.encode("mip65.ops.role"));

    mapping (string => Asset) private _assets;
    string[] private _assetsIds;
    int private _cash;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(GUARDIAN_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(GUARDIAN_ROLE, _msgSender());
        _setRoleAdmin(DATA_ROLE, GUARDIAN_ROLE);
        _setRoleAdmin(OPS_ROLE, GUARDIAN_ROLE);
        _cash = 0;
    }

    function _checkDate(uint date) internal view {
        require(date != 0, "The timestamp can't be 0");
        require(date % 24*3600 == 0, "The date should be at UTC midnight");
        require(date < block.timestamp, "The date should not be in the future");
    }

    function init(string calldata asset) onlyRole(GUARDIAN_ROLE) external {
        _assets[asset] = Asset(asset, 0, 0, 0, 0, 0, 0);
        _assetsIds.push(asset);
        emit AssetInit(asset);
    }

    function buy(string calldata asset, uint date, int qty, int price) onlyRole(OPS_ROLE) external {
        _checkDate(date);
        Asset storage item = _assets[asset];
        item.qty += qty;
        _cash -= qty * price;
        emit AssetBuy(asset, date, qty, price);
    }
    
    function sell(string calldata asset, uint date, int qty, int price) onlyRole(OPS_ROLE) external {
        _checkDate(date);
        Asset storage item = _assets[asset];
        item.qty -= qty;
        _cash += qty * price;
        emit AssetSell(asset, date, qty, price);
    }

    function update(string calldata asset, uint date, int nav, int yield, int duration, int maturity) onlyRole(DATA_ROLE) external {
        _checkDate(date);
        Asset storage item = _assets[asset];
        item.nav = nav;
        item.yield = yield;
        item.duration = duration;
        item.maturity = maturity;
        emit AssetUpdate(asset, date, nav, yield, duration, maturity);
    }

    function addCapital(uint date, int amount) onlyRole(OPS_ROLE) external {
        _checkDate(date);
        _cash += amount;
        emit CapitalIn(date, amount);
    }

    function removeCapital(uint date, int amount) onlyRole(OPS_ROLE) external {
        _checkDate(date);
        _cash -= amount;
        emit CapitalOut(date, amount);
    }

    function expense(uint date, int amount, string memory reason) onlyRole(OPS_ROLE) external {
        _checkDate(date);
        _cash -= amount;
        emit Expense(date, amount, reason);
    }

    function income(uint date, int amount, string memory reason) onlyRole(OPS_ROLE) external {
        _checkDate(date);
        _cash += amount;
        emit Income(date, amount, reason);
    }

    function value() view external returns (int) {
        int val = 0;
        for(uint i = 0; i < _assetsIds.length; i++) {
            Asset memory item = _assets[_assetsIds[i]];
            val += (item.qty * item.nav) / 10**18;
        }
        return val + _cash;
    }

    function cash() view external returns (int) {
        return _cash;
    }

    function assets() view external returns (string[] memory) {
        return _assetsIds;
    }

    function details(string calldata asset) view external returns (int qty, int nav, int yield, int duration, int maturity) {
        Asset memory item = _assets[asset];
        return (item.qty, item.nav, item.yield, item.duration, item.maturity);
    }
}
