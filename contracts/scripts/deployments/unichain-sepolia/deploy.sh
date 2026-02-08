#!/bin/bash

# Deploy and verify contracts on Unichain Sepolia
# Usage: ./deploy.sh [--verify-only] [compliance_verifier] [policy_verifier] [strategy_verifier] [hook_address]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
VERIFY_ONLY=false
if [ "$1" = "--verify-only" ]; then
    VERIFY_ONLY=true
    shift
fi

COMPLIANCE_PROOF_VERIFIER_ADDRESS=$1
POLICY_PROOF_VERIFIER_ADDRESS=$2
STRATEGY_PROOF_VERIFIER_ADDRESS=$3
UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS=$4

# Get the contracts root directory (3 levels up from this script)
CONTRACTS_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Check if .env file exists
if [ ! -f "$CONTRACTS_ROOT/.env" ]; then
    echo -e "${RED}Error: .env file not found at $CONTRACTS_ROOT/.env${NC}"
    echo "Please create a .env file based on .env.example in the contracts directory"
    exit 1
fi

# Load environment variables
source "$CONTRACTS_ROOT/.env"

# Change to contracts root for forge commands
cd "$CONTRACTS_ROOT"

if [ "$VERIFY_ONLY" = true ]; then
    # ============================================
    # VERIFICATION ONLY MODE
    # ============================================
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}Verifying Contracts on Unichain Sepolia${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""

    # Validate
    if [ -z "$UNISCAN_API_KEY" ]; then
        echo -e "${RED}Error: UNISCAN_API_KEY not set in .env${NC}"
        echo "Get your API key from: https://sepolia.uniscan.xyz/"
        exit 1
    fi

    if [ -z "$UNICHAIN_SEPOLIA_RPC_URL" ]; then
        echo -e "${RED}Error: UNICHAIN_SEPOLIA_RPC_URL not set in .env${NC}"
        exit 1
    fi

    if [ -z "$POOL_MANAGER_ADDRESS" ]; then
        echo -e "${RED}Error: POOL_MANAGER_ADDRESS not set in .env${NC}"
        exit 1
    fi

    # Get addresses interactively if not provided
    if [ -z "$COMPLIANCE_PROOF_VERIFIER_ADDRESS" ]; then
        echo -e "${YELLOW}Enter ComplianceProofVerifier contract address:${NC}"
        read COMPLIANCE_PROOF_VERIFIER_ADDRESS
    fi

    if [ -z "$POLICY_PROOF_VERIFIER_ADDRESS" ]; then
        echo -e "${YELLOW}Enter PolicyProofVerifier contract address:${NC}"
        read POLICY_PROOF_VERIFIER_ADDRESS
    fi

    if [ -z "$STRATEGY_PROOF_VERIFIER_ADDRESS" ]; then
        echo -e "${YELLOW}Enter StrategyProofVerifier contract address:${NC}"
        read STRATEGY_PROOF_VERIFIER_ADDRESS
    fi

    # echo ""
    # echo -e "${YELLOW}Verifying ComplianceProofVerifier at $COMPLIANCE_PROOF_VERIFIER_ADDRESS...${NC}"
    # forge verify-contract \
    #   --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
    #   --etherscan-api-key "$UNISCAN_API_KEY" \
    #   --verifier-url https://api-sepolia.uniscan.xyz/api/v2 \
    #   "$COMPLIANCE_PROOF_VERIFIER_ADDRESS" \
    #   src/circuits/ComplianceProofVerifier.sol:ComplianceProofVerifier \
    #   || echo -e "${YELLOW}ComplianceProofVerifier verification failed or already verified${NC}"

    # echo ""
    # echo -e "${YELLOW}Verifying PolicyProofVerifier at $POLICY_PROOF_VERIFIER_ADDRESS...${NC}"
    # forge verify-contract \
    #   --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
    #   --etherscan-api-key "$UNISCAN_API_KEY" \
    #   --verifier-url https://api-sepolia.uniscan.xyz/api/v2 \
    #   "$POLICY_PROOF_VERIFIER_ADDRESS" \
    #   src/circuits/PolicyProofVerifier.sol:PolicyProofVerifier \
    #   || echo -e "${YELLOW}PolicyProofVerifier verification failed or already verified${NC}"

    # echo ""
    # echo -e "${YELLOW}Verifying StrategyProofVerifier at $STRATEGY_PROOF_VERIFIER_ADDRESS...${NC}"
    # forge verify-contract \
    #   --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
    #   --etherscan-api-key "$UNISCAN_API_KEY" \
    #   --verifier-url https://api-sepolia.uniscan.xyz/api/v2 \
    #   "$STRATEGY_PROOF_VERIFIER_ADDRESS" \
    #   src/circuits/StrategyProofVerifier.sol:StrategyProofVerifier \
    #   || echo -e "${YELLOW}StrategyProofVerifier verification failed or already verified${NC}"

    # echo ""
    # echo -e "${GREEN}====================================${NC}"
    # echo -e "${GREEN}Verification Process Complete!${NC}"
    # echo -e "${GREEN}====================================${NC}"
    # echo ""
    # echo "Check contracts on Uniscan:"
    # echo "ComplianceProofVerifier: https://sepolia.uniscan.xyz/address/$COMPLIANCE_PROOF_VERIFIER_ADDRESS"
    # echo "PolicyProofVerifier: https://sepolia.uniscan.xyz/address/$POLICY_PROOF_VERIFIER_ADDRESS"
    # echo "StrategyProofVerifier: https://sepolia.uniscan.xyz/address/$STRATEGY_PROOF_VERIFIER_ADDRESS"

else
    # ============================================
    # DEPLOYMENT MODE
    # ============================================
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}Deploying to Unichain Sepolia${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""

    # Validate required variables
    if [ -z "$PRIVATE_KEY" ]; then
        echo -e "${RED}Error: PRIVATE_KEY not set in .env${NC}"
        exit 1
    fi

    if [ -z "$UNICHAIN_SEPOLIA_RPC_URL" ]; then
        echo -e "${RED}Error: UNICHAIN_SEPOLIA_RPC_URL not set in .env${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Building deployment script...${NC}"
    forge build scripts/deployments/unichain-sepolia/Deploy.s.sol --skip test

    echo ""
    echo -e "${YELLOW}Deploying contracts using forge script...${NC}"
    echo ""

    # Deploy with or without verification
    # if [ -n "$UNISCAN_API_KEY" ]; then
    #     echo "Deployment with verification enabled"
    #     forge script scripts/deployments/unichain-sepolia/Deploy.s.sol:DeployScript \
    #       --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
    #       --broadcast \
    #       --verify \
    #       --etherscan-api-key "$UNISCAN_API_KEY" \
    #       --verifier-url https://api-sepolia.uniscan.xyz/api/v2 \
    #       -vvvv
    # else
    #     echo "Deployment without verification (no UNISCAN_API_KEY)"
    #     forge script scripts/deployments/unichain-sepolia/Deploy.s.sol:DeployScript \
    #       --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
    #       --broadcast \
    #       -vvvv
    # fi
    
    # Temporarily disabled verification - deploy only
    echo "Deployment without verification"
    forge script scripts/deployments/unichain-sepolia/Deploy.s.sol:DeployScript \
      --rpc-url "$UNICHAIN_SEPOLIA_RPC_URL" \
      --broadcast \
      -vvvv

    echo ""
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""
    
    # Extract deployed contract addresses from broadcast JSON
    BROADCAST_FILE="$CONTRACTS_ROOT/broadcast/Deploy.s.sol/1301/run-latest.json"
    
    if [ -f "$BROADCAST_FILE" ]; then
        echo -e "${YELLOW}Extracting deployed contract addresses...${NC}"
        
        # Parse the JSON to get deployed contract addresses
        # The contracts are deployed in order: ComplianceHonk, ComplianceProof, PolicyHonk, PolicyProof, StrategyHonk, StrategyProof, Hook
        DEPLOYED_ADDRESSES=($(cat "$BROADCAST_FILE" | grep -o '"contractAddress":"0x[a-fA-F0-9]*"' | sed 's/"contractAddress":"//g' | sed 's/"//g'))
        
        if [ ${#DEPLOYED_ADDRESSES[@]} -ge 7 ]; then
            COMPLIANCE_HONK_VERIFIER_ADDRESS="${DEPLOYED_ADDRESSES[0]}"
            COMPLIANCE_PROOF_VERIFIER_ADDRESS="${DEPLOYED_ADDRESSES[1]}"
            POLICY_HONK_VERIFIER_ADDRESS="${DEPLOYED_ADDRESSES[2]}"
            POLICY_PROOF_VERIFIER_ADDRESS="${DEPLOYED_ADDRESSES[3]}"
            STRATEGY_HONK_VERIFIER_ADDRESS="${DEPLOYED_ADDRESSES[4]}"
            STRATEGY_PROOF_VERIFIER_ADDRESS="${DEPLOYED_ADDRESSES[5]}"
            UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS="${DEPLOYED_ADDRESSES[6]}"
            
            echo ""
            echo "Deployed Contract Addresses:"
            echo "============================="
            echo "Compliance HonkVerifier: $COMPLIANCE_HONK_VERIFIER_ADDRESS"
            echo "ComplianceProofVerifier: $COMPLIANCE_PROOF_VERIFIER_ADDRESS"
            echo "Policy HonkVerifier: $POLICY_HONK_VERIFIER_ADDRESS"
            echo "PolicyProofVerifier: $POLICY_PROOF_VERIFIER_ADDRESS"
            echo "Strategy HonkVerifier: $STRATEGY_HONK_VERIFIER_ADDRESS"
            echo "StrategyProofVerifier: $STRATEGY_PROOF_VERIFIER_ADDRESS"
            echo "UniswapV4ConfidentialHook: $UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS"
            echo ""
            
            # Update .env file with deployed addresses
            echo -e "${YELLOW}Updating .env file with deployed addresses...${NC}"
            
            # Update HonkVerifier addresses
            if grep -q "COMPLIANCE_HONK_VERIFIER_ADDRESS=" "$CONTRACTS_ROOT/.env"; then
                sed -i.bak "s|COMPLIANCE_HONK_VERIFIER_ADDRESS=.*|COMPLIANCE_HONK_VERIFIER_ADDRESS=\"$COMPLIANCE_HONK_VERIFIER_ADDRESS\"|g" "$CONTRACTS_ROOT/.env"
            else
                echo "COMPLIANCE_HONK_VERIFIER_ADDRESS=\"$COMPLIANCE_HONK_VERIFIER_ADDRESS\"" >> "$CONTRACTS_ROOT/.env"
            fi
            
            if grep -q "POLICY_HONK_VERIFIER_ADDRESS=" "$CONTRACTS_ROOT/.env"; then
                sed -i.bak "s|POLICY_HONK_VERIFIER_ADDRESS=.*|POLICY_HONK_VERIFIER_ADDRESS=\"$POLICY_HONK_VERIFIER_ADDRESS\"|g" "$CONTRACTS_ROOT/.env"
            else
                echo "POLICY_HONK_VERIFIER_ADDRESS=\"$POLICY_HONK_VERIFIER_ADDRESS\"" >> "$CONTRACTS_ROOT/.env"
            fi
            
            if grep -q "STRATEGY_HONK_VERIFIER_ADDRESS=" "$CONTRACTS_ROOT/.env"; then
                sed -i.bak "s|STRATEGY_HONK_VERIFIER_ADDRESS=.*|STRATEGY_HONK_VERIFIER_ADDRESS=\"$STRATEGY_HONK_VERIFIER_ADDRESS\"|g" "$CONTRACTS_ROOT/.env"
            else
                echo "STRATEGY_HONK_VERIFIER_ADDRESS=\"$STRATEGY_HONK_VERIFIER_ADDRESS\"" >> "$CONTRACTS_ROOT/.env"
            fi
            
            # Update ProofVerifier addresses
            if grep -q "COMPLIANCE_PROOF_VERIFIER_ADDRESS=" "$CONTRACTS_ROOT/.env"; then
                sed -i.bak "s|COMPLIANCE_PROOF_VERIFIER_ADDRESS=.*|COMPLIANCE_PROOF_VERIFIER_ADDRESS=\"$COMPLIANCE_PROOF_VERIFIER_ADDRESS\"|g" "$CONTRACTS_ROOT/.env"
            else
                echo "COMPLIANCE_PROOF_VERIFIER_ADDRESS=\"$COMPLIANCE_PROOF_VERIFIER_ADDRESS\"" >> "$CONTRACTS_ROOT/.env"
            fi
            
            if grep -q "POLICY_PROOF_VERIFIER_ADDRESS=" "$CONTRACTS_ROOT/.env"; then
                sed -i.bak "s|POLICY_PROOF_VERIFIER_ADDRESS=.*|POLICY_PROOF_VERIFIER_ADDRESS=\"$POLICY_PROOF_VERIFIER_ADDRESS\"|g" "$CONTRACTS_ROOT/.env"
            else
                echo "POLICY_PROOF_VERIFIER_ADDRESS=\"$POLICY_PROOF_VERIFIER_ADDRESS\"" >> "$CONTRACTS_ROOT/.env"
            fi
            
            if grep -q "STRATEGY_PROOF_VERIFIER_ADDRESS=" "$CONTRACTS_ROOT/.env"; then
                sed -i.bak "s|STRATEGY_PROOF_VERIFIER_ADDRESS=.*|STRATEGY_PROOF_VERIFIER_ADDRESS=\"$STRATEGY_PROOF_VERIFIER_ADDRESS\"|g" "$CONTRACTS_ROOT/.env"
            else
                echo "STRATEGY_PROOF_VERIFIER_ADDRESS=\"$STRATEGY_PROOF_VERIFIER_ADDRESS\"" >> "$CONTRACTS_ROOT/.env"
            fi
            
            # Update Hook contract address
            if grep -q "UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS=" "$CONTRACTS_ROOT/.env"; then
                sed -i.bak "s|UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS=.*|UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS=\"$UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS\"|g" "$CONTRACTS_ROOT/.env"
            else
                echo "UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS=\"$UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS\"" >> "$CONTRACTS_ROOT/.env"
            fi
            
            # Remove backup file
            rm -f "$CONTRACTS_ROOT/.env.bak"
            
            echo -e "${GREEN}✓ Updated .env file with deployed contract addresses${NC}"
            echo ""
        else
            echo -e "${YELLOW}Warning: Could not extract all contract addresses from broadcast file${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: Broadcast file not found at $BROADCAST_FILE${NC}"
        echo "Check the output above for deployed contract addresses"
    fi
    
    echo "The full deployment details are saved in broadcast/Deploy.s.sol/1301/run-latest.json"
    echo ""
    echo "View on Uniscan: https://sepolia.uniscan.xyz/"
    
    if [ -z "$UNISCAN_API_KEY" ]; then
        echo ""
        echo -e "${YELLOW}Tip: To verify contracts manually, run:${NC}"
        echo "./deploy.sh --verify-only <compliance_verifier> <policy_verifier> <strategy_verifier>"
    fi
fi
