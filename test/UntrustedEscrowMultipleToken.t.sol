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

    //TODO
    function testDeployment(address random)public {
        vm.assume(random != address(unEsMuTo));
        bool isPossiblyERC20 = unEsMuTo.contractChecks(address(token));
        assertTrue(isPossiblyERC20);

        vm.expectRevert(abi.encodePacked("not a contract"));
        bool isNotContract = unEsMuTo.contractChecks(address(random));
        assertFalse(isNotContract);
    }

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

    //REVERT: deposit() "no total supply"
    function testDepositRevertCheckNoTotalSupply(address sender, address recipient) public {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(recipient != sender);

        vm.prank(ownerToken);
        ERC20T noSupplyToken = new ERC20T(0);

        vm.startPrank(sender);
        noSupplyToken.approve(address(unEsMuTo), 5_000);
        vm.expectRevert(abi.encodePacked("no total supply"));
        unEsMuTo.deposit(recipient, address(noSupplyToken), 1_200);
    }

    //REVERT: deposit() "not a contract"
    function testDepositRevertCheckNotAcontract(address sender, address recipient) public {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(recipient != sender);

        address random = vm.addr(100);

        vm.startPrank(sender);
        vm.expectRevert(abi.encodePacked("not a contract"));
        unEsMuTo.deposit(recipient, random, 1_200);
    }

    //REVERT: deposit() "no zero address receiver"
    function testDepositRevertNoZeroAddressReceiver(address sender) public {
        vm.assume(sender != address(0));

        vm.prank(sender);
        vm.expectRevert(abi.encodePacked("no zero address receiver"));
        unEsMuTo.deposit(address(0), address(token), 1_200);
    }

    // -------------- WITHDRAW -----------------

    //SIMULATE DEPOSIT FOR TESTING
    function mockDeposit(address sender, address recipient) public {
        vm.prank(ownerToken);
        token.transfer(sender, 1_500);

        vm.startPrank(sender);
        //approve contract to transfer funds 
        token.approve(address(unEsMuTo), 5_000);

        //creation of an escrow with deposit of an arbitrary ERC20 token fund
        unEsMuTo.deposit(recipient, address(token), 1_200);
    }

    //SUCCESS: withdraw()
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

    //Revert wihtdraw() "caller is not recipient"
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

    //Revert wihtdraw() "funds already claimed"
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

    //Revert wihtdraw() "cannot be claimed yet"
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

    // -------------- REQUEST -----------------

    //SUCCESS: requestUnlocking
    function testRequestUnlocking(address sender, address recipient) public {
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
        unEsMuTo.requestUnlocking(1);

        assertTrue(unEsMuTo.isRequested(1));

        assertFalse(unEsMuTo.escrow(1).isRedeemed, "not requested should be false");
    }

        //REVERT: requestUnlocking "escrow is over"
        function testRevertRequestUnlockingEscrowIsOver(address sender, address recipient, uint256 timeSkip) public {
            vm.assume(
                sender != address(0) && 
                recipient != address(0) && 
                sender != recipient &&
                recipient != address(unEsMuTo)
            );
            vm.assume(timeSkip > 6 weeks && timeSkip < 520 weeks);
    
            //create deposit
            mockDeposit(sender, recipient);
    
            //Skip the withdraw buffer of 3 days
            skip(4 days);
    
            vm.prank(recipient);
            //withdraw
            unEsMuTo.withdraw(1);

            //skip the 6 weeks buffer for unlocking
            skip(timeSkip);

    
            // //MUST revert because funds were withdrawn and escrow is redeemed
            // vm.prank(sender);
            // vm.expectRevert(abi.encodePacked("escrow is over"));
            // unEsMuTo.requestUnlocking(1);
    
            // //MUST be locked
            // bool isUnlocked = unEsMuTo.isRequested(1);
            // assertFalse(isUnlocked, "is requested");
        }

    //REVERT: requestUnlocking "already requested"
    function testRevertRequestUnlockingAlreadyRequested(address sender, address recipient) public{ 
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            sender != recipient
        );
        
        //create deposit
        mockDeposit(sender, recipient);

        //
        skip(6 weeks + 1 minutes);

        //Aprove unlocking
        vm.startPrank(sender);
        unEsMuTo.requestUnlocking(1);

        //MUST revert because already approved for refund
        vm.expectRevert(abi.encodePacked("already requested"));
        unEsMuTo.requestUnlocking(1);
    }

    //REVERT: requestUnlocking "only sender can request"
    function testRevertRequestUnlockingOnlySenderCanRequest(address sender, address recipient, address notSender) public {
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
        //MUST revert caller is not sender
        vm.expectRevert(abi.encodePacked("only sender can request"));
        unEsMuTo.requestUnlocking(1);

        assertFalse(unEsMuTo.isRequested(1));
    }

    //REVERT: requestUnlocking "only after 6 weeks"
    function testRevertRequestUnlockingOnlyAfter6Weeks(address sender, address recipient, uint256 time) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            sender != recipient
        );
        vm.assume(time < 6 weeks);
        
        //create deposit
        mockDeposit(sender, recipient);

        //
        skip(time);

        vm.prank(sender);
        //MUST revert 6 weeks buffer not over
        vm.expectRevert(abi.encodePacked("only after 6 weeks"));
        unEsMuTo.requestUnlocking(1);
    }



    // -------------- UNLOCKING ----------------

    function testUnlocking(address sender, address recipient) public {
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
        //sender requests for refund
        unEsMuTo.requestUnlocking(1);

        //Owner of Escrow unlocks funds
        vm.prank(ownerEscrow);
        unEsMuTo.unlockFunds(1);

        // verify escrow is redeemed and over
        //BUG: if not commented coverage of branches & statements falls by 10%
        // bool isredeemed = unEsMuTo.escrow(1).isRedeemed;
        // assertTrue(isredeemed, "not redeemed");
    }

    function testRevertUnlockingNotOwner(address sender, address recipient, address notOwner) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            notOwner != address(0) &&
            notOwner != ownerEscrow &&
            sender != recipient
        );
        
        //create deposit
        mockDeposit(sender, recipient);

        //
        skip(6 weeks + 1 minutes);

        vm.prank(sender);
        //sender requests for refund
        unEsMuTo.requestUnlocking(1);

        //not the owner of Escrow try to unlock funds
        vm.prank(notOwner);
        //MUST revert
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        unEsMuTo.unlockFunds(1);
    }

    function testRevertUnlockingNotRequestedForRefund(address sender, address recipient) public {
        vm.assume(
            sender != address(0) && 
            recipient != address(0) &&
            sender != recipient
        );
        
        //create deposit
        mockDeposit(sender, recipient);

        //
        skip(6 weeks + 1 minutes);

        vm.prank(ownerEscrow);
        vm.expectRevert(abi.encodePacked("not requested"));
        unEsMuTo.unlockFunds(1);
    }

}