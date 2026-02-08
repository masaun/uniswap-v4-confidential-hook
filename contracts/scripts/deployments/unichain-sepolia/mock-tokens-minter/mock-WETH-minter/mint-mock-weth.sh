#!/bin/bash

# Mint MockWETH tokens on Unichain Sepolia
# Usage: ./mint-mock-weth.sh [amount_in_weth] [recipient_address]
#   Example: ./mint-mock-weth.sh 10000  (mints 10,000 WETH to your address)
#   Example: ./mint-mock-weth.sh 10000 <Your wallet address> (mints to specific address)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get the contracts root directory (2 levels up from this script)
CONTRACTS_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Check .env
if [ ! -f "$CONTRACTS_ROOT/.env" ]; then
    echo -e "${RED}Error: .env file not found at $CONTRACTS_ROOT/.env${NC}"
    echo "Please create a .env file with MOCK_WETH_ADDRESS set"
    exit 1
fi

source "$CONTRACTS_ROOT/.env"

# Validate environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

if [ -z "$UNICHAIN_SEPOLIA_RPC_URL" ]; then
    echo -e "${RED}Error: UNICHAIN_SEPOLIA_RPC_URL not set in .env${NC}"
    exit 1
fi

if [ -z "$MOCK_WETH_ADDRESS" ] || [ "$MOCK_WETH_ADDRESS" = "0x0000000000000000000000000000000000000000" ]; then
    echo -e "${RED}Error: MOCK_WETH_ADDRESS not set in .env${NC}"
    echo "Please deploy MockWETH first using ./deploy-mock-weth.sh"
    exit 1
fi

# Parse amount argument (optional)
if [ -n "$1" ]; then
    # Convert to amount with 18 decimals
    MINT_AMOUNT=$(echo "$1 * 10^18" | bc)
    export MINT_AMOUNT
    echo -e "${YELLOW}Custom mint amount: $1 WETH${NC}"
else
    echo -e "${YELLOW}Using default mint amount: 10,000 WETH${NC}"
fi

# Parse recipient address argument (optional)
if [ -n "$2" ]; then
    export MINT_RECIPIENT="$2"
    echo -e "${YELLOW}Custom recipient: $2${NC}"
fi

# Change to contracts root for forge commands
cd "$CONTRACTS_ROOT"

echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}Minting MockWETH on Unichain Sepolia${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo -e "${YELLOW}MockWETH Address: $MOCK_WETH_ADDRESS${NC}"
echo "Amount: $MINT_AMOUNT (with decimals)"
echo "Recipient: ${MINT_RECIPIENT:-Deployer}"
echo ""

forge script scripts/mock-WETH-minter/MintMockWETH.s.sol:MintMockWETH \
  --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
  --broadcast

echo ""
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}Minting Complete!${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo "Check your balance on Blockscout:"
echo "https://unichain-sepolia.blockscout.com/token/$MOCK_WETH_ADDRESS"
