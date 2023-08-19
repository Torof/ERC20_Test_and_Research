## ERC20 main problem

ERC20 has a lack of important feature.
When sending a token with `transfer` and `transferFrom` there is no possibility to verify if the **receiver is a contract** and if it can **handle the receiving and sending** of this token. It can result in the token being lost and **locked for ever**.

The standard ***ERC721*** introduced the concept of Hook with the interface IERC721Receiver.

> A wallet/broker/auction application MUST implement the wallet interface if it will accept safe transfers.

> When transfer is complete, this function
> checks if `_to` is a smart contract (code size > 0). If so, it calls
> `onERC721Received` on `_to` and throws if the return value is not
> `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.

## Proposed solutions

Several ERC were created to solve this problem, such as:

- ERC223
- ERC1155
- ERC667
- ERC777
- ERC1363 

Here is a comparison table made by Bard AI:

![Comparison table of solutions to ERC20 short comings](./assets/ERC-comparison-table-Bard.png "Comparison-table")
