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

//CHECK: use ERC165Checker ?
//ALERT: no way to unlock funds
//TODO: multisig for unlocking funds
//CHECK: use of ENUM for contractChecks ? (0 = notContract, 1 = noTotalSupply, 2 = ERC71, 3 = checksPassed)


contract UntrustedEscrowMultipleToken is Ownable2Step {
    using Address for address;
    using SafeERC20 for IERC20;

    bytes4 private constant _IERC721_INTERFACE_ID = 0x80ac58cd;
    mapping(uint256 => Escrow) private _escrows;
    mapping(uint256 => bool) private _unlockingEscrow;
    mapping(address => mapping(address => uint256)) private _balanceOf;
    uint256 public escrowSupply;

    event Deposited(address indexed sender, uint256 amount, uint256 indexed escrowIndex);
    event Withdrawn(address indexed recipient, uint256 amount, uint256 indexed escrowIndex);
    event UnlockingApproved(uint256 indexed escrowIndex);
    event Unlocked(uint256 indexed escrowIndex);

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
    @dev the function is made public so that it can be called as a view on the application side
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

    function withdraw(uint256 escrowIndex) external {
        Escrow memory escrow_ = _escrows[escrowIndex];

        require(escrow_.recipient == msg.sender, "caller is not recipient");
        require(!escrow_.isRedeemed && escrow_.claimTime != 0, "funds already redeemed");
        require(block.timestamp > escrow_.initTime + 3 days, "cannot be redeemed yet");

        //Set claimTime to now and isRedeemed to true to prevent re-using the funds from escrow
        _escrows[escrowIndex].claimTime = uint64(block.timestamp);
        _escrows[escrowIndex].isRedeemed = true;

        //Transfer from the contract to the recipient
        IERC20(escrow_.token).safeTransfer(escrow_.recipient, escrow_.amount);
        emit Withdrawn(escrow_.recipient, escrow_.amount, escrowIndex);
    }

    function balanceOf(address recipient, address token) external view returns(uint256){
        return _balanceOf[recipient][token];
    }

    function approveUnlocking(uint escrowIndex) external {
        Escrow memory escrow_ = _escrows[escrowIndex];
        require(msg.sender == escrow_.sender, "only sender can approve");
        require(block.timestamp > escrow_.initTime + 6 weeks, "only after 6 weeks");
        require(!escrow_.isRedeemed, "escrow is over");

        //sender approves refund
        _unlockingEscrow[escrowIndex] = true;

        emit UnlockingApproved(escrowIndex);
    }

    
    function unlockFunds(uint escrowIndex) external onlyOwner {
        Escrow memory escrow_ = _escrows[escrowIndex];
        require(block.timestamp > escrow_.initTime + 6 weeks, "only after 6 weeks");
        require(_unlockingEscrow[escrowIndex], "sender hasn't approved");

        //transfer the funds back to the sender
        IERC20(escrow_.token).safeTransfer(escrow_.sender, escrow_.amount);

        emit Unlocked(escrowIndex);
    }

}