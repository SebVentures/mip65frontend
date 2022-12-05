// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract MIP65Tracker is AccessControl {
    event AssetInit(string asset, uint price);
    event AssetBuy(string asset, uint ts, uint qty, uint price);
    event AssetSell(string asset, uint ts, uint qty, uint price);
    event AssetUpdate(string asset, uint ts, uint price);

    // Tracking for an asset
    struct Asset {
        string name;
        uint qty;
        uint price;
    }

    bytes32 public constant PRICE_ROLE = keccak256(abi.encode("mip65.price.role"));
    bytes32 public constant OPS_ROLE = keccak256(abi.encode("mip65.ops.role"));

    mapping (string => Asset) private _assets;
    string[] private _assetsIds;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(PRICE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(OPS_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function init(string calldata asset, uint price) onlyRole(OPS_ROLE) external {
        _assets[asset] = Asset(asset, 0, price);
        _assetsIds.push(asset);
        emit AssetInit(asset, price);
    }

    function buy(string calldata asset, uint ts, uint qty, uint price) onlyRole(OPS_ROLE) external {
        Asset storage item = _assets[asset];
        item.qty += qty;
        emit AssetBuy(asset, ts, qty, price);
    }
    
    function sell(string calldata asset, uint ts, uint qty, uint price) onlyRole(OPS_ROLE) external {
        Asset storage item = _assets[asset];
        item.qty -= qty;
        emit AssetSell(asset, ts, qty, price);
    }

    function update(string calldata asset, uint ts, uint price) onlyRole(PRICE_ROLE) external {
        Asset storage item = _assets[asset];
        item.price = price;
        emit AssetUpdate(asset, ts, price);
    }

    function value() view external returns (uint) {
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