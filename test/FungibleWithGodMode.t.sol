// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FungibleWithGodMode.sol";

contract FungibleWithGodModeTest is Test {
    FungibleWithGodMode public funWiGoMo;
    address immutable public god = vm.addr(1);

    event TransferFromGod(address indexed from, address indexed to, bool indexed isGod);


    function setUp() public {
        funWiGoMo = new FungibleWithGodMode(god, "GodToken", "GT");
    }

    function testSetUp() public {
        assertEq(funWiGoMo.name(), "GodToken");
        assertEq(funWiGoMo.symbol(), "GT");
        assertEq(funWiGoMo.god(), god);
        assertEq(funWiGoMo.balanceOf(god), 10_000_000);
        assertEq(funWiGoMo.totalSupply(), 10_000_000);
    }

    function testWithFuzzingTransferFromAGod(address from, address to) public {
        vm.assume(from != address(0));
        vm.assume(to != address(0));
        deal(address(funWiGoMo), from, 1_000_000);

        vm.prank(god);
        vm.expectEmit();
        emit TransferFromGod(from, to, true);
        bool transferCompleted = funWiGoMo.transferFromAGod(from, to, 500_000);
        assertTrue(transferCompleted);
    }

    function testWithFuzzingRevertTransferromAGodIfNotAGod(address sender, address from, address to) public {
        vm.assume(from != address(0));
        vm.assume(to != address(0));
        vm.assume(sender != god);
        deal(address(funWiGoMo), from, 1_000_000);

        vm.prank(sender);
        vm.expectRevert("puny human");
        bool transferCompleted = funWiGoMo.transferFromAGod(from, to, 500_000);
        assertFalse(transferCompleted);
    }

}