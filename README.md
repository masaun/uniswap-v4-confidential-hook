# Uniswap v4 Confidential Hook

> ⚠️ **IMPORTANT NOTE**: This project currently requires redeployment of the hook contract with correct Uniswap V4 permission flags. See [HOOK_ADDRESS_FIX.md](HOOK_ADDRESS_FIX.md) for details.

## Overview

Uniswap v4 Confidential Hook is a privacy-preserving hook implementation for Uniswap v4 that leverages `Zero-Knowledge (ZK) Proof` to enable **confidential trading** with `compliance`, `policy`, and `strategy` verification. 

Built with `Noir` **ZK circuits** and Solidity smart contracts, this hook ensures that swap and liquidity operations meet specific criteria **without** `revealing sensitive transaction details on-chain`.

## Key Features

- **ZK-Powered Privacy**: Utilizes Noir circuits to generate and verify zero-knowledge proofs for confidential transactions
- **Triple Verification System**: 
  - **Compliance Verification**: Ensures transactions meet regulatory compliance requirements
  - **Policy Verification**: Validates adherence to custom trading policies
  - **Strategy Verification**: Confirms execution aligns with predefined trading strategies
- **Uniswap v4 Hook Integration**: Seamlessly integrates with Uniswap v4's hook architecture
- **BeforeSwap & BeforeAddLiquidity Hooks**: Validates ZK proofs before allowing swaps and liquidity additions
- **Honk zkProof System**: Leverages Barretenberg's Honk verifier for efficient on-chain proof verification

## Use Case

- **Institutional Trading**: Allows institutions to execute trades while maintaining confidentiality and proving compliance
- **Privacy-Preserving DeFi**: Enables traders to protect their trading strategies while demonstrating adherence to platform policies
- **Regulated Market Access**: Facilitates access to DeFi markets with built-in compliance verification
- **Confidential Liquidity Provision**: Lets liquidity providers add funds while keeping position sizes and strategies private


<br>

## Tech Stack

- **ZK Circuit**: `Noir` (`v1.0.0-beta.18`)
   - ZK Circuit Library: `@aztec/bb.js` (`v3.0.0-devnet.6-patch.1`) & `@noir-lang/noir_js` (`v1.0.0-beta.18`)
   - Incremental Merkle Tree (`IMT`) Library: `@zk-kit/imt` (`v2.0.0-beta.8`) 

- **Smart Contract**: `Solidity`
- **Blockchain**: Arbitrum Sepolia Testnet


<br>

## Architecture & Userflow

```bash
                ┌───────────────────────────┐
Enterprise      │ Private intent + identity │
(Institution)   └────────────┬─────────────-┘
                             ▼
                 ┌──────────────--───-┐
                 │ Noir Circuit(s)    │
                 │                    │
                 │ - Policy Proof     │
                 │ - Strategy Proof   │
                 │ - Compliance Proof │
                 └─────────┬──────────┘
                           │ proof + publicInputs
                           ▼
                  ┌─────────────────────────────────┐
                  │ Uniswap v4 Confidential Hook    │
                  │                                 │
                  │ _beforeSwap()                   │
                  │ _beforeAddLiquidity()           │
                  │    　　　▼                       │
                  │ - verifyComplianceProof()       │
                  │ - verifyPolicyProof()           │
                  │ - verifyStrategyProof()         │
                  └─────────┬───────────────┬───────┘
                            ▼               ▼        
                  ┌──────────────────┐   ┌────────┐
                  │ Pool Liquidity   │   │ Swap   │
                  └──────────────────┘   └────────┘
```

<br>

## Deployed Contract Addresses (on `Unichain Sepolia`)

### Newly deployed-contract addresses (on `Unichain Sepolia`) by this project
| Contract | Address |
|----------|---------|
| **HonkVerifier (of the `Compliance` ZK circuit)** | [`0x786B31a1E67a9745f848DFfb6C54a1d8aCCB8F1c`](https://sepolia.uniscan.xyz/address/0x786B31a1E67a9745f848DFfb6C54a1d8aCCB8F1c) |
| **HonkVerifier (of the `Policy` ZK circuit)** | [`0x44B3ae18A72A44b17CD762C48f5206AD4F4A17C9`](https://sepolia.uniscan.xyz/address/0x44B3ae18A72A44b17CD762C48f5206AD4F4A17C9) |
| **HonkVerifier (of the `Strategy` ZK circuit)** | [`0xBb058974aF8cC8A3606bFE952e234Bd8a5E11858`](https://sepolia.uniscan.xyz/address/0xBb058974aF8cC8A3606bFE952e234Bd8a5E11858) |
| **ComplianceProofVerifier** | [`0x1aA877Bfb71e7eC24224415a30E1E0345Dc1d4C0`](https://sepolia.uniscan.xyz/address/0x1aA877Bfb71e7eC24224415a30E1E0345Dc1d4C0) |
| **PolicyProofVerifier** | [`0x132DB810D64ceF15dDA378b58069B2B3daDC434B`](https://sepolia.uniscan.xyz/address/0x132DB810D64ceF15dDA378b58069B2B3daDC434B) |
| **StrategyProofVerifier** | [`0x98165b549582844227f1CB08375bDf099A991406`](https://sepolia.uniscan.xyz/address/0x98165b549582844227f1CB08375bDf099A991406) |
| **UniswapV4ConfidentialHook** | [`0x05f2ba624e4121Ac8D5416f7a33291A010588880`](https://sepolia.uniscan.xyz/address/0x05f2ba624e4121Ac8D5416f7a33291A010588880) |


### Existing deployed-contract addresses (on `Unichain Sepolia`)
| Contract | Address |
|----------|---------|
| **PoolManager** | [`0xC81462Fec8B23319F288047f8A03A57682a35C1A`](https://sepolia.uniscan.xyz/address/0xC81462Fec8B23319F288047f8A03A57682a35C1A) |
| **USDC** | [`0x31d0220469e10c4e71834a79b1f276d740d3768f`](https://sepolia.uniscan.xyz/address/0x31d0220469e10c4e71834a79b1f276d740d3768f) |
| **WETH** | [`0x4200000000000000000000000000000000000006`](https://sepolia.uniscan.xyz/address/0x4200000000000000000000000000000000000006) |

<br>

## DEMO Video

- DEMO of the `End-To-End` script using ./scripts/`e2e.ts`: https://www.loom.com/share/e0531eb349aa4662a9949e6a37a6d276

<br>

## Installation

## Noir ZK circuit

- Circuit Test
```bash
cd circuits/invoice-refactoring

sh circuit_test.sh
```

<br>

- Circuit Artifacts & Solidity Verifier generation
```bash
cd circuits/invoice-refactoring

sh build.sh
```

<br>

### Smart Contract

1. **Install dependencies**:
```bash
cd contracts
forge install
```

2. **Compile contracts**:
```bash
forge build
```

3. **Run tests**:
```bash
IN PROGRESS
```

4. **Deploy contracts on Unichain Sepolia**:
```bash
cd contracts/scripts/deployments/unichain-sepolia

sh deploy.sh
```

<br>

## Run the e2e script

- Install the node modules with the `bun` CLI
```bash
cd scripts
bun install
```

<br>

- e2e script
```bash
cd scripts
bun run e2e
```

<br>

## References

- ZK circuit in `Noir` (powered by `Aztec`)
  - [Noir Documentation](https://noir-lang.org/)
  - [Barretenberg Documentation](https://aztecprotocol.github.io/barretenberg/)
  - `noir-examples/solidity-example`
    - `js/generate-proof.ts` (How to use the `verifierTarget: "evm"`): https://github.com/noir-lang/noir-examples/blob/master/solidity-example/js/generate-proof.ts#L16

  - Recursive Proof:
    - Doc：https://barretenberg.aztec.network/docs/explainers/recursive_aggregation/
    - `noir-examples/recursion`：https://github.com/noir-lang/noir-examples/tree/master/recursion


<br>

- Uniswap v4 Hook
  - Template: https://github.com/uniswapfoundation/v4-template

- Unichain
  - Fancet: https://docs.unichain.org/docs/tools/faucets
  - `WETH`: You can convert your Narive ETH to the WETH by calling the `deposit()` in the Block Explorer: https://unichain-sepolia.blockscout.com/address/0x4200000000000000000000000000000000000006?tab=read_write_contract
  - `USDC`: https://faucet.circle.com/

- Uniswap v4
  - [Uniswap v4 docs](https://docs.uniswap.org/contracts/v4/overview)
  - [v4-periphery](https://github.com/uniswap/v4-periphery)
  - [v4-core](https://github.com/uniswap/v4-core)
  - [v4-by-example](https://v4-by-example.org)