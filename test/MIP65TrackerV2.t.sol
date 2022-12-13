// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/MIP65TrackerV2.sol";

contract MIP65TrackerV2Test is Test {
    address private gov;
    address private guardian1;
    address private guardian2;
    address private ops1;
    address private ops2;
    address private data1;
    address private data2;

    MIP65TrackerV2 private tracker;

    uint256 constant TODAY = 1640995200; // 2022-01-01

    
    function setUp() public {
        gov = vm.addr(1);
        guardian1 = vm.addr(2);
        guardian2 = vm.addr(3);
        ops1 = vm.addr(4);
        ops2 = vm.addr(5);
        data1 = vm.addr(6);
        data2 = vm.addr(7);

        vm.warp(TODAY + 1 days);

        tracker = new MIP65TrackerV2();

        // Set gov as 
        tracker.grantRole(tracker.DEFAULT_ADMIN_ROLE(), gov);
        tracker.grantRole(tracker.GUARDIAN_ROLE(), gov);
        tracker.grantRole(tracker.GUARDIAN_ROLE(), guardian1);
        tracker.grantRole(tracker.OPS_ROLE(), ops1);
        tracker.grantRole(tracker.DATA_ROLE(), data1);

        // Remove deployer access
        tracker.renounceRole(tracker.GUARDIAN_ROLE(), address(this));
        tracker.renounceRole(tracker.DEFAULT_ADMIN_ROLE(), address(this));

    }

    function testAccess() public {
        // vm.expertRevert causing troubles
        try tracker.grantRole(tracker.GUARDIAN_ROLE(), guardian2) {
            assertTrue(false);
        }
        catch Error(string memory) { 
            assertTrue(true);
        }
    }

    function testData() public {
        // Setting up 2 assets
        vm.prank(gov);
        tracker.init("ASSET_A");
        vm.prank(gov);
        tracker.init("ASSET_B");

        vm.prank(data1);
        tracker.update("ASSET_A", TODAY, 1 ether, 0.04 ether, 1.9 ether, 2.1 ether);

        /* test that data are well set for ASSET_A */
        (int qty, int nav, int yield, int duration, int maturity) = tracker.details("ASSET_A");
        assertEq(qty, 0, "Qty of Asset A is wrong");
        assertEq(nav, 1 ether, "NAV of Asset A is wrong");
        assertEq(yield, 0.04 ether, "Yield of Asset A is wrong");
        assertEq(duration, 1.9 ether, "Duration of Asset A is wrong");
        assertEq(maturity, 2.1 ether, "Maturity of Asset A is wrong");


        vm.prank(data1);
        tracker.update("ASSET_B", TODAY, 2 ether, 0.05 ether, 0.5 ether, 0.6 ether);

        /* test that data are well set for ASSET_A */
        (qty, nav, yield, duration, maturity) = tracker.details("ASSET_B");
        assertEq(qty, 0, "Qty of Asset B is wrong");
        assertEq(nav, 2 ether, "NAV of Asset B is wrong");
        assertEq(yield, 0.05 ether, "Yield of Asset B is wrong");
        assertEq(duration, 0.5 ether, "Duration of Asset B is wrong");
        assertEq(maturity, 0.6 ether, "Maturity of Asset B is wrong");

        /* test that data haven't changed for ASSET_A */
        (qty, nav, yield, duration, maturity) = tracker.details("ASSET_A");
        assertEq(qty, 0, "Qty of Asset A was changed");
        assertEq(nav, 1 ether, "NAV of Asset A was changed");
        assertEq(yield, 0.04 ether, "Yield of Asset A was changed");
        assertEq(duration, 1.9 ether, "Duration of Asset A was changed");
        assertEq(maturity, 2.1 ether, "Maturity of Asset A was changed");

        // Even if we change in the past, data are changed for the details method
        vm.prank(data1);
        tracker.update("ASSET_A", TODAY - 50 days, 3 ether, 0.03 ether, 3.0 ether, 3.1 ether);

        /* test that data haven't changed for ASSET_A */
        (qty, nav, yield, duration, maturity) = tracker.details("ASSET_A");
        assertEq(qty, 0, "Qty of Asset A was not changed");
        assertEq(nav, 3 ether, "NAV of Asset A was not changed");
        assertEq(yield, 0.03 ether, "Yield of Asset A was not changed");
        assertEq(duration, 3.0 ether, "Duration of Asset A was not changed");
        assertEq(maturity, 3.1 ether, "Maturity of Asset A was not changed");
    }


    function testScenario() public {
        // Give control to this contract
        bytes32 guardianRole = tracker.GUARDIAN_ROLE();
        vm.prank(gov);
        tracker.grantRole(guardianRole, address(this));
        // Give right for OPS and DATA
        tracker.grantRole(tracker.OPS_ROLE(), address(this));
        tracker.grantRole(tracker.DATA_ROLE(), address(this));

        // Setting up 2 assets
        tracker.init("ASSET_A");
        tracker.init("ASSET_B");

        // Sending capital in
        tracker.addCapital(TODAY - 50 days, 1_000 ether);
        assertEq(tracker.value(), 1_000 ether, "add capital isn't working - value");
        assertEq(tracker.cash(), 1_000 ether, "add capital isn't working - cash");

        // Sending capital in
        tracker.removeCapital(TODAY - 50 days, 50 ether);
        assertEq(tracker.value(), 950 ether, "remove capital isn't working - value");
        assertEq(tracker.cash(), 950 ether, "remove capital isn't working - cash");

        // Buy order, 1 unit at $10
        tracker.buy("ASSET_A", TODAY - 50 days, 1 ether, 10 ether);
        // Value ASSET_A at $9
        tracker.update("ASSET_A", TODAY - 50 days, 9 ether, 0.09 ether, 9.0 ether, 9.1 ether);

        assertEq(tracker.value(), 949 ether, "Buy asset isn't working - value");
        assertEq(tracker.cash(), 940 ether, "Buy asset isn't working - cash");

        // Value ASSET_A at $10
        tracker.update("ASSET_A", TODAY - 50 days, 10 ether, 0.09 ether, 9.0 ether, 9.1 ether);
        
        assertEq(tracker.value(), 950 ether, "Buy asset isn't working - value");
        assertEq(tracker.cash(), 940 ether, "Buy asset isn't working - cash");


    }

}
