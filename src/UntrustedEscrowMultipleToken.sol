// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
@author Torof 
@notice 
@dev use of block.timestamp MUST implement safer ways (such as oracle).
*/
//TODO: NatSpec
//CHECK: use ERC165Checker ?
//CHECK: use of ENUM for contractChecks ? (0 = notContract, 1 = noTotalSupply, 2 = ERC71, 3 = checksPassed)


contract UntrustedEscrowMultipleToken is Ownable2Step {
    using Address for address;
    using SafeERC20 for IERC20;

    bytes4 private constant _IERC721_INTERFACE_ID = 0x80ac58cd;
    mapping(uint256 => Escrow) private _escrows;
    mapping(uint256 => bool) private _unlockingEscrow;
    mapping(address => mapping(address => uint256)) private _balanceOf;
    uint256 public escrowSupply;

    event Deposited(address indexed sender, uint256 amount, uint256 indexed index);
    event Withdrawn(address indexed recipient, uint256 amount, uint256 indexed index);
    event UnlockingApproved(uint256 indexed index);
    event Unlocked(uint256 indexed index);

    struct Escrow {
        address token;
        address sender;
        address recipient;
        uint256 amount;
        uint64 initTime;
        uint64 claimTime;
        bool isRedeemed;
    }

    constructor () {
        escrowSupply = 1;
    }

    /**
    emits a {Deposited} event
    @notice a user can deposit an amount of ERC20
    @param recipient the address that will be able to withdraw the funds
    @param token address of the 'supposed' ERC20 contract
    @param amount amount of the fund
    */
    function deposit(address recipient, address token, uint256 amount) external {
        require(recipient != address(0), "no zero address receiver");
        require(contractChecks(token), "CHECKS: failed");

        //implement check because token contract origin is unsure
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "ERC20: insufficient allowance");

        //Create a new escrow
        Escrow memory escrow_ = Escrow(token, msg.sender, recipient, amount, uint64(block.timestamp),0, false);

        //register the escrow by index
        _escrows[escrowSupply] = escrow_;
        escrowSupply++;

        //update recipient balance of token to withdraw
        _balanceOf[recipient][token] = amount;

        //Send funds to contracts for holding
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount, escrowSupply - 1);
    }

    //CHECK: if using ENUM, can use event to log error;
    //CHECK: use ERC165Checker ?
    /**
    @notice implements some checks to ensure as much as possible that called token IS a valid ERC20 contract
    @dev the function is made public so that it can be called as a view on the application side
    @param token address of the 'supposed' ERC20 contract to run checks on
    */
    function contractChecks(address token) public view returns(bool){
        //Verify that address given is a contract;
        require(address(token).isContract(), "not a contract");
        
        //Verify that contracts implements a totalSupply
        (bool success,bytes memory data) = token.staticcall(abi.encodeWithSignature("totalSupply()"));
        uint decodedData = abi.decode(data, (uint256));
        require(success && decodedData > 0, "no total supply");

        //verifies that address is not an ERC721 compliant
        // try token.call(abi.encodeWithSignature("supportsInterface(bytes4)", _IERC721_INTERFACE_ID)) {
        //     revert("is ERC721");
        // } catch {}

        return true;
    }

    /**
    @notice the recipient of funds can withdraw them 3 days after deposit 
    @param index id of the escrow to withdraw the funds from
    @dev
    */
    function withdraw(uint256 index) external {
        Escrow memory escrow_ = escrow(index);

        require(escrow_.recipient == msg.sender, "caller is not recipient");
        require(!escrow_.isRedeemed && escrow_.claimTime == 0, "funds already claimed");
        require(block.timestamp > escrow_.initTime + 3 days, "cannot be claimed yet");

        //Set claimTime to now and isRedeemed to true to prevent re-using the funds from escrow
        _escrows[index].claimTime = uint64(block.timestamp);
        _escrows[index].isRedeemed = true;

        //Transfer from the contract to the recipient
        IERC20(escrow_.token).safeTransfer(escrow_.recipient, escrow_.amount);
        emit Withdrawn(escrow_.recipient, escrow_.amount, index);
    }

    /**
    @notice shows the balance of an address for a particular ERC20
    @param recipient the address to check the balance of
    @param token the address of the 'supposed' ERC20 token
    */
    function balanceOf(address recipient, address token) external view returns(uint256){
        return _balanceOf[recipient][token];
    }

    /**
    @notice the sender of an escrow can approve a refund if owner hasn't claimed the funds for 6 weeks. It should probably be used for problems
    @param index the escrow to unlock
    @dev
    */
    function approveUnlocking(uint index) external {
        Escrow memory escrow_ = escrow(index);
        require(!escrow_.isRedeemed, "escrow is over");
        require(!isUnlocked(index), "already waiting for refunds");
        require(msg.sender == escrow_.sender, "only sender can approve");
        require(block.timestamp > escrow_.initTime + 6 weeks, "only after 6 weeks");

        //sender approves refund
        _unlockingEscrow[index] = true;

        emit UnlockingApproved(index);
    }

    /**
    @notice contract owner can agree to unlock the funds upon request if an escrow's recipient hasn't claimed funds. 
        Once unlocking is approved, funds are sent back to sender and escrow is over.
    @param index id of the escrow
    @dev
    */
    function unlockFunds(uint index) external onlyOwner {
        Escrow memory escrow_ = escrow(index);
        require(isUnlocked(index));
        require(block.timestamp > escrow_.initTime + 6 weeks, "only after 6 weeks");
        require(_unlockingEscrow[index], "sender hasn't approved");
        
        //escrow refunded and locked
        escrow_.isRedeemed = true;

        //transfer the funds back to the sender
        IERC20(escrow_.token).safeTransfer(escrow_.sender, escrow_.amount);

        emit Unlocked(index);
    }

    /// @param index id of the escrow
    /// @return Escrow return the escrow at index
    function escrow(uint256 index) public view returns(Escrow memory){
        return _escrows[index];
    }

    /**
    @notice check if an escrow is unlocked for refund
    @param index id of the escrow
    */
    function isUnlocked(uint256 index) public view returns(bool){
        return  _unlockingEscrow[index];
    }
}