// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";

// Import the Compliance HonkVerifier and ProofVerifier
import {HonkVerifier as ComplianceHonk} from "../../../src/circuits/honk-verifier/compliance/HonkVerifier.sol";
import {ComplianceProofVerifier} from "../../../src/circuits/ComplianceProofVerifier.sol";

// Import the Policy HonkVerifier and ProofVerifier  
import {HonkVerifier as PolicyHonk} from "../../../src/circuits/honk-verifier/policy/HonkVerifier.sol";
import {PolicyProofVerifier} from "../../../src/circuits/PolicyProofVerifier.sol";

// Import the Strategy HonkVerifier and ProofVerifier
import {HonkVerifier as StrategyHonk} from "../../../src/circuits/honk-verifier/strategy/HonkVerifier.sol";
import {StrategysProofVerifier} from "../../../src/circuits/StrategyProofVerifier.sol";

// Import the UniswapV4ConfidentialHook contract
import {UniswapV4ConfidentialHook} from "../../../src/UniswapV4ConfidentialHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

contract DeployScript is Script {

    function run() external {
        // Get the deployer's private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying to Unichain Sepolia");
        console.log("Deployer:", msg.sender);
        console.log("========================================");
        console.log("");

        // Step 1: Deploy Compliance HonkVerifier
        console.log("Step 1: Deploying Compliance HonkVerifier...");
        ComplianceHonk complianceHonkVerifier = new ComplianceHonk();
        console.log("Compliance HonkVerifier deployed at:", address(complianceHonkVerifier));
        console.log("");

        // Step 2: Deploy ComplianceProofVerifier
        console.log("Step 2: Deploying ComplianceProofVerifier...");
        ComplianceProofVerifier complianceProofVerifier = new ComplianceProofVerifier(address(complianceHonkVerifier));
        console.log("ComplianceProofVerifier deployed at:", address(complianceProofVerifier));
        console.log("");

        // Step 3: Deploy Policy HonkVerifier
        console.log("Step 3: Deploying Policy HonkVerifier...");
        PolicyHonk policyHonkVerifier = new PolicyHonk();
        console.log("Policy HonkVerifier deployed at:", address(policyHonkVerifier));
        console.log("");

        // Step 4: Deploy PolicyProofVerifier
        console.log("Step 4: Deploying PolicyProofVerifier...");
        PolicyProofVerifier policyProofVerifier = new PolicyProofVerifier(address(policyHonkVerifier));
        console.log("PolicyProofVerifier deployed at:", address(policyProofVerifier));
        console.log("");

        // Step 5: Deploy Strategy HonkVerifier
        console.log("Step 5: Deploying Strategy HonkVerifier...");
        StrategyHonk strategyHonkVerifier = new StrategyHonk();
        console.log("Strategy HonkVerifier deployed at:", address(strategyHonkVerifier));
        console.log("");

        // Step 6: Deploy StrategyProofVerifier
        console.log("Step 6: Deploying StrategyProofVerifier...");
        StrategysProofVerifier strategyProofVerifier = new StrategysProofVerifier(address(strategyHonkVerifier));
        console.log("StrategyProofVerifier deployed at:", address(strategyProofVerifier));
        console.log("");

        // Step 7: Deploy UniswapV4ConfidentialHook using CREATE2 with salt mining
        console.log("Step 7: Deploying UniswapV4ConfidentialHook...");
        console.log("Mining for valid hook address (this may take a moment)...");
        
        IPoolManager poolManager = IPoolManager(vm.envAddress("POOL_MANAGER_ADDRESS"));
        
        // Get the hook permissions flags
        uint160 flags = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG
        );
        
        // Mine for a salt that will produce a valid hook address
        bytes32 salt = 0;
        address hookAddress;
        bytes memory creationCode = abi.encodePacked(
            type(UniswapV4ConfidentialHook).creationCode,
            abi.encode(poolManager, complianceProofVerifier, policyProofVerifier, strategyProofVerifier)
        );
        
        // Try different salts until we find a valid hook address
        for (uint256 i = 0; i < 100000; i++) {
            salt = bytes32(i);
            hookAddress = vm.computeCreate2Address(salt, keccak256(creationCode));
            
            // Check if the address matches the required flags
            if (uint160(hookAddress) & 0xFFF == flags) {
                console.log("Found valid salt:", uint256(salt));
                break;
            }
        }
        
        require(uint160(hookAddress) & 0xFFF == flags, "Could not find valid hook address");
        
        // Deploy with the found salt
        UniswapV4ConfidentialHook hook;
        assembly {
            hook := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        require(address(hook) != address(0), "Hook deployment failed");
        
        console.log("UniswapV4ConfidentialHook deployed at:", address(hook));
        console.log("");

        vm.stopBroadcast();

        // Print deployment summary
        console.log("========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("Compliance HonkVerifier:", address(complianceHonkVerifier));
        console.log("ComplianceProofVerifier:", address(complianceProofVerifier));
        console.log("Policy HonkVerifier:", address(policyHonkVerifier));
        console.log("PolicyProofVerifier:", address(policyProofVerifier));
        console.log("Strategy HonkVerifier:", address(strategyHonkVerifier));
        console.log("StrategyProofVerifier:", address(strategyProofVerifier));
        console.log("UniswapV4ConfidentialHook:", address(hook));
        console.log("========================================");
        console.log("");
        console.log("Please add these addresses to your .env file:");
        console.log("COMPLIANCE_PROOF_VERIFIER_ADDRESS=", address(complianceProofVerifier));
        console.log("POLICY_PROOF_VERIFIER_ADDRESS=", address(policyProofVerifier));
        console.log("STRATEGY_PROOF_VERIFIER_ADDRESS=", address(strategyProofVerifier));
    }
}


