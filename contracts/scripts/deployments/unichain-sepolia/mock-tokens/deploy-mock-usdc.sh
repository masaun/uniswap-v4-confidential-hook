#!/bin/bash

# Deploy and verify MockUSDC on Unichain Sepolia
# Usage: ./deploy-mock-usdc.sh [--verify-only] [mock_usdc_address]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
VERIFY_ONLY=false
if [ "$1" = "--verify-only" ]; then
    VERIFY_ONLY=true
    shift
fi

MOCK_USDC_ADDRESS=$1

# Get the contracts root directory (3 levels up from this script)
CONTRACTS_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Check .env
if [ ! -f "$CONTRACTS_ROOT/.env" ]; then
    echo -e "${RED}Error: .env file not found at $CONTRACTS_ROOT/.env${NC}"
    echo "Please create a .env file based on .env.example in the contracts directory"
    exit 1
fi

source "$CONTRACTS_ROOT/.env"

# Change to contracts root for forge commands
cd "$CONTRACTS_ROOT"

if [ "$VERIFY_ONLY" = true ]; then
    # ============================================
    # VERIFICATION ONLY MODE
    # ============================================
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}Verifying MockUSDC on Unichain Sepolia${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""

    # Validate
    if [ -z "$BLOCKSCOUT_API_KEY" ]; then
        echo -e "${YELLOW}Warning: BLOCKSCOUT_API_KEY not set in .env${NC}"
        echo "Skipping verification..."
        exit 0
    fi

    # Get address from argument, env, or user input
    if [ -z "$MOCK_USDC_ADDRESS" ]; then
        # No argument provided, try to use env variable
        if [ -n "$MOCK_USDC_ADDRESS" ] && [ "$MOCK_USDC_ADDRESS" != "0x0000000000000000000000000000000000000000" ]; then
            MOCK_USDC_ADDRESS="$MOCK_USDC_ADDRESS"
        else
            # Prompt user for address
            echo -e "${YELLOW}Enter MockUSDC contract address:${NC}"
            read MOCK_USDC_ADDRESS
        fi
    fi

    echo ""
    echo -e "${YELLOW}Verifying MockUSDC at $MOCK_USDC_ADDRESS...${NC}"
    forge verify-contract \
      --rpc-url unichain_sepolia \
      --verifier blockscout \
      --verifier-url https://unichain-sepolia.blockscout.com/api/ \
      "$MOCK_USDC_ADDRESS" \
      src/mocks/MockUSDC.sol:MockUSDC \
      || echo -e "${YELLOW}MockUSDC verification failed or already verified${NC}"

    echo ""
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}Verification Complete!${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""
    echo "Check contract on Blockscout:"
    echo "https://unichain-sepolia.blockscout.com/address/$MOCK_USDC_ADDRESS"

else
    # ============================================
    # DEPLOYMENT MODE
    # ============================================
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}Deploying MockUSDC to Unichain Sepolia${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""

    # Validate
    if [ -z "$PRIVATE_KEY" ]; then
        echo -e "${RED}Error: PRIVATE_KEY not set${NC}"
        exit 1
    fi

    if [ -z "$UNICHAIN_SEPOLIA_RPC_URL" ]; then
        echo -e "${RED}Error: UNICHAIN_SEPOLIA_RPC_URL not set${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Building contracts...${NC}"
    forge build

    echo ""
    echo -e "${YELLOW}Deploying MockUSDC...${NC}"

    forge script scripts/deployments/unichain-sepolia/DeployMockUSDC.s.sol:DeployMockUSDC \
      --rpc-url unichain_sepolia \
      --broadcast

    echo ""
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}MockUSDC Deployment Complete!${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Copy the MockUSDC address from the output above"
    echo "2. Add to .env: MOCK_USDC_ADDRESS=<address>"
    echo "3. Run mint script to mint tokens"
fi
