// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FungibleWithGodMode.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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

    function testSupportInterface(bytes4 wrongInterfaceId) public {
        vm.assume(wrongInterfaceId != type(IERC20).interfaceId);
        vm.assume(wrongInterfaceId != type(IERC165).interfaceId);
        bool supportsIERC20 = funWiGoMo.supportsInterface(type(IERC20).interfaceId);
        bool supportsIERC165 = funWiGoMo.supportsInterface(type(IERC165).interfaceId);

        bool otherbytes4 = funWiGoMo.supportsInterface(wrongInterfaceId);

        assertTrue(supportsIERC20);
        assertTrue(supportsIERC165);
        assertFalse(otherbytes4);
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