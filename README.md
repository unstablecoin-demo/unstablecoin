# Unstablecoin Repository

## Overview

The Unstablecoin repository is part of the **Chocolate Coin Family**, an educational initiative designed to showcase stablecoin mechanics through different implementations.

This specific repository focuses on the **unstable** version of CHOCUSD, a project that demonstrates the inherent risks and potential vulnerabilities in some fiat-based stablecoin systems.

## The Chocolate Coin Family

The family consists of two distinct versions for learning and comparison:

**1. Unstable CHOCUSD (This Repository)**
A flawed implementation deployed on the **Sepolia Testnet** to serve as an educational tool for identifying potential risks.

**2. Stable CHOCUSD (BSC Mainnet)**
A fully functional, non-flawed stablecoin deployed on the **BSC Mainnet** that serves as a proper, stable example. The contract addresses are:
- **CHOCUSD Proxy:** [`0x1bc0294f8a4eb5158a92e3604ff0b8b8bb52c7c9`](https://bscscan.com/address/0x1bc0294f8a4eb5158a92e3604ff0b8b8bb52c7c9#readProxyContract)
- **CHOCUSD Implementation:** [`0x0483aee4a2986a084f497e3f9112a68504137d0f`](https://bscscan.com/address/0x0483aee4a2986a084f497e3f9112a68504137d0f#code)
- **SupplyController Proxy:** [`0xc651c4fa67c2923465cd5e7b92324c43917e1ebb`](https://bscscan.com/address/0xc651c4fa67c2923465cd5e7b92324c43917e1ebb)
- **SupplyController Implementation:** [`0xac18d27a9b7a86b13440ba8016d227e5b1e2db58`](https://bscscan.com/address/0xac18d27a9b7a86b13440ba8016d227e5b1e2db58)
 
## Directories

### `/docs`
Contains site deployed using github pages covering key details on our unstablecoin
- Circulating supply & Reserves
- FAQ on general details on the project
- Learn more section with links to Github, Whitepaper & Redemption Policy

Currently viewable at https://unstablecoin-demo.github.io/unstablecoin/

### `/public`
Contains documentation and resources for public dissemination:
- Overview and intentions of the Unstablecoin project.
- Legal disclaimer and usage warnings.
- Links to testnet deployments of Unstablecoin contracts.
- Descriptions of the ERC20 token contract, roles, and their functions.

## Usage

Navigate to each directory and refer to the respective `README.md` for detailed instructions on the contents and how to use them.

## Note

The `public` directory intentionally omits risk-related details for the purpose of demostration of potential vulnerabilities.
