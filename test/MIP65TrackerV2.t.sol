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
        catch Error(string memory _err) { 
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

        (int qty, int nav, int yield, int duration, int maturity) = tracker.details("ASSET_A");
        assertEq(qty, 0, "Qty of Asset A is wrong");
        assertEq(nav, 1 ether, "NAV of Asset A is wrong");
        assertEq(yield, 0.04 ether, "Yield of Asset A is wrong");
        assertEq(duration, 1.9 ether, "Duration of Asset A is wrong");
        assertEq(maturity, 2.1 ether, "Maturity of Asset A is wrong");

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
        assertEq(tracker.value(), 1_000 ether, "add capital isn't working");
        assertEq(tracker.cash(), 1_000 ether, "add capital isn't working");

        // Sending capital in
        tracker.removeCapital(TODAY - 50 days, 50 ether);
        assertEq(tracker.value(), 950 ether, "add capital isn't working");
        assertEq(tracker.cash(), 950 ether, "add capital isn't working");



    }

}
