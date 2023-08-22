// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UntrustedEscrow  {
    using SafeERC20 for IERC20;
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
        //CHECK if address is contract
        //Check if address implements transfer & name & totalSupply
        //Check that address is NOT ERC721
    }

    function redeemFunds() external {}

}