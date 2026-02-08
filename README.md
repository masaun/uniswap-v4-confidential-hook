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

| Contract | Address |
|----------|---------||
| **HonkVerifier** | [`0x786b31a1e67a9745f848dffb6c54a1d8accb8f1c`](https://unichain-sepolia.blockscout.com/address/0x786b31a1e67a9745f848dffb6c54a1d8accb8f1c) |
| **ComplianceProofVerifier** | [`0x1aa877bfb71e7ec24224415a30e1e0345dc1d4c0`](https://unichain-sepolia.blockscout.com/address/0x1aa877bfb71e7ec24224415a30e1e0345dc1d4c0) |
| **PolicyProofVerifier** | [`0x44b3ae18a72a44b17cd762c48f5206ad4f4a17c9`](https://unichain-sepolia.blockscout.com/address/0x44b3ae18a72a44b17cd762c48f5206ad4f4a17c9) |
| **StrategyProofVerifier** | [`0x132db810d64cef15dda378b58069b2b3dadc434b`](https://unichain-sepolia.blockscout.com/address/0x132db810d64cef15dda378b58069b2b3dadc434b) |
| **UniswapV4ConfidentialHook** | [`0xbb058974af8cc8a3606bfe952e234bd8a5e11858`](https://unichain-sepolia.blockscout.com/address/0xbb058974af8cc8a3606bfe952e234bd8a5e11858) |

<br>

## DEMO Video


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

- Uniswap v4
  - [Uniswap v4 docs](https://docs.uniswap.org/contracts/v4/overview)
  - [v4-periphery](https://github.com/uniswap/v4-periphery)
  - [v4-core](https://github.com/uniswap/v4-core)
  - [v4-by-example](https://v4-by-example.org)