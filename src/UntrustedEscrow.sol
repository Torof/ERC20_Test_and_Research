// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UntrustedEscrow is ERC20 {
    address public owner;

    constructor(address owner_, string memory name, string memory symbol) ERC20(name, symbol) {
        owner = owner_;
    }
}