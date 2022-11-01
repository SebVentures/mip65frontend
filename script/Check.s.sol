// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/MIP65Tracker.sol";

import "forge-std/Script.sol";

contract CheckScript is Script {
    address private eoa1;
    address private eoa2;
    address private eoa3;


    MIP65Tracker private tracker;

    function setUp() public {
    }

    function run() public {
        vm.startBroadcast(tx.origin);

        tracker = MIP65Tracker(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        
        console.log(tracker.value()/10**18);

        vm.stopBroadcast();
    }
}
