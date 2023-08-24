// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FungibleWithSanction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";


contract FungibleWithSanctionTest is Test {
    FungibleWithSanction public funWiSan;
    address immutable public owner = vm.addr(1);
    address immutable public sender1 = vm.addr(2);
    address immutable public senderBlacklisted = vm.addr(3);
    address immutable public receiver1 = vm.addr(4);
   

    event AddedToBlacklist(address indexed blacklistedAddress);
    event RemovedFromBlacklist(address indexed unBlacklistedAddress);
    
    function setUp() public {
        vm.prank(owner);
        funWiSan =  new FungibleWithSanction("NoPowerToken", "NPT");
    }

    function testSetUp() public {
        assertEq(funWiSan.name(), "NoPowerToken");
        assertEq(funWiSan.symbol(), "NPT");
        assertEq(funWiSan.owner(), owner);
        assertEq(funWiSan.balanceOf(owner), 10_000_000);
        assertEq(funWiSan.totalSupply(), 10_000_000);
    }

    function testSupportInterface(bytes4 wrongInterfaceId) public {
        bool supportsIERC20 = funWiSan.supportsInterface(type(IERC20).interfaceId);
        bool supportsIERC165 = funWiSan.supportsInterface(type(IERC165).interfaceId);

        bool otherbytes4 = funWiSan.supportsInterface(wrongInterfaceId);

        assertTrue(supportsIERC20);
        assertTrue(supportsIERC165);
        assertFalse(otherbytes4);
    }

    function testWithFuzzingAddToBlacklist(address blacklistedFuzz) public {
        //address should not be blacklisted
        assertFalse(funWiSan.isBlacklisted(blacklistedFuzz));

        //owner blacklists address
        vm.prank(owner);

        vm.expectEmit();
        // We emit the AddedToBlacklist event we expect to see.
        emit AddedToBlacklist(blacklistedFuzz);
        funWiSan.addToBlacklist(blacklistedFuzz);

        //address should be blacklisted
        assertTrue(funWiSan.isBlacklisted(blacklistedFuzz));
    }

    function testRevertWithFuzzingAddToBlacklistIfBlacklisted(address blacklistedFuzz) public {
        //owner blacklists address
        vm.startPrank(owner);
        funWiSan.addToBlacklist(blacklistedFuzz);

        //Should revert , user already blacklisted
        bytes4 selector = bytes4(keccak256("Blacklisted(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedFuzz ));
        funWiSan.addToBlacklist(blacklistedFuzz);
        vm.stopPrank();
    }

    function testRevertAddToBlacklistIfNotOwner(address notOwnerFuzz) public {
        vm.assume(notOwnerFuzz != owner);

        //caller is not admin
        vm.startPrank(notOwnerFuzz);

        //should revert notOwner()
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        funWiSan.addToBlacklist(senderBlacklisted);
        vm.stopPrank();
    }

    function testWithFuzzingRemoveFromBlacklist(address blacklistedFuzz) public {
        //admin blacklists address
        vm.startPrank(owner);
        funWiSan.addToBlacklist(blacklistedFuzz);

        //address should be blacklisted
        assertTrue(funWiSan.isBlacklisted(blacklistedFuzz));

        vm.expectEmit();
        // We emit the RemoveFromBlacklist event we expect to see.
        emit RemovedFromBlacklist(blacklistedFuzz);

        //owner removes from blacklist
        funWiSan.removeFromBlacklist(blacklistedFuzz);

        vm.stopPrank();

        //address should not be blacklisted anymore
        assertFalse(funWiSan.isBlacklisted(blacklistedFuzz));
    }

    function testRevertRemoveFromBlacklistIfNotBlacklisted(address blacklistedFuzz) public {
        vm.startPrank(owner);

        //Should revert , user already blacklisted
        bytes4 selector = bytes4(keccak256("NotBlacklisted(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, blacklistedFuzz ));
        funWiSan.removeFromBlacklist(blacklistedFuzz);
        vm.stopPrank();
    }

    function testWithFuzzingRevertRemoveFromBlacklistIfNotOwner(address notOwnerFuzz) public {
        //make sure fuzz doesn't use revert cases
        vm.assume(notOwnerFuzz != owner);

        vm.prank(owner);
        //owner adds to blacklist
        funWiSan.addToBlacklist(senderBlacklisted);

        //caller is not owner
        vm.startPrank(notOwnerFuzz);
        

        //should revert notOwner()
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        funWiSan.removeFromBlacklist(senderBlacklisted);
        vm.stopPrank();
    }

    function testIsBlacklisted(address blacklisted) public {
        //address should not be blacklisted
        assertFalse(funWiSan.isBlacklisted(blacklisted));

        //admin blacklists address
        vm.prank(owner);
        funWiSan.addToBlacklist(blacklisted);

        //address should be blacklisted
        assertTrue(funWiSan.isBlacklisted(blacklisted));
    }

    function testWithFuzzingTransfer(address senderFuzz) public {
        //make sure fuzz doesn't use revert cases
        vm.assume(senderFuzz != address(0));
        vm.assume(senderFuzz != owner);

        uint balanceSFBefore = funWiSan.balanceOf(senderFuzz);
        uint balanceAdminBefore = funWiSan.balanceOf(owner);

        //admin transfer 1_000_000 to senderFuzz
        vm.prank(owner);
        bool transferExecuted = funWiSan.transfer(senderFuzz, 1_000_000);

        //assert transfer was successful
        assertTrue(transferExecuted);

        uint balanceSFAfter = funWiSan.balanceOf(senderFuzz);
        uint balanceAdminAfter = funWiSan.balanceOf(owner);
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
        funWiSan.approve(owner, 1_000_000);

        //admin transfer 1_000_000 to sender1
        vm.prank(owner);
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
        vm.prank(owner);
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
        vm.prank(owner);
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
        vm.prank(owner);
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
        vm.prank(owner);
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