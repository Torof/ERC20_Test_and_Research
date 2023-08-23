// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//CHECK: use ERC165Checker ?
//ALERT: no way to unlock funds

contract UntrustedEscrow  {
    using SafeERC20 for IERC20;

    address public warden;
    IERC20 public immutable token;

    struct Escrow {
        address sender;
        address recipient;
        uint256 amount;
        uint256 initTime;
        bool isRedeemed;
    }

    constructor (address token_) {
        token = IERC20(token_);
    }

    function depositFunds(address recipient, uint256 amount) external {}

    function _contractChecks() internal returns(bool){
        //CHECK: if address is contract
        //CHECK if address implements transfer & name & totalSupply
        //CHECK that address is NOT ERC721
    }

    function redeemFunds() external {}

}