# SafeERC20

SafeERC20 is a library created by OpenZeppelin to try to solve some of ERC20 shortcomings and security issues. 

It allows to wrap around an external token, and use wrappers functions such as `safeTransfer`, `safeTransferFrom`,  `safeIncreaseAllowance` and `safeDecreaseAllowance`.

 ### Solutions it brings:

- **Safe wrapping:** It makes sure that all wrapped functions will always return a boolean.

- **Error handling:** It can handle both cases where the external ERC20 transaction fails or throw an error, preventing the transaction from failing.

- **Safe approvals:** It allows to prevent approval racing *where a malicious address can use twice an allowance when an allowance is changed* by introducing `safeIncreaseAllowance` and `safeDecreaseAllowance`.

### possible problems

- **Extra gas cost:** since it adds function calls, it adds computation and therefore extra cost.

- **Trusting an external library**