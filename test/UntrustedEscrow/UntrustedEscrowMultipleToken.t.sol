// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/UntrustedEscrow/UntrustedEscrowMultipleToken.sol";
import "../helper/ERC20T.sol";

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

    function testWithdraw() public {}

    function testRevertWithdraw1() public {}

    function testRevertWithdraw2() public {}

    function testRevertWithdraw3() public {}

    // -------------- APPROVAL -----------------

    function testApproveUnlocking() public {}

    function testRevertApproveUnlocking1() public {}

    function testRevertApproveUnlocking2() public {}

    function testRevertApproveUnlocking3() public {}

    // -------------- UNLOCKING ----------------

    function testUnlocking() public {}

    function testRevertUnlocking() public {}
}