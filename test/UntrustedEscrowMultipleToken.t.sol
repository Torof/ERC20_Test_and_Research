// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/UntrustedEscrowMultipleToken.sol";
import "./helper/ERC20T.sol";

contract UntrustedEscrowMultipleTokenTest is Test {
    UntrustedEscrowMultipleToken public unEsMuTo;
    ERC20T public token;
    address public ownerEscrow = vm.addr(10);
    address public ownerToken = vm.addr(11);
    address public mockOne = vm.addr(12);

    function setUp() public {
        vm.prank(ownerToken);
        token = new ERC20T(10_000_000);

        vm.prank(ownerEscrow);
        unEsMuTo = new UntrustedEscrowMultipleToken();

    }

    function testDeployment()public {}

    //  ------------- DEPOSIT ------------------

    function testDeposit(address sender, address recipient) public {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(recipient != sender);

        vm.prank(ownerToken);
        token.transfer(sender, 1_500);

        vm.startPrank(sender);
        token.approve(address(unEsMuTo), 5_000);
        unEsMuTo.deposit(recipient, address(token), 1_200);
    }

    function testDepositRevert1(address sender, address recipient) public {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(recipient != sender);

        vm.prank(ownerToken);
        ERC20T noSupplyToken = new ERC20T(0);

        vm.startPrank(sender);
        noSupplyToken.approve(address(noSupplyToken), 5_000);
        vm.expectRevert(abi.encodePacked("no total supply"));
        unEsMuTo.deposit(recipient, address(noSupplyToken), 1_200);
    }

    function testDepositRevert2(address sender, address recipient) public {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(recipient != sender);

        address random = vm.addr(100);

        vm.startPrank(sender);
        vm.expectRevert(abi.encodePacked("not a contract"));
        unEsMuTo.deposit(recipient, random, 1_200);
    }

    function testDepositRevert1(address sender) public {
        vm.assume(sender != address(0));

        vm.prank(sender);
        vm.expectRevert(abi.encodePacked("no zero address receiver"));
        unEsMuTo.deposit(address(0), address(token), 1_200);
    }

    // -------------- WITHDRAW -----------------

    function mockDeposit(address sender, address recipient) public {
        vm.prank(ownerToken);
        token.transfer(sender, 1_500);

        vm.startPrank(sender);
        //approve contract to transfer funds 
        token.approve(address(unEsMuTo), 5_000);

        //creation of an escrow with deposit of an arbitrary ERC20 token fund
        unEsMuTo.deposit(recipient, address(token), 1_200);
    }

    //BUG: with fuzzing detects 1200 != 2400 (10k runs)
    function testWithdraw(address sender, address recipient) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) && 
            sender != recipient
        );

        //create deposit
        mockDeposit(sender, recipient);

        //balance of recipient before withdrawing
        uint balanceBefore = token.balanceOf(recipient);

        //Skip the withdraw buffer of 3 days
        skip(4 days);
        vm.prank(recipient);
        unEsMuTo.withdraw(1);

        //balance of recipient after withdrawing
        uint balanceAfter = token.balanceOf(recipient);

        UntrustedEscrowMultipleToken.Escrow memory escr = unEsMuTo.escrow(1);

        //Verify that escrow isRedeemed = true, and that recipient's balance is updated 
        assertEq(balanceAfter, balanceBefore + 1_200, "balance not = 1200");
        assertTrue(escr.isRedeemed, "funds not redeemed");
        assertGt(escr.claimTime, 0, "claimTime not zero");
    }

    function testRevertWithdrawCallerIsNotRecipient(address sender, address recipient, address notRecipient) public {
        vm.assume(
        sender != address(0) && 
        recipient != address(0) &&
        notRecipient != address(0) &&
        recipient != notRecipient &&
        sender != notRecipient
        );
        //create deposit
        mockDeposit(sender, recipient);

        //Skip the withdraw buffer of 3 days
        skip(4 days);

        vm.startPrank(notRecipient);
        //MUST revert
        vm.expectRevert(abi.encodePacked("caller is not recipient"));
        unEsMuTo.withdraw(1);
    }

    function testRevertWithdrawFundsAlreadyClaimed(address sender, address recipient) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            sender != recipient
        );
        //create deposit
        mockDeposit(sender, recipient);

        //Skip the withdraw buffer of 3 days
        skip(4 days);
    
        vm.startPrank(recipient);

        //Withdraw funds
        unEsMuTo.withdraw(1);

            //MUST revert
        vm.expectRevert(abi.encodePacked("funds already claimed"));

        //Withdraw funds
        unEsMuTo.withdraw(1);
    }

    function testRevertWithdrawCannotBeClaimedYet(address sender, address recipient, uint256 time) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            sender != recipient
        );
        vm.assume(time < 3 days);

        //create deposit
        mockDeposit(sender, recipient);

        //Skip time below 3 days buffer, to be before claim time
        skip(time);
    
        vm.startPrank(recipient);

            //MUST revert
        vm.expectRevert(abi.encodePacked("cannot be claimed yet"));
        //Withdraw funds
        unEsMuTo.withdraw(1);
    }

    // -------------- APPROVAL -----------------

    function testApproveUnlocking(address sender, address recipient) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            sender != recipient
        );
        
        //create deposit
        mockDeposit(sender, recipient);

        //
        skip(6 weeks + 1 minutes);

        vm.prank(sender);
        unEsMuTo.approveUnlocking(1);

        assertTrue(unEsMuTo.isUnlocked(1));

        assertFalse(unEsMuTo.escrow(1).isRedeemed, "not unlocked should be false");
    }

    function testRevertApproveUnlockingOnlySenderCanApprove(address sender, address recipient, address notSender) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            notSender != address(0) &&
            sender != recipient &&
            notSender != sender
        );
        
        //create deposit
        mockDeposit(sender, recipient);

        //
        skip(6 weeks + 1 minutes);

        vm.prank(notSender);
        vm.expectRevert(abi.encodePacked("only sender can approve"));
        unEsMuTo.approveUnlocking(1);

        assertFalse(unEsMuTo.isUnlocked(1));
    }

    function testRevertApproveUnlockingOnlyAfter6Weeks() public {}

    function testRevertApproveUnlockingEscrowIsOver() public {}

    // -------------- UNLOCKING ----------------

    function testUnlocking() public {}

    function testRevertUnlocking1() public {}

    function testRevertUnlocking2() public {}
}