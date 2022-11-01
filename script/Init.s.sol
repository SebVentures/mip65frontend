// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/MIP65Tracker.sol";

import "forge-std/Script.sol";

contract InitScript is Script {


    function run() public {
        vm.startBroadcast(tx.origin);

        MIP65Tracker tracker = new MIP65Tracker();

        console.log("MIP65Tracker deployed address");
        console.log(address(tracker));

        tracker.grantRole(tracker.OPS_ROLE(), tx.origin);
        tracker.grantRole(tracker.PRICE_ROLE(), tx.origin);

        tracker.init("IB01", 10229*10**16);

        tracker.buy("IB01", block.timestamp, 901*10**18, 10232*10**16);

        tracker.buy("IB01", block.timestamp, 75*10**18, 10232*10**16);

        tracker.update("IB01", block.timestamp, 10230*10**16);

        console.log(tracker.value()/10**18);


        tracker.update("IB01", block.timestamp, 10228*10**16);
        console.log(tracker.value()/10**18);

        tracker.assets();

        vm.stopBroadcast();
    }
}
