# Mock Token Deployment Guide

This guide explains how to deploy and use MockUSDC and MockWETH tokens for testing the Uniswap V4 Confidential Hook on Unichain Sepolia.

## Overview

- **MockUSDC**: ERC20 token with 6 decimals (mimics real USDC)
- **MockWETH**: ERC20 token with 18 decimals (mimics Wrapped Ether)

## Prerequisites

1. `.env` file configured in `contracts/` directory with:
   - `PRIVATE_KEY` - Your wallet private key
   - `UNICHAIN_SEPOLIA_RPC_URL` - Unichain Sepolia RPC URL
   - `UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS` - Your deployed hook address
   - `POOL_MANAGER_ADDRESS` - Pool Manager contract address

## Step-by-Step Deployment

### 1. Deploy MockUSDC

```bash
cd contracts/scripts/deployments/unichain-sepolia
./deploy-mock-usdc.sh
```

**Output**: Copy the deployed MockUSDC address

**Add to `.env`**:
```
MOCK_USDC_ADDRESS=<deployed_address>
```

### 2. Deploy MockWETH

```bash
cd contracts/scripts/deployments/unichain-sepolia
./deploy-mock-weth.sh
```

**Output**: Copy the deployed MockWETH address

**Add to `.env`**:
```
MOCK_WETH_ADDRESS=<deployed_address>
```

### 3. Mint MockUSDC

Mint 1,000,000 USDC to your address:
```bash
cd contracts/scripts/mock-USDC-minter
./mint-mock-usdc.sh
```

Mint to a specific address (e.g., `Your Wallet Address`):
```bash
./mint-mock-usdc.sh 1000000 <Your Wallet Address>
```

### 4. Mint MockWETH

Mint 10,000 WETH to your address:
```bash
cd contracts/scripts/mock-WETH-minter
./mint-mock-weth.sh
```

Mint to a specific address:
```bash
./mint-mock-weth.sh 10000 <Your Wallet address>
```

## Initialize the Pool

After deploying and minting tokens, you need to initialize the Uniswap V4 pool:

```bash
cd contracts
forge script scripts/CreateUSDCETHPool.s.sol:CreateUSDCETHPool \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast
```

**Note**: Make sure your `.env` has the mock token addresses set before initializing the pool.

## Running E2E Tests

Once tokens are deployed, minted, and the pool is initialized:

```bash
cd scripts
bun run e2e
```

The e2e.ts script will:
1. Use `MOCK_USDC_ADDRESS` and `MOCK_WETH_ADDRESS` from environment variables
2. Generate ZK proofs for compliance, policy, and strategy
3. Execute a confidential swap on Uniswap V4 with ZK verification

## Verification

Check your deployed contracts on Blockscout:
- MockUSDC: `https://unichain-sepolia.blockscout.com/address/<MOCK_USDC_ADDRESS>`
- MockWETH: `https://unichain-sepolia.blockscout.com/address/<MOCK_WETH_ADDRESS>`

## Contract Locations

- **MockUSDC Contract**: `contracts/src/mocks/MockUSDC.sol`
- **MockWETH Contract**: `contracts/src/mocks/MockWETH.sol`
- **Deploy Script (USDC)**: `contracts/scripts/deployments/unichain-sepolia/DeployMockUSDC.s.sol`
- **Deploy Script (WETH)**: `contracts/scripts/deployments/unichain-sepolia/DeployMockWETH.s.sol`
- **Mint Script (USDC)**: `contracts/scripts/mock-USDC-minter/MintMockUSDC.s.sol`
- **Mint Script (WETH)**: `contracts/scripts/mock-WETH-minter/MintMockWETH.s.sol`

## Environment Variables Summary

Add these to `contracts/.env`:

```bash
# Mock Tokens
MOCK_USDC_ADDRESS=0x...  # Deployed MockUSDC address
MOCK_WETH_ADDRESS=0x...  # Deployed MockWETH address

# Core Contracts (should already be set)
UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS=0x324fFb32560Ab432930bA2d217B9EB16a9a54880
POOL_MANAGER_ADDRESS=0xC81462Fec8B23319F288047f8A03A57682a35C1A

# Network
UNICHAIN_SEPOLIA_RPC_URL=https://sepolia.unichain.org
PRIVATE_KEY=0x...  # Your wallet private key
```

## Troubleshooting

### Pool doesn't exist
- Run the pool initialization script first (Step 4 above)
- Ensure mock token addresses are set in .env

### Insufficient balance
- Run mint scripts to add tokens to your address
- Check balances on Blockscout

### Swap reverts
- Verify pool is initialized correctly
- Check that you have sufficient token balances
- Ensure tokens are approved for PoolManager

## Alternative: Using Native ETH

If you want to test with native ETH instead of WETH, set in `.env`:
```bash
MOCK_WETH_ADDRESS=0x0000000000000000000000000000000000000000
```

The e2e.ts script will automatically handle native ETH vs ERC20 WETH.
