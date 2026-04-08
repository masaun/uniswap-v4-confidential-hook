import { IMT } from "@zk-kit/imt";
import { poseidon_hash_1, poseidon_hash_2, poseidon_hash_3, poseidon_hash_4, poseidon_hash_5, poseidon_hash_6 } from "../zk-utils/poseidon/poseidon.ts";
import { TREE_DEPTH } from "../zk-utils/constants.ts";
import { getIndexOfLeaf, createIncrementalMerkleProof, getIncrementalMerkleRoot } from "../zk-utils/incremental-merkle-tree/incremental-merkle-tree.ts";
import { Noir } from "@noir-lang/noir_js";
import { Barretenberg, UltraHonkBackend, type ProofData } from "@aztec/bb.js";
import complianceCircuitArtifact from "../../circuit-artifacts/compliance/compliance-0.0.1/compliance.json";
import policyCircuitArtifact from "../../circuit-artifacts/policy/policy-0.0.1/policy.json";
import strategyCircuitArtifact from "../../circuit-artifacts/strategy/strategy-0.0.1/strategy.json";

export * from "../zk-utils/constants.ts";

// =====================================
// Type Definitions
// =====================================

// Trader/Compliance related types
export interface TraderCredential {
  jurisdictionCode: bigint;
  traderSecret: bigint;
  credentialExpiry: bigint;
  blockTimestamp: bigint;
}

// Policy/Intent related types
export interface TradeIntent {
  amount: bigint;
  tokenIn: bigint;
  tokenOut: bigint;
  nonce: bigint;
  intentSecret: bigint;
}

export interface TradePolicy {
  tokenIn: bigint;
  tokenOut: bigint;
  maxLimit: bigint;
  policySecret: bigint;
}

// Strategy related types
export interface TradingStrategy {
  amount: bigint;
  limitPrice: bigint;
  slippageToleranceBps: bigint;
  startTime: bigint;
  endTime: bigint;
  nonce: bigint;
  intentSecret: bigint;
}

export interface StrategyContext {
  twapPrice: bigint;
  blockTimestamp: bigint;
  poolStateHash: bigint;
}

// Merkle tree related
export interface MerkleTreeData {
  traderTree: IMT;
  intentTree: IMT;
  policyTree: IMT;
}

export const generateRandomInt = () => {
  return Math.floor(Math.random() * 1000000);
};

export const generateRandomField = () => {
  return BigInt(Math.floor(Math.random() * Number.MAX_SAFE_INTEGER));
};

/**
 * Helper function to create trader commitment
 */
export const createTraderCommitment = (credential: TraderCredential): bigint => {
  return poseidon_hash_2([credential.jurisdictionCode, credential.traderSecret]);
};

/**
 * Helper function to create intent commitment
 */
export const createIntentCommitment = (intent: TradeIntent): bigint => {
  return poseidon_hash_4([intent.amount, intent.tokenIn, intent.tokenOut, intent.intentSecret]);
};

/**
 * Helper function to create policy commitment
 */
export const createPolicyCommitment = (policy: TradePolicy): bigint => {
  return poseidon_hash_4([policy.tokenIn, policy.tokenOut, policy.maxLimit, policy.policySecret]);
};

/**
 * Helper function to create strategy intent commitment
 */
export const createStrategyIntentCommitment = (strategy: TradingStrategy): bigint => {
  return poseidon_hash_4([strategy.amount, strategy.limitPrice, strategy.nonce, strategy.intentSecret]);
};

/**
 * Generates ZK proofs for compliance, policy, and strategy circuits
 * @param traderCredential - Trader compliance credentials
 * @param tradeIntent - Trade intent parameters
 * @param tradePolicy - Trade policy parameters
 * @param tradingStrategy - Trading strategy parameters
 * @param strategyContext - Strategy context (TWAP, timestamp, pool state)
 * @param merkleTreeData - Merkle trees for trader, intent, and policy
 */
export const generateProof = async (
  traderCredential: TraderCredential,
  tradeIntent: TradeIntent,
  tradePolicy: TradePolicy,
  tradingStrategy: TradingStrategy,
  strategyContext: StrategyContext,
  merkleTreeData: MerkleTreeData
): Promise<{
  complianceProof: { proof: ProofData; publicInputs: any };
  policyProof: { proof: ProofData; publicInputs: any };
  strategyProof: { proof: ProofData; publicInputs: any };
}> => {
  const api = await Barretenberg.new();

  // Shared nullifier secret for all proofs
  const nullifierSecret = generateRandomField();

  // ==========================================
  // Prepare Compliance Proof Data
  // ==========================================
  const traderCommitment = createTraderCommitment(traderCredential);
  const traderMerkleRoot = await getIncrementalMerkleRoot(merkleTreeData.traderTree);
  const traderCommitmentIndex = await getIndexOfLeaf(merkleTreeData.traderTree, traderCommitment);
  const traderMerkleProof = await createIncrementalMerkleProof(merkleTreeData.traderTree, traderCommitmentIndex);
  
  // Truncate merkle proof to match circuit depth (8)
  const traderProofTruncated = {
    siblings: traderMerkleProof.siblings.slice(0, TREE_DEPTH),
    pathIndices: traderMerkleProof.pathIndices.slice(0, TREE_DEPTH)
  };

  const complianceNullifier = poseidon_hash_3([traderCommitment, traderMerkleRoot, nullifierSecret]);
  const complianceNullifierHash = poseidon_hash_1([complianceNullifier]);

  // ==========================================
  // 1. Generate Compliance Proof
  // ==========================================
  const complianceNoir = new Noir(complianceCircuitArtifact as any);
  const complianceBackend = new UltraHonkBackend(complianceCircuitArtifact.bytecode, api);

  const complianceInputs = {
    public_inputs: {
      trader_merkle_root: traderMerkleRoot.toString(),
      nullifier_hash: complianceNullifierHash.toString()
    },
    private_inputs: {
      trader_commitment: traderCommitment.toString(),
      trader_merkle_root: traderMerkleRoot.toString(),
      trader_merkle_proof_length: TREE_DEPTH,
      trader_merkle_proof_indices: traderProofTruncated.pathIndices,
      trader_merkle_proof_siblings: traderProofTruncated.siblings.map(v => v.toString()),
      credential_expiry: traderCredential.credentialExpiry.toString(),
      block_timestamp: traderCredential.blockTimestamp.toString(),
      jurisdiction_code: traderCredential.jurisdictionCode.toString(),
      nullifier: complianceNullifier.toString(),
      trader_secret: traderCredential.traderSecret.toString(),
      liquidity_provider_signature_secret: generateRandomField().toString(),
      nullifier_secret: nullifierSecret.toString()
    }
  };

  const complianceWitness = await complianceNoir.execute(complianceInputs);
  const complianceProofData = await complianceBackend.generateProof(complianceWitness.witness, {
    verifierTarget: 'evm'
  });

  // ==========================================
  // 2. Generate Policy Proof
  // ==========================================
  const policyNoir = new Noir(policyCircuitArtifact as any);
  const policyBackend = new UltraHonkBackend(policyCircuitArtifact.bytecode, api);

  const intentCommitment = createIntentCommitment(tradeIntent);
  const policyCommitment = createPolicyCommitment(tradePolicy);
  
  const intentMerkleRoot = await getIncrementalMerkleRoot(merkleTreeData.intentTree);
  const policyMerkleRoot = await getIncrementalMerkleRoot(merkleTreeData.policyTree);
  
  const intentCommitmentIndex = await getIndexOfLeaf(merkleTreeData.intentTree, intentCommitment);
  const intentMerkleProof = await createIncrementalMerkleProof(merkleTreeData.intentTree, intentCommitmentIndex);
  
  const policyCommitmentIndex = await getIndexOfLeaf(merkleTreeData.policyTree, policyCommitment);
  const policyMerkleProof = await createIncrementalMerkleProof(merkleTreeData.policyTree, policyCommitmentIndex);
  
  // Truncate merkle proofs to match circuit depth (8)
  const intentProofTruncated = {
    siblings: intentMerkleProof.siblings.slice(0, TREE_DEPTH),
    pathIndices: intentMerkleProof.pathIndices.slice(0, TREE_DEPTH)
  };
  
  const policyProofTruncated = {
    siblings: policyMerkleProof.siblings.slice(0, TREE_DEPTH),
    pathIndices: policyMerkleProof.pathIndices.slice(0, TREE_DEPTH)
  };

  const policyNullifier = poseidon_hash_5([
    intentCommitment,
    intentMerkleRoot,
    policyCommitment,
    policyMerkleRoot,
    nullifierSecret
  ]);
  const policyNullifierHash = poseidon_hash_1([policyNullifier]);

  const policyInputs = {
    public_inputs: {
      intent_merkle_root: intentMerkleRoot.toString(),
      policy_merkle_root: policyMerkleRoot.toString(),
      nullifier_hash: policyNullifierHash.toString()
    },
    private_inputs: {
      amount: tradeIntent.amount.toString(),
      token_in: tradeIntent.tokenIn.toString(),
      token_out: tradeIntent.tokenOut.toString(),
      max_limit: tradePolicy.maxLimit.toString(),
      nonce: tradeIntent.nonce.toString(),
      pool_id_hash: generateRandomField().toString(),
      intent_commitment: intentCommitment.toString(),
      policy_commitment: policyCommitment.toString(),
      intent_merkle_proof_length: TREE_DEPTH,
      intent_merkle_proof_indices: intentProofTruncated.pathIndices,
      intent_merkle_proof_siblings: intentProofTruncated.siblings.map(v => v.toString()),
      policy_merkle_proof_length: TREE_DEPTH,
      policy_merkle_proof_indices: policyProofTruncated.pathIndices,
      policy_merkle_proof_siblings: policyProofTruncated.siblings.map(v => v.toString()),
      nullifier: policyNullifier.toString(),
      intent_secret: tradeIntent.intentSecret.toString(),
      policy_secret: tradePolicy.policySecret.toString(),
      approver_secret: generateRandomField().toString(),
      nullifier_secret: nullifierSecret.toString()
    }
  };

  const policyWitness = await policyNoir.execute(policyInputs);
  const policyProofData = await policyBackend.generateProof(policyWitness.witness, {
    verifierTarget: 'evm'
  });

  // ==========================================
  // 3. Generate Strategy Proof
  // ==========================================
  const strategyNoir = new Noir(strategyCircuitArtifact as any);
  const strategyBackend = new UltraHonkBackend(strategyCircuitArtifact.bytecode, api);

  const strategyIntentCommitment = createStrategyIntentCommitment(tradingStrategy);
  const strategyIntentMerkleRoot = await getIncrementalMerkleRoot(merkleTreeData.intentTree);
  const strategyIntentCommitmentIndex = await getIndexOfLeaf(merkleTreeData.intentTree, strategyIntentCommitment);
  const strategyIntentMerkleProof = await createIncrementalMerkleProof(merkleTreeData.intentTree, strategyIntentCommitmentIndex);
  
  // Truncate merkle proof to match circuit depth (8)
  const strategyProofTruncated = {
    siblings: strategyIntentMerkleProof.siblings.slice(0, TREE_DEPTH),
    pathIndices: strategyIntentMerkleProof.pathIndices.slice(0, TREE_DEPTH)
  };

  const strategyNullifier = poseidon_hash_3([strategyIntentCommitment, strategyIntentMerkleRoot, nullifierSecret]);
  const strategyNullifierHash = poseidon_hash_1([strategyNullifier]);

  const strategyInputs = {
    public_inputs: {
      twap_price: strategyContext.twapPrice.toString(),
      block_timestamp: strategyContext.blockTimestamp.toString(),
      nullifier_hash: strategyNullifierHash.toString()
    },
    private_inputs: {
      amount: tradingStrategy.amount.toString(),
      limit_price: tradingStrategy.limitPrice.toString(),
      slippage_tolerance_bps: tradingStrategy.slippageToleranceBps.toString(),
      start_time: tradingStrategy.startTime.toString(),
      end_time: tradingStrategy.endTime.toString(),
      pool_state_hash: strategyContext.poolStateHash.toString(),
      nonce: tradingStrategy.nonce.toString(),
      intent_commitment: strategyIntentCommitment.toString(),
      intent_merkle_root: strategyIntentMerkleRoot.toString(),
      intent_merkle_proof_length: TREE_DEPTH,
      intent_merkle_proof_indices: strategyProofTruncated.pathIndices,
      intent_merkle_proof_siblings: strategyProofTruncated.siblings.map(v => v.toString()),
      nullifier: strategyNullifier.toString(),
      intent_secret: tradingStrategy.intentSecret.toString(),
      nullifier_secret: nullifierSecret.toString()
    }
  };

  const strategyWitness = await strategyNoir.execute(strategyInputs);
  const strategyProofData = await strategyBackend.generateProof(strategyWitness.witness, {
    verifierTarget: 'evm'
  });

  return {
    complianceProof: {
      proof: complianceProofData.proof,
      publicInputs: complianceProofData.publicInputs
    },
    policyProof: {
      proof: policyProofData.proof,
      publicInputs: policyProofData.publicInputs
    },
    strategyProof: {
      proof: strategyProofData.proof,
      publicInputs: strategyProofData.publicInputs
    }
  };
};
