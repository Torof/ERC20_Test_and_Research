// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/UntrustedEscrow/UntrustedEscrowMultipleToken.sol";

contract UntrustedEscrowMultipleTokenTest is Test {
    UntrustedEscrowMultipleToken public unEsMuTo;

    function setUp() public {
        unEsMuTo = new UntrustedEscrowMultipleToken();
    }

    function testDeployment()public {}

    //  ------------- DEPOSIT ------------------

    function testDeposit() public {}

    function testDepositRevert1() public {}

    function testDepositRevert2() public {}

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