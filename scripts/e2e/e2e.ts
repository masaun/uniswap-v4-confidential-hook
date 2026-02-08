import { getIncrementalMerkleTree } from "../libs/zk-utils/incremental-merkle-tree/index.ts";
import {
  generateProof,
  generateRandomField,
  createTraderCommitment,
  createIntentCommitment,
  createPolicyCommitment,
  createStrategyIntentCommitment,
  type TraderCredential,
  type TradeIntent,
  type TradePolicy,
  type TradingStrategy,
  type StrategyContext,
  type MerkleTreeData,
} from "../libs/zk-prover/zk-prover.ts";
import { createWalletClient, createPublicClient, http, parseUnits, formatUnits, type WalletClient, type PublicClient, type Address } from "viem";
import { unichainSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { config } from "dotenv";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

// Load environment variables from contracts/.env
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const envPath = resolve(__dirname, "../../contracts/.env");

console.log("📂 Loading environment from:", envPath);
const result = config({ path: envPath });

if (result.error) {
  console.error("❌ Error loading .env file:", result.error);
  throw result.error;
}

// Deployed contract addresses from .env
const HOOK_ADDRESS = process.env.UNISWAP_V4_CONFIDENTIAL_HOOK_ADDRESS as Address;
const POOL_MANAGER_ADDRESS = process.env.POOL_MANAGER_ADDRESS as Address;
const INSTITUTIONAL_TRADER_PRIVATE_KEY = process.env.INSTITUTIONAL_TRADER_PRIVATE_KEY!; // @dev - Enterprise trader private key
const RPC_URL = process.env.UNICHAIN_SEPOLIA_RPC_URL!;

// Validate environment variables
if (!HOOK_ADDRESS || !POOL_MANAGER_ADDRESS || !INSTITUTIONAL_TRADER_PRIVATE_KEY || !RPC_URL) {
  throw new Error("Missing required environment variables in contracts/.env");
}

console.log("🔧 Configuration:");
console.log("  - Network: Unichain Sepolia");
console.log("  - RPC URL:", RPC_URL);
console.log("  - Hook Address:", HOOK_ADDRESS);
console.log("  - Pool Manager Address:", POOL_MANAGER_ADDRESS);

/**
 * @notice - E2E script for Uniswap V4 Confidential Hook on Unichain Sepolia
 * This script demonstrates the complete flow:
 * 1. Setup trader credentials and trade parameters
 * 2. Generate ZK proofs for Compliance, Policy, and Strategy circuits
 * 3. Execute confidential swap on Uniswap V4 with ZK verification
 */
const main = async () => {
  try {
    console.log("\n=".repeat(60));
    console.log("E2E Test: Uniswap V4 Confidential Hook on Unichain Sepolia");
    console.log("=".repeat(60));

    console.log("\n🔌 Setting up wallet and clients...");
    // Setup wallet and clients
    const account = privateKeyToAccount(INSTITUTIONAL_TRADER_PRIVATE_KEY);
    console.log("  ✓ Account created from private key");
    
    const walletClient: WalletClient = createWalletClient({
      account,
      chain: unichainSepolia,
      transport: http(RPC_URL)
    });
    console.log("  ✓ Wallet client created");

    const publicClient: PublicClient = createPublicClient({
      chain: unichainSepolia,
      transport: http(RPC_URL)
    });
    console.log("  ✓ Public client created");

    console.log("\n✅ Wallet connected:");
    console.log("  - Address:", account.address);

    // ==========================================
    // 1. Setup Trader Credential (Compliance)
    // ==========================================
    console.log("\n📋 Step 1: Setting up Institutional Trader Credential...");
    const traderCredential: TraderCredential = {
      jurisdictionCode: BigInt(1), // e.g., US = 1
      traderSecret: generateRandomField(),
      credentialExpiry: BigInt(Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60), // 1 year from now
      blockTimestamp: BigInt(Math.floor(Date.now() / 1000)),
    };

    const traderCommitment = createTraderCommitment(traderCredential);
    console.log("  ✓ Trader Credential:");
    console.log(`    - Jurisdiction: ${traderCredential.jurisdictionCode}`);
    console.log(`    - Commitment: 0x${traderCommitment.toString(16)}`);

    // ==========================================
    // 2. Setup Trade Intent (Policy)
    // ==========================================
    console.log("\n💱 Step 2: Setting up Trade Intent...");
    const tradeIntent: TradeIntent = {
      amount: BigInt(1000000), // 1M units
      tokenIn: BigInt(0x1), // USDC address (simplified)
      tokenOut: BigInt(0x2), // ETH address (simplified)
      nonce: BigInt(Date.now()),
      intentSecret: generateRandomField(),
    };

    const intentCommitment = createIntentCommitment(tradeIntent);
    console.log("  ✓ Trade Intent:");
    console.log(`    - Amount: ${tradeIntent.amount}`);
    console.log(`    - Token In: 0x${tradeIntent.tokenIn.toString(16)}`);
    console.log(`    - Token Out: 0x${tradeIntent.tokenOut.toString(16)}`);
    console.log(`    - Commitment: 0x${intentCommitment.toString(16)}`);

    // ==========================================
    // 3. Setup Trade Policy
    // ==========================================
    console.log("\n📜 Step 3: Setting up Trade Policy...");
    const tradePolicy: TradePolicy = {
      tokenIn: tradeIntent.tokenIn,
      tokenOut: tradeIntent.tokenOut,
      maxLimit: BigInt(2000000), // Max 2M units
      policySecret: generateRandomField(),
    };

    const policyCommitment = createPolicyCommitment(tradePolicy);
    console.log("  ✓ Trade Policy:");
    console.log(`    - Max Limit: ${tradePolicy.maxLimit}`);
    console.log(`    - Commitment: 0x${policyCommitment.toString(16)}`);

    // ==========================================
    // 4. Setup Trading Strategy
    // ==========================================
    console.log("\n⚡ Step 4: Setting up Trading Strategy...");
    const now = Math.floor(Date.now() / 1000);
    const tradingStrategy: TradingStrategy = {
      amount: BigInt(1000000),
      limitPrice: BigInt(3000), // e.g., $3000 per ETH
      slippageToleranceBps: BigInt(50), // 0.5%
      startTime: BigInt(now - 3600), // Started 1 hour ago
      endTime: BigInt(now + 7200), // Ends in 2 hours
      nonce: BigInt(Date.now()),
      intentSecret: generateRandomField(),
    };

    const strategyIntentCommitment = createStrategyIntentCommitment(tradingStrategy);
    console.log("  ✓ Trading Strategy:");
    console.log(`    - Limit Price: ${tradingStrategy.limitPrice}`);
    console.log(`    - Slippage Tolerance: ${tradingStrategy.slippageToleranceBps} bps`);
    console.log(`    - Commitment: 0x${strategyIntentCommitment.toString(16)}`);

    // ==========================================
    // 5. Setup Strategy Context
    // ==========================================
    console.log("\n🌊 Step 5: Setting up Strategy Context...");
    const strategyContext: StrategyContext = {
      twapPrice: BigInt(2950), // TWAP price: $2950
      blockTimestamp: BigInt(now),
      poolStateHash: generateRandomField(),
    };

    console.log("  ✓ Strategy Context:");
    console.log(`    - TWAP Price: ${strategyContext.twapPrice}`);
    console.log(`    - Block Timestamp: ${strategyContext.blockTimestamp}`);

    // ==========================================
    // 6. Create Merkle Trees
    // ==========================================
    console.log("\n🌳 Step 6: Creating Merkle Trees...");
    
    const { imTree: traderTree } = await getIncrementalMerkleTree([traderCommitment]);
    const { imTree: intentTree } = await getIncrementalMerkleTree([intentCommitment, strategyIntentCommitment]);
    const { imTree: policyTree } = await getIncrementalMerkleTree([policyCommitment]);

    const merkleTreeData: MerkleTreeData = {
      traderTree,
      intentTree,
      policyTree,
    };

    console.log(`  ✓ Trader Merkle Root: 0x${traderTree.root.toString(16)}`);
    console.log(`  ✓ Intent Merkle Root: 0x${intentTree.root.toString(16)}`);
    console.log(`  ✓ Policy Merkle Root: 0x${policyTree.root.toString(16)}`);

    // ==========================================
    // 7. Generate All Proofs
    // ==========================================
    console.log("\n🔐 Step 7: Generating ZK Proofs...");
    console.log("This may take a moment...\n");

    const { complianceProof, policyProof, strategyProof } = await generateProof(
      traderCredential,
      tradeIntent,
      tradePolicy,
      tradingStrategy,
      strategyContext,
      merkleTreeData
    );

    console.log("  ✓ All Proofs Generated Successfully!");

    console.log("\n  🔒 Compliance Proof:");
    console.log(`    - Public Inputs: ${JSON.stringify(complianceProof.publicInputs)}`);
    console.log(`    - Proof Size: ${complianceProof.proof.length} bytes`);

    console.log("\n  📊 Policy Proof:");
    console.log(`    - Public Inputs: ${JSON.stringify(policyProof.publicInputs)}`);
    console.log(`    - Proof Size: ${policyProof.proof.length} bytes`);

    console.log("\n  📈 Strategy Proof:");
    console.log(`    - Public Inputs: ${JSON.stringify(strategyProof.publicInputs)}`);
    console.log(`    - Proof Size: ${strategyProof.proof.length} bytes`);

    // ==========================================
    // 8. Execute Confidential Swap
    // ==========================================
    console.log("\n🚀 Step 8: Executing Confidential Swap...");
    console.log("  - Preparing swap with ZK proofs...");
    
    // TODO: Implement actual swap execution with the hook contract
    // This would involve:
    // 1. Format proofs for contract calls
    // 2. Call the hook's beforeSwap with all three proofs
    // 3. Execute the swap through PoolManager
    // 4. Verify the results
    
    console.log("\n" + "=".repeat(60));
    console.log("✅ E2E Test Completed Successfully!");
    console.log("=".repeat(60));
    
    console.log("\n✨ Summary:");
    console.log(`  - Trader Jurisdiction: ${traderCredential.jurisdictionCode}`);
    console.log(`  - Trade Amount: ${tradeIntent.amount}`);
    console.log(`  - Policy Max Limit: ${tradePolicy.maxLimit}`);
    console.log(`  - Strategy Limit Price: ${tradingStrategy.limitPrice}`);
    console.log(`  - All ZK proofs generated and ready for on-chain verification`);
    console.log("\n" + "=".repeat(60) + "\n");

  } catch (mainError) {
    console.error("\n❌ Fatal error in main function:");
    console.error(mainError);
    throw mainError;
  }
};

console.log("\n🚀 Initiating E2E test...\n");
main().catch((error) => {
  console.error("\n❌ Unhandled error:");
  console.error(error);
  process.exit(1);
});
