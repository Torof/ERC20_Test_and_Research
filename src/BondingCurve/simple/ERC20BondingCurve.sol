// SPDX-License-Identifier: NONE

/**
FEATURES:
- Can receive ERC20, ERC1363, ERC777
- Will not accept ERC777 payments
- Accepts ERC1363 and ERC20 payments
- Possibility for admin to unlock ERC20 tokens sent directly with no Hook ?
- Implements a list of tokens addresses than are accepted, others will be rejected.
- Linear bonding curve
- ERC20 vault ?
*/

pragma solidity 0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ERC20BondingCurve is IERC165, ERC20 {
    using Math for *;
// ========================
//    EVENTS
// ========================

    event TokenBought(address indexed buyer, uint256 etherReceived, uint256 tokenIssuedAmount);
    event TokenSold(address indexed seller, uint256 tokenBurned, uint256 etherSent);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    receive() external payable {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC20).interfaceId;
    }

    //
    function buyToken(uint256 amount) public payable {
        uint256 initialTotalSupply = totalSupply() + 1;
        uint256 finalTotalSupply = initialTotalSupply + amount - 1;  // Minus 1 because totalSupply is already incremented in _mint
    
        uint256 priceToPay = (amount * (initialTotalSupply + finalTotalSupply))  / 2 ;
    
        require(msg.value == priceToPay * 1 ether, "Not enough ether");
    
        _mint(msg.sender, amount);
    
        emit TokenBought(msg.sender, priceToPay, amount);
    }


    function sellToken() external {}
}

