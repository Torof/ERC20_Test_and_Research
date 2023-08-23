// SPDX-License-Identifier: NONE

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
@author Torof 
@notice 
@dev use of block.timestamp MUST implement safer ways (such as oracle).
*/

//CHECK: use ERC165Checker ?
//ALERT: no way to unlock funds
//TODO: multisig for unlocking funds
//CHECK: use of ENUM for contractChecks ? (0 = notContract, 1 = noTotalSupply, 2 = ERC71, 3 = checksPassed)


contract UntrustedEscrowMultipleToken  {
    using Address for address;
    using SafeERC20 for IERC20;

    bytes4 private constant IERC721_INTERFACE_ID = 0x80ac58cd;
    address public warden;
    mapping(uint256 => Escrow) private _escrows;
    mapping(address => mapping(address => uint256)) private _balanceOf;
    uint256 public escrowSupply;

    event Deposited(address indexed sender, uint256 amount, uint256 indexed escrowIndex);
    event Withdrawn(address indexed recipient, uint256 amount, uint256 indexed escrowIndex);


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
        require(_contractChecks(token), "CHECKS: failed");
        //implement check because token contract origin is unsure
        require(token.allowance(msg.sender, address(this)) >= amount, "ERC20: insufficient allowance");

        //Create a new escrow
        Escrow escrow_ = new Escrow(msg.sender, recipient, amount, block.timestamp, false);

        //register the escrow by index
        escrows[escrowSupply] = escrow_;
        escrowSupply++;

        //update recipient balance of token to withdraw
        _balanceOf[recipient][token] = amount;

        //Send funds to contracts for holding
        token.safeTransferFrom(token, msg.sender, address(this), amount);

        emit Deposited(sender, amount, escrowSupply - 1);
    }

    //CHECK: if using ENUM, can use event to log error;
    //CHECK: use ERC165Checker ?
    function _contractChecks(address token) internal view returns(bool){
        //Verify that address given is a contract;
        require(address(token).isContract(), "not a contract");
        
        //Verify that contracts implements a totalSupply
        (bool success,bytes memory data) = token.staticcall(abi.encode("totalSupply()"));
        uint decodedData = abi.decode(data, (uint256));
        require(success && decodedData > 0);

        //verifies that address is not an ERC721 compliant
        try token.staticcall(abi.encodeWithsignature("supportsInterface(bytes4)", IERC721_INTERFACE_ID)) {
            revert("is ERC721");
        } catch {}

        return true;
    }

    function withdraw(uint256 escrowIndex) external {
        Escrow memory escrow_ = escrows[escrowIndex];

        require(escrow_.recipient == msg.sender, "caller is not recipient");
        require(!escrow_.isRedeemed, "funds already redeemed");
        require(block.timestamp > escrow_.initTime + 3 days, "cannot be redeemed yet");

        escrows[escrowIndex].claimTime = block.timestamp;
        escrows[escrowIndex].isRedeemed = true;

        token.safeTransfer(token, escrow_.recipient, escrow_.amount);
        emit Withdrawn(escrow_.recipient, escrow_.amount, escrowIndex);
    }

    function unlockFunds() external {

    }

}