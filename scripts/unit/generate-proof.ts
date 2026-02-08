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

/**
 * @notice - Unit script to generate ZK proofs for Compliance, Policy, and Strategy circuits
 */
const main = async () => {
  console.log("=".repeat(60));
  console.log("Generating ZK Proofs for Uniswap V4 Confidential Hook");
  console.log("=".repeat(60));

  // ==========================================
  // 1. Setup Trader Credential (Compliance)
  // ==========================================
  const traderCredential: TraderCredential = {
    jurisdictionCode: BigInt(1), // e.g., US = 1
    traderSecret: generateRandomField(),
    credentialExpiry: BigInt(Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60), // 1 year from now
    blockTimestamp: BigInt(Math.floor(Date.now() / 1000)),
  };

  const traderCommitment = createTraderCommitment(traderCredential);
  console.log("\n📋 Trader Credential:");
  console.log(`  Jurisdiction: ${traderCredential.jurisdictionCode}`);
  console.log(`  Commitment: 0x${traderCommitment.toString(16)}`);

  // ==========================================
  // 2. Setup Trade Intent (Policy)
  // ==========================================
  const tradeIntent: TradeIntent = {
    amount: BigInt(1000000), // 1M units
    tokenIn: BigInt(0x1), // USDC address (simplified)
    tokenOut: BigInt(0x2), // ETH address (simplified)
    nonce: BigInt(Date.now()),
    intentSecret: generateRandomField(),
  };

  const intentCommitment = createIntentCommitment(tradeIntent);
  console.log("\n💱 Trade Intent:");
  console.log(`  Amount: ${tradeIntent.amount}`);
  console.log(`  Token In: 0x${tradeIntent.tokenIn.toString(16)}`);
  console.log(`  Token Out: 0x${tradeIntent.tokenOut.toString(16)}`);
  console.log(`  Commitment: 0x${intentCommitment.toString(16)}`);

  // ==========================================
  // 3. Setup Trade Policy
  // ==========================================
  const tradePolicy: TradePolicy = {
    tokenIn: tradeIntent.tokenIn,
    tokenOut: tradeIntent.tokenOut,
    maxLimit: BigInt(2000000), // Max 2M units
    policySecret: generateRandomField(),
  };

  const policyCommitment = createPolicyCommitment(tradePolicy);
  console.log("\n📜 Trade Policy:");
  console.log(`  Max Limit: ${tradePolicy.maxLimit}`);
  console.log(`  Commitment: 0x${policyCommitment.toString(16)}`);

  // ==========================================
  // 4. Setup Trading Strategy
  // ==========================================
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
  console.log("\n⚡ Trading Strategy:");
  console.log(`  Limit Price: ${tradingStrategy.limitPrice}`);
  console.log(`  Slippage Tolerance: ${tradingStrategy.slippageToleranceBps} bps`);
  console.log(`  Commitment: 0x${strategyIntentCommitment.toString(16)}`);

  // ==========================================
  // 5. Setup Strategy Context
  // ==========================================
  const strategyContext: StrategyContext = {
    twapPrice: BigInt(2950), // TWAP price: $2950
    blockTimestamp: BigInt(now),
    poolStateHash: generateRandomField(),
  };

  console.log("\n🌊 Strategy Context:");
  console.log(`  TWAP Price: ${strategyContext.twapPrice}`);
  console.log(`  Block Timestamp: ${strategyContext.blockTimestamp}`);

  // ==========================================
  // 6. Create Merkle Trees
  // ==========================================
  console.log("\n🌳 Creating Merkle Trees...");
  
  const { imTree: traderTree } = await getIncrementalMerkleTree([traderCommitment]);
  const { imTree: intentTree } = await getIncrementalMerkleTree([intentCommitment, strategyIntentCommitment]);
  const { imTree: policyTree } = await getIncrementalMerkleTree([policyCommitment]);

  const merkleTreeData: MerkleTreeData = {
    traderTree,
    intentTree,
    policyTree,
  };

  console.log(`  Trader Merkle Root: 0x${traderTree.root.toString(16)}`);
  console.log(`  Intent Merkle Root: 0x${intentTree.root.toString(16)}`);
  console.log(`  Policy Merkle Root: 0x${policyTree.root.toString(16)}`);

  // ==========================================
  // 7. Generate All Proofs
  // ==========================================
  console.log("\n🔐 Generating ZK Proofs...");
  console.log("This may take a moment...\n");

  const { complianceProof, policyProof, strategyProof } = await generateProof(
    traderCredential,
    tradeIntent,
    tradePolicy,
    tradingStrategy,
    strategyContext,
    merkleTreeData
  );

  // ==========================================
  // 8. Display Results
  // ==========================================
  console.log("=".repeat(60));
  console.log("✅ All Proofs Generated Successfully!");
  console.log("=".repeat(60));

  console.log("\n🔒 Compliance Proof:");
  console.log(`  Public Inputs: ${JSON.stringify(complianceProof.publicInputs)}`);
  console.log(`  Proof Size: ${complianceProof.proof.length} bytes`);

  console.log("\n📊 Policy Proof:");
  console.log(`  Public Inputs: ${JSON.stringify(policyProof.publicInputs)}`);
  console.log(`  Proof Size: ${policyProof.proof.length} bytes`);

  console.log("\n📈 Strategy Proof:");
  console.log(`  Public Inputs: ${JSON.stringify(strategyProof.publicInputs)}`);
  console.log(`  Proof Size: ${strategyProof.proof.length} bytes`);

  console.log("\n" + "=".repeat(60));
  console.log("✨ Proof generation complete!");
  console.log("=".repeat(60) + "\n");
};

main().catch(console.error);
