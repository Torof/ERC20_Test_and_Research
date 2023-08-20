## ERC20 main problems

- ### lost funds

ERC20 has a lack of important feature.
The main problem is lack of possibility to handle incoming ERC20 transactions, that were performed via `transfer` and `transferFrom` function of ERC20 token.
It can result in the token being lost and **locked for ever**.

The standard ***ERC721*** introduced the concept of Hook with the interface IERC721Receiver.

`IERC721.sol`:

> A wallet/broker/auction application MUST implement the wallet interface if it will accept safe transfers.

`safeTransferFrom`:

> When transfer is complete, this function
> checks if `_to` is a smart contract (code size > 0). If so, it calls
> `onERC721Received` on `_to` and throws if the return value is not
> `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.



- ### several transactions

Needs to call `approve` and then `transferFrom`

- ### inflexible logic

 No hooks or call to external contracts so no possibility to extend functionnality.

## Proposed solutions to ERC20 short comings

Several ERC were created to solve this problem, such as:

 **ERC223, ERC667, ERC1155, ERC777, ERC1363** (and many others but here are the most discussed and commonly found).

#### Non Final ERCs

- [ERC223](https://eips.ethereum.org/EIPS/eip-223  "ERC223-EIPS-REVIEW")
    - [ERC223_issues](https://github.com/ethereum/EIPs/issues/223 "ERC223 issues")
- [ERC667](https://github.com/ethereum/EIPs/issues/677  "ERC667-NOT AN EIP") *ERC667 is not an EIP*

#### Final ERC but not retrocompatible with ERC20
- [ERC1155](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md  "ERC1155- FINAL")

#### Final ERC and compatible with ERC20

- [ERC777](https://eips.ethereum.org/EIPS/eip-777 "ERC777-EIPS-FINAL")
- [ERC1363](https://eips.ethereum.org/EIPS/eip-777 "ERC1363-EIPS-FINAL") 

*Here is a comparison table made by Bard AI*:

![Comparison table of solutions to ERC20 short comings](./assets/ERC-comparison-table-Bard.png "Comparison-table")


## ERC777

#### What does it solve

- hooks

#### What can be potential pitfalls

- No security checks

- external call / possible reentrancy

- use of ERC1820 registry

- added complexity

## ERC1363

#### What does it solve

- payable token

#### What can be potential pitfalls

- external call

- added complexity

_________________________________

# Conclusion

ERC777 is in discussion to be deprecated and ot recommanded for use, because it can be dangerous if not well implemented. There is added complexity which makes it harder for wide adoption and use by beginner developers.

ERC1363 is FINAL but not widely adopted yet.
Less complexity than ERC777 and on top of safety checks, it allows a high level functionnality by receiving contracts.

### SafeERC20 library

**What is SafeERC20**


*here is more thorough and deep analysis of SafeERC20*:
[SafeERC20_Paper](./SafeERC20.md)

[SafeERC20_Code](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol "SafeERC20 by OpenZeppelin")
