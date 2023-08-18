// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FungibleWithSanction is ERC20 {
    address public immutable admin;

    mapping(address => bool) private _isBlacklisted;

    error SendingFromBlacklisted(address);
    error SendingToBlacklisted(address);
    error Blacklisted(address);
    error NotBlacklisted(address);
    error NotAdmin();

    modifier onlyAdmin() {
        if(msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(
        address admin_,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        admin = admin_;
        _mint(admin, 10_000_000);
    }

    function addToBlacklist(address toBlacklist) public onlyAdmin {
        if(_isBlacklisted[toBlacklist]) revert Blacklisted(toBlacklist);
        _isBlacklisted[toBlacklist] = true;
    }

    function removeFromBlacklist(address toRemoveFromBlacklist) public onlyAdmin {
        if(!_isBlacklisted[toRemoveFromBlacklist]) revert NotBlacklisted(toRemoveFromBlacklist);
        _isBlacklisted[toRemoveFromBlacklist] = false;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (_isBlacklisted[from])
            revert SendingFromBlacklisted(from);
        if (_isBlacklisted[to]) revert SendingToBlacklisted(to);
        super._transfer(from, to, amount);
    }


    function isBlacklisted(address toCheck) public view returns(bool){
        return _isBlacklisted[toCheck];
    }
}


// function transfer(
    //     address to,
    //     uint256 amount
    // ) public override returns (bool) {
    //     if (_isBlacklisted[msg.sender])
    //         revert SendingFromBlacklisted(msg.sender);
    //     if (_isBlacklisted[to]) revert SendingToBlacklisted(to);
    //     super.transfer(to, amount);
    //     return true;
    // }

    // function transferFrom(address from, address to, uint256 amount) public override returns(bool){
    //     if (_isBlacklisted[from])
    //         revert SendingFromBlacklisted(from);
    //     if (_isBlacklisted[to]) revert SendingToBlacklisted(to);
    //     super.transferFrom(from, to, amount);
    //     return true;
    // }
