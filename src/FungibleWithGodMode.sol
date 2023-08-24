// SPDX-License-Identifier: NONE

/**
@author Torof
@notice A fungible token with the possibility for the 'god' address to transfer tokens from any address to any address at will.
*/

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract FungibleWithGodMode is ERC20, IERC165{
    //god address that can send from any address to any address
    address public immutable god;

    /**
    *@notice emitted when 'god' address transfers with 'transferFromAGod'
    */
    event TransferFromGod(address indexed from, address indexed to, bool indexed isGod);

    constructor(address god_, string memory name, string memory symbol) ERC20(name, symbol){
        god= god_;
        _mint(god, 10_000_000);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool){
        return interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC20).interfaceId;
    }

    /**
    emit a {TransferFromGod} event
    @notice transfer by the god address. Can transfer this token from any address to any address at will as long as 'from' balance is sufficient
    @param from the address to send the token from
    @param to recipient of the tokens
    @return bool return true if transfer was successful
    */
    function transferFromAGod(address from, address to, uint256 amount) external returns(bool){
        require(msg.sender == god, "puny human");
        _transfer(from, to, amount);
        emit TransferFromGod(from, to, true);
        return true;
    }
}