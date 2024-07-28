# Unstablecoin

Unstablecoin is a conceptual project aimed at highlighting the potential risks and vulnerabilities inherent in stablecoin systems, particularly those pegged to fiat currencies. While stablecoins offer a bridge between the volatile cryptocurrency markets and the more stable fiat currencies, they carry inherent risks that can compromise their stability. This project serves as a demonstration platform, simulating various scenarios where the peg might be tested or fail. Our objective is to provide an educational resource that can be used to better understand the complexities and operational risks of fiat-based stablecoins.

### Disclaimer

The source code and any related material provided on this platform are intended for testing purposes only. Please read our full disclaimer before using this code or any related materials in any capacity: [Link](https://github.com/unstablecoin-demo/unstablecoin/blob/main/public/disclaimer.md).

## Address
Proxy contract and implementation contract are deployed and verifiable at the following links: 
https://sepolia.etherscan.io/address/0x91905B47AAeFFdc84D0B39546Eee6417570c19AA#code
https://sepolia.etherscan.io/address/0xCcf20e80664a2f4B94Feb9f99F1BACC9d87ee510#code


## Contract Specification

Chocolate USD (CHOCUSD) is an ERC20 token that is Centrally Minted and Burned by The Chocolate Issuer Limited,
representing the trusted party backing the token with USD.

The code used is a modified version of PYUSD located at https://github.com/paxosglobal/pyusd-contract/blob/master/contracts.

### ERC20 Token

The public interface of Chocolate USD is the ERC20 interface
specified by [EIP-20](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md).

- `name()`
- `symbol()`
- `decimals()`
- `totalSupply()`
- `balanceOf(address who)`
- `transfer(address to, uint256 value)`
- `approve(address spender, uint256 value)`
- `increaseApproval(address spender, uint256 addedValue)`
- `decreaseApproval(address spender, uint256 subtractedValue)`
- `allowance(address owner, address spender)`
- `transferFrom(address from, address to, uint256 value)`

And the usual events.

- `event Transfer(address indexed from, address indexed to, uint256 value)`
- `event Approval(address indexed owner, address indexed spender, uint256 value)`

Typical interaction with the contract will use `transfer` to move the token as payment.
Additionally, a pattern involving `approve` and `transferFrom` can be used to allow another
address to move tokens from your address to a third party without the need for the middleperson
to custody the tokens, such as in the 0x protocol.


#### Warning about ERC20 approve front-running

[There is a well known gotcha](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729) involving the ERC20
`approve` method. The problem occurs when the owner decides to change the allowance of a spender that already has an
allowance. If the spender sends a `transferFrom` transaction at a similar time that the owner sends the new `approve`
transaction and the `transferFrom` by the spender goes through first, then the spender gets to use the original
allowance, and also get approved for the intended new allowance.

To mitigate this risk, we recommend that smart contract users utilize the alternative functions `increaseApproval` and
`decreaseApproval` instead of using `approve` directly.

### Controlling the token supply

The total supply of CHOCUSD is backed by US dollar fiat held in reserve by The Chocolate Issuer Limited.
There is a single `supplyController` address that can mint and burn the token
based on the actual movement of cash in and out of the reserve based on
requests for the purchase and redemption of CHOCUSD.

The supply control interface includes methods to get the current address
of the supply controller, and events to monitor the change in supply of CHOCUSD.

- `supplyController()`

Supply Control Events

- `SupplyIncreased(address indexed to, uint256 value)`
- `SupplyDecreased(address indexed from, uint256 value)`
- `SupplyControllerSet(address indexed oldSupplyController, address indexed newSupplyController)`

### Pausing the contract

In the event of a critical security threat, The Chocolate Issuer Limited has the ability to pause transfers
and approvals of the CHOCUSD token. The ability to pause is controlled by a single `owner` role,
following OpenZeppelin's
[Ownable](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/5daaf60d11ee2075260d0f3adfb22b1c536db983/contracts/ownership/Ownable.sol).
The simple model for pausing transfers following OpenZeppelin's
[Pausable](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/5daaf60d11ee2075260d0f3adfb22b1c536db983/contracts/lifecycle/Pausable.sol).

While paused, the supply controller retains the ability to mint and burn tokens.

### Asset Protection Role

The Chocolate Issuer Limited is regulated by the New York Department of Financial Services (NYDFS). As required by the regulator,
The Chocolate Issuer Limited must have a role for asset protection to freeze or seize the assets of a criminal party when required to do so by
law, including by court order or other legal process.

The `assetProtectionRole` can freeze and unfreeze the CHOCUSD balance of any address on chain.
It can also wipe the balance of an address after it is frozen
to allow the appropriate authorities to seize the backing assets.

Freezing is something that The Chocolate Issuer Limited will not do on its own accord,
and as such we expect to happen extremely rarely. The list of frozen addresses is available
in `isFrozen(address who)`.

### Upgradeability Proxy

To facilitate upgradeability on the immutable blockchain we follow a standard
two-contract delegation pattern: a proxy contract represents the token,
while all calls not involving upgrading the contract are delegated to an
implementation contract.

The delegation uses `delegatecall`, which runs the code of the implementation contract
_in the context of the proxy storage_. This way the implementation pointer can
be changed to a different implementation contract while still keeping the same
data and CHOCUSD contract address, which are really for the proxy contract.

The proxy used here is AdminUpgradeabilityProxy from ZeppelinOS.

## Upgrade Process

The implementation contract is only used for the logic of the non-admin methods.
A new implementation contract can be set by calling `upgradeTo()` or `upgradeToAndCall()` on the proxy,
where the latter is used for upgrades requiring a new initialization or data migration so that
it can all be done in one transaction. You must first deploy a copy of the new implementation
contract, which is automatically paused by its constructor to help avoid accidental calls directly
to the proxy contract.
