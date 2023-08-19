// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FungibleWithSanction.sol";

contract FungibleWithSanctionTest is Test {
    FungibleWithSanction public funWiSan;
    address immutable public admin = vm.addr(1);
    address immutable public sender1 = vm.addr(2);
    address immutable public senderBlacklisted = vm.addr(3);
    address immutable public receiver1 = vm.addr(4);
   

    event AddedToBlacklist(address indexed blacklistedAddress);
    event RemovedFromBlacklist(address indexed unBlacklistedAddress);
    
    function setUp() public {
        funWiSan =  new FungibleWithSanction(admin, "NoPowerToken", "NPT");
    }

    function testSetUp() public {
        assertEq(funWiSan.name(), "NoPowerToken");
        assertEq(funWiSan.symbol(), "NPT");
        assertEq(funWiSan.admin(), admin);
        assertEq(funWiSan.balanceOf(admin), 10_000_000);
        assertEq(funWiSan.totalSupply(), 10_000_000);
    }

    function testWithFuzzingAddToBlacklist(address blacklistedFuzz) public {
        //address should not be blacklisted
        assertFalse(funWiSan.isBlacklisted(blacklistedFuzz));

        //admin blacklists address
        vm.prank(admin);

        vm.expectEmit();
        // We emit the AddedToBlacklist event we expect to see.
        emit AddedToBlacklist(blacklistedFuzz);
        funWiSan.addToBlacklist(blacklistedFuzz);

        //address should be blacklisted
        assertTrue(funWiSan.isBlacklisted(blacklistedFuzz));
    }

    function testRevertWithFuzzingAddToBlacklistIfBlacklisted(address blacklistedFuzz) public {
        //admin blacklists address
        vm.startPrank(admin);
        funWiSan.addToBlacklist(blacklistedFuzz);

        //Should revert , user already blacklisted
        bytes4 selector = bytes4(keccak256("Blacklisted(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedFuzz ));
        funWiSan.addToBlacklist(blacklistedFuzz);
        vm.stopPrank();
    }

    function testRevertAddToBlacklistIfNotAdmin(address notAdminFuzz) public {
        vm.assume(notAdminFuzz != admin);

        //caller is not admin
        vm.startPrank(notAdminFuzz);
        bytes4 selector = bytes4(keccak256("NotAdmin()"));

        //should revert notAdmin()
        vm.expectRevert(selector);
        funWiSan.addToBlacklist(senderBlacklisted);
        vm.stopPrank();
    }

    function testWithFuzzingRemoveFromBlacklist(address blacklistedFuzz) public {
        //admin blacklists address
        vm.startPrank(admin);
        funWiSan.addToBlacklist(blacklistedFuzz);

        //address should be blacklisted
        assertTrue(funWiSan.isBlacklisted(blacklistedFuzz));

        vm.expectEmit();
        // We emit the RemoveFromBlacklist event we expect to see.
        emit RemovedFromBlacklist(blacklistedFuzz);

        //admin removes from blacklist
        funWiSan.removeFromBlacklist(blacklistedFuzz);

        vm.stopPrank();

        //address should not be blacklisted anymore
        assertFalse(funWiSan.isBlacklisted(blacklistedFuzz));
    }

    function testRevertRemoveFromBlacklistIfNotBlacklisted(address blacklistedFuzz) public {
        vm.startPrank(admin);

        //Should revert , user already blacklisted
        bytes4 selector = bytes4(keccak256("NotBlacklisted(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedFuzz ));
        funWiSan.removeFromBlacklist(blacklistedFuzz);
        vm.stopPrank();
    }

    function testWithFuzzingRevertRemoveFromBlacklistIfNotAdmin(address notAdminFuzz) public {
        //make sure fuzz doesn't use revert cases
        vm.assume(notAdminFuzz != admin);

        vm.prank(admin);
        //admin adds to blacklist
        funWiSan.addToBlacklist(senderBlacklisted);

        //caller is not admin
        vm.startPrank(notAdminFuzz);
        bytes4 selector = bytes4(keccak256("NotAdmin()"));

        //should revert notAdmin()
        vm.expectRevert(selector);
        funWiSan.removeFromBlacklist(senderBlacklisted);
        vm.stopPrank();
    }

    function testIsBlacklisted(address blacklisted) public {
        //address should not be blacklisted
        assertFalse(funWiSan.isBlacklisted(blacklisted));

        //admin blacklists address
        vm.prank(admin);
        funWiSan.addToBlacklist(blacklisted);

        //address should be blacklisted
        assertTrue(funWiSan.isBlacklisted(blacklisted));
    }

    function testWithFuzzingTransfer(address senderFuzz) public {
        //make sure fuzz doesn't use revert cases
        vm.assume(senderFuzz != address(0));
        vm.assume(senderFuzz != admin);

        uint balanceSFBefore = funWiSan.balanceOf(senderFuzz);
        uint balanceAdminBefore = funWiSan.balanceOf(admin);

        //admin transfer 1_000_000 to senderFuzz
        vm.prank(admin);
        bool transferExecuted = funWiSan.transfer(senderFuzz, 1_000_000);

        //assert transfer was successful
        assertTrue(transferExecuted);

        uint balanceSFAfter = funWiSan.balanceOf(senderFuzz);
        uint balanceAdminAfter = funWiSan.balanceOf(admin);
        //assert balances were updated
        assertEq(balanceSFAfter, balanceSFBefore + 1_000_000);
        assertEq(balanceAdminAfter, balanceAdminBefore - 1_000_000);
    }

    
    function testTransferFrom(address fromFuzz, address toFuzz) public {
        //make sure fuzz doesn't use revert cases
        vm.assume(fromFuzz != address(0));
        vm.assume(toFuzz != address(0));
        vm.assume(toFuzz != fromFuzz);
        deal(address(funWiSan), fromFuzz, 1_000_000);
        uint balanceSenderBefore = funWiSan.balanceOf(fromFuzz);
        uint balanceReceiverBefore = funWiSan.balanceOf(toFuzz);

        vm.prank(fromFuzz);
        funWiSan.approve(admin, 1_000_000);

        //admin transfer 1_000_000 to sender1
        vm.prank(admin);
        bool transferExecuted = funWiSan.transferFrom(fromFuzz, toFuzz, 1_000_000);

        //assert transfer was successful
        assertTrue(transferExecuted);

        uint balanceSenderAfter = funWiSan.balanceOf(fromFuzz);
        uint balanceReceiverAfter = funWiSan.balanceOf(toFuzz);

        //assert balances were updated
        assertEq(balanceSenderAfter, balanceSenderBefore - 1_000_000);
        assertEq(balanceReceiverAfter, balanceReceiverBefore + 1_000_000);
    }

    function testWithFuzzingRevertTransferIfSenderBlacklisted(address blacklistedSender) public {
        vm.assume(blacklistedSender != address(0));
        deal(address(funWiSan), blacklistedSender, 1_000_000);

        //admin adds address to blacklist
        vm.prank(admin);
        funWiSan.addToBlacklist((blacklistedSender));

        vm.prank(blacklistedSender);
        bytes4 selector = bytes4(keccak256("SendingFromBlacklisted(address)"));
        //transfer should revert, sender address is blacklisted
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedSender));
        funWiSan.transfer(receiver1, 1_000_000);
    }

    function testRevertTransferIfReceiverBlacklisted(address blacklistedReceiver) public {
        vm.assume(blacklistedReceiver != address(0));
        vm.assume(blacklistedReceiver != sender1);

        //deals token to address for transfer
        deal(address(funWiSan), sender1 , 1_000_000);

        //admin adds address to blacklist
        vm.prank(admin);
        funWiSan.addToBlacklist((blacklistedReceiver));

        vm.prank(sender1);
        bytes4 selector = bytes4(keccak256("SendingToBlacklisted(address)"));
        //transfer should revert, receiver address is blacklisted
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedReceiver));
        funWiSan.transfer(blacklistedReceiver, 1_000_000);
    }

    function testRevertTransferFromIfSenderBlacklisted(address blacklistedSender, address senderOnBehalf) public {
        vm.assume(blacklistedSender != address(0));
        vm.assume(senderOnBehalf != address(0));
        vm.assume(senderOnBehalf != blacklistedSender);
        deal(address(funWiSan), blacklistedSender, 1_000_000);

        //admin adds address to blacklist
        vm.prank(admin);
        funWiSan.addToBlacklist((blacklistedSender));

        //sender approves random address to transfer on behalf
        vm.prank(blacklistedSender);
        funWiSan.approve(senderOnBehalf, 1_000_000);

        //random address transfers from blacklisted sender, should revert
        vm.prank(senderOnBehalf);
        bytes4 selector = bytes4(keccak256("SendingFromBlacklisted(address)"));
        //transfer should revert, sender address is blacklisted
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedSender));
        funWiSan.transferFrom(blacklistedSender, receiver1, 1_000_000);
    }

    function testRevertTransferFromIfReceiverBlacklisted(address blacklistedReceiver, address senderOnBehalf) public {
        vm.assume(blacklistedReceiver != address(0));
        vm.assume(senderOnBehalf != address(0));
        vm.assume(senderOnBehalf != blacklistedReceiver);

        //deals token to address for transfer
        deal(address(funWiSan), sender1 , 1_000_000);

        //admin adds address to blacklist
        vm.prank(admin);
        funWiSan.addToBlacklist((blacklistedReceiver));

        //sender approves random address to transfer on behalf
        vm.prank(sender1);
        funWiSan.approve(senderOnBehalf, 1_000_000);

        //random allowed address transfers to blacklisted, should revert
        vm.prank(senderOnBehalf);
        bytes4 selector = bytes4(keccak256("SendingToBlacklisted(address)"));
        //transfer should revert, receiver address is blacklisted
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedReceiver));
        funWiSan.transferFrom(sender1, blacklistedReceiver, 1_000_000);
    }
}