// SPDX-License-Identifier: NONE

/**
@author Torof
@title FungibleTokenWithSanction
@notice A simple ERC20 with the possibility for an admin to prevent an address from sending or receiving this contract's token.

@dev possibility to implement an enumerable model for the blacklist. Not implemented for now.
*/

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";


contract FungibleWithSanction is ERC20, Ownable2Step, IERC165 {

    mapping(address => bool) private _isBlacklisted;

    /**
    @notice emitted when an address is blacklisted
    */
    event AddedToBlacklist(address indexed blacklistedAddress);

    /**
    @notice emitted when an address is removed from blacklist
    */
    event RemovedFromBlacklist(address indexed unBlacklistedAddress);

    error SendingFromBlacklisted(address);
    error SendingToBlacklisted(address);
    error Blacklisted(address);
    error NotBlacklisted(address);
    error NotAdmin();

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(owner(), 10_000_000);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool){
        return interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC20).interfaceId;
    }

    /**
    emit a {AddedToBlacklist} event
    @notice allows the admin address to sanction an address from sending and receiving the token
    @param toBlacklist the address to sanction
    @dev MUST revert if caller is not admin or the address is already blacklisted
    */
    function addToBlacklist(address toBlacklist) external onlyOwner {
        if(_isBlacklisted[toBlacklist]) revert Blacklisted(toBlacklist);
        _isBlacklisted[toBlacklist] = true;
        emit AddedToBlacklist(toBlacklist);
    }

    /**
    emit a {RemovedFromBlacklist} event
    @notice allows the admin address to remove lift the sanction on an address
    @param toRemoveFromBlacklist the address to lift the sanction from
    @dev MUST revert if caller is not admin or the address is not blacklisted
    */
    function removeFromBlacklist(address toRemoveFromBlacklist) external onlyOwner {
        if(!_isBlacklisted[toRemoveFromBlacklist]) revert NotBlacklisted(toRemoveFromBlacklist);
        _isBlacklisted[toRemoveFromBlacklist] = false;
        emit RemovedFromBlacklist(toRemoveFromBlacklist);
    }

    /**
    @notice internal transfer used in both transfer and transferFrom. prevent a blacklisted address from sending or receiving the token.
    @param from the address to send the tokens from
    @param to the recipient address of the tokens
    @param amount the amount to transfer
    @dev MUST revert with error if sender or receiver is blacklisted.
    */
    function _transfer(address from, address to, uint256 amount) internal override {
        if (_isBlacklisted[from])
            revert SendingFromBlacklisted(from);
        if (_isBlacklisted[to]) revert SendingToBlacklisted(to);
        super._transfer(from, to, amount);
    }

    /**
    @notice verifies if an address
    @param toCheck the address to verify if blacklisted
    @return bool return true if address is blacklisted, otherwise return false 
    */
    function isBlacklisted(address toCheck) public view returns(bool){
        return _isBlacklisted[toCheck];
    }
}
