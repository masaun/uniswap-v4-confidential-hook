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
import { createWalletClient, createPublicClient, http, parseUnits, formatUnits, encodeAbiParameters, type WalletClient, type PublicClient, type Address } from "viem";
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

// Token addresses on Unichain Sepolia - use Mock tokens from env
const TOKEN0_ADDRESS = (process.env.MOCK_USDC_ADDRESS || "0x31d0220469e10c4E71834a79b1f276d740d3768F") as Address; // Mock USDC on Unichain Sepolia
const TOKEN1_ADDRESS = (process.env.MOCK_WETH_ADDRESS || "0x0000000000000000000000000000000000000000") as Address; // Mock WETH (or use zero address for native ETH)

// Validate environment variables
if (!HOOK_ADDRESS || !POOL_MANAGER_ADDRESS || !INSTITUTIONAL_TRADER_PRIVATE_KEY || !RPC_URL) {
  throw new Error("Missing required environment variables in contracts/.env");
}

console.log("🔧 Configuration:");
console.log("  - Network: Unichain Sepolia");
console.log("  - RPC URL:", RPC_URL);
console.log("  - Hook Address:", HOOK_ADDRESS);
console.log("  - Pool Manager Address:", POOL_MANAGER_ADDRESS);
console.log("  - Token0 Address:", TOKEN0_ADDRESS);
console.log("  - Token1 Address:", TOKEN1_ADDRESS);

// Contract ABIs
const ERC20_ABI = [
  {
    type: "function",
    name: "balanceOf",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "approve",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "allowance",
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" }
    ],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view"
  }
] as const;

const POOL_MANAGER_ABI = [
  {
    type: "function",
    name: "swap",
    inputs: [
      {
        name: "key",
        type: "tuple",
        components: [
          { name: "currency0", type: "address" },
          { name: "currency1", type: "address" },
          { name: "fee", type: "uint24" },
          { name: "tickSpacing", type: "int24" },
          { name: "hooks", type: "address" }
        ]
      },
      {
        name: "params",
        type: "tuple",
        components: [
          { name: "zeroForOne", type: "bool" },
          { name: "amountSpecified", type: "int256" },
          { name: "sqrtPriceLimitX96", type: "uint160" }
        ]
      },
      { name: "hookData", type: "bytes" }
    ],
    outputs: [{ name: "delta", type: "int256" }],
    stateMutability: "nonpayable"
  }
] as const;

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
    
    // Format proofs for contract calls
    const complianceProofHex = `0x${Buffer.from(complianceProof.proof).toString('hex')}` as `0x${string}`;
    const policyProofHex = `0x${Buffer.from(policyProof.proof).toString('hex')}` as `0x${string}`;
    const strategyProofHex = `0x${Buffer.from(strategyProof.proof).toString('hex')}` as `0x${string}`;

    // Convert public inputs to bytes32 arrays
    const compliancePublicInputsBytes32 = complianceProof.publicInputs.map((input: string) => {
      const hex = BigInt(input).toString(16).padStart(64, '0');
      return `0x${hex}` as `0x${string}`;
    });
    
    const policyPublicInputsBytes32 = policyProof.publicInputs.map((input: string) => {
      const hex = BigInt(input).toString(16).padStart(64, '0');
      return `0x${hex}` as `0x${string}`;
    });
    
    const strategyPublicInputsBytes32 = strategyProof.publicInputs.map((input: string) => {
      const hex = BigInt(input).toString(16).padStart(64, '0');
      return `0x${hex}` as `0x${string}`;
    });

    console.log("  ✓ Proofs formatted for contract:");
    console.log(`    - Compliance Proof: ${complianceProofHex.substring(0, 66)}... (${complianceProofHex.length} chars)`);
    console.log(`    - Policy Proof: ${policyProofHex.substring(0, 66)}... (${policyProofHex.length} chars)`);
    console.log(`    - Strategy Proof: ${strategyProofHex.substring(0, 66)}... (${strategyProofHex.length} chars)`);
    console.log(`    - Compliance Public Inputs: [${compliancePublicInputsBytes32.length} items]`);
    console.log(`    - Policy Public Inputs: [${policyPublicInputsBytes32.length} items]`);
    console.log(`    - Strategy Public Inputs: [${strategyPublicInputsBytes32.length} items]`);

    // Encode hookData with all three proofs and their public inputs
    // The hook expects: complianceProof, policyProof, strategyProof, compliancePublicInputs, policyPublicInputs, strategyPublicInputs
    const hookData = encodeAbiParameters(
      [
        { name: 'complianceProof', type: 'bytes' },
        { name: 'policyProof', type: 'bytes' },
        { name: 'strategyProof', type: 'bytes' },
        { name: 'compliancePublicInputs', type: 'bytes32[]' },
        { name: 'policyPublicInputs', type: 'bytes32[]' },
        { name: 'strategyPublicInputs', type: 'bytes32[]' },
      ],
      [
        complianceProofHex,
        policyProofHex,
        strategyProofHex,
        compliancePublicInputsBytes32,
        policyPublicInputsBytes32,
        strategyPublicInputsBytes32,
      ]
    );

    console.log(`  ✓ Hook data encoded: ${hookData.substring(0, 66)}... (${hookData.length} chars)`);

    // ==========================================
    // 9. Token Approvals
    // ==========================================
    console.log("\n💰 Step 9: Checking balances and approving tokens...");
    
    // Check TOKEN0 (USDC) balance
    const token0Balance = await publicClient.readContract({
      address: TOKEN0_ADDRESS,
      abi: ERC20_ABI,
      functionName: "balanceOf",
      args: [account.address]
    }) as bigint;

    // Check TOKEN1 (WETH or ETH) balance
    let token1Balance: bigint;
    let token1IsNative = TOKEN1_ADDRESS === "0x0000000000000000000000000000000000000000";
    
    if (token1IsNative) {
      // Native ETH - use getBalance
      token1Balance = await publicClient.getBalance({
        address: account.address
      });
    } else {
      // ERC20 token - use readContract
      token1Balance = await publicClient.readContract({
        address: TOKEN1_ADDRESS,
        abi: ERC20_ABI,
        functionName: "balanceOf",
        args: [account.address]
      }) as bigint;
    }

    console.log(`  - Token0 (USDC) Balance: ${formatUnits(token0Balance, 6)} USDC`);
    console.log(`  - Token1 (${token1IsNative ? 'ETH' : 'WETH'}) Balance: ${formatUnits(token1Balance, 18)} ${token1IsNative ? 'ETH' : 'WETH'}`);

    // Check and approve TOKEN0 (USDC) for PoolManager
    const token0Allowance = await publicClient.readContract({
      address: TOKEN0_ADDRESS,
      abi: ERC20_ABI,
      functionName: "allowance",
      args: [account.address, POOL_MANAGER_ADDRESS]
    }) as bigint;

    if (token0Allowance < parseUnits("1000", 6)) {
      console.log("  - Approving Token0 (USDC) for PoolManager...");
      const approveTx = await walletClient.writeContract({
        address: TOKEN0_ADDRESS,
        abi: ERC20_ABI,
        functionName: "approve",
        args: [POOL_MANAGER_ADDRESS, parseUnits("1000000", 6)] // Approve 1M USDC
      });
      await publicClient.waitForTransactionReceipt({ hash: approveTx });
      console.log(`  ✓ Token0 approved: ${approveTx}`);
    } else {
      console.log("  ✓ Token0 already approved");
    }

    // Approve TOKEN1 (WETH) if it's not native ETH
    if (!token1IsNative) {
      const token1Allowance = await publicClient.readContract({
        address: TOKEN1_ADDRESS,
        abi: ERC20_ABI,
        functionName: "allowance",
        args: [account.address, POOL_MANAGER_ADDRESS]
      }) as bigint;

      if (token1Allowance < parseUnits("1000", 18)) {
        console.log("  - Approving Token1 (WETH) for PoolManager...");
        const approveTx = await walletClient.writeContract({
          address: TOKEN1_ADDRESS,
          abi: ERC20_ABI,
          functionName: "approve",
          args: [POOL_MANAGER_ADDRESS, parseUnits("1000", 18)] // Approve 1000 WETH
        });
        await publicClient.waitForTransactionReceipt({ hash: approveTx });
        console.log(`  ✓ Token1 approved: ${approveTx}`);
      } else {
        console.log("  ✓ Token1 already approved");
      }
    } else {
      console.log("  ✓ Token1 is native ETH - no approval needed");
    }

    // ==========================================
    // 10. Execute Swap with ZK Proofs${token1IsNative ? 'ETH' : 'WETH'}
    // ==========================================
    console.log("\n🔄 Step 10: Executing confidential swap on Uniswap V4...");
    
    // Configure PoolKey
    const poolKey = {
      currency0: TOKEN0_ADDRESS,
      currency1: TOKEN1_ADDRESS,
      fee: 3000, // 0.3% fee
      tickSpacing: 60,
      hooks: HOOK_ADDRESS
    };

    // Configure swap parameters
    const swapParams = {
      zeroForOne: true, // Swapping token0 (USDC) for token1 (ETH)
      amountSpecified: parseUnits("100", 6), // 100 USDC (6 decimals)
      sqrtPriceLimitX96: 0n // No price limit
    };

    console.log("  - Pool Configuration:");
    console.log(`    - Currency0: ${poolKey.currency0}`);
    console.log(`    - Currency1: ${poolKey.currency1}`);
    console.log(`    - Fee: ${poolKey.fee / 10000}%`);
    console.log(`    - Hook: ${poolKey.hooks}`);
    console.log("  - Swap Parameters:");
    console.log(`    - Direction: USDC → ETH`);
    console.log(`    - Amount: ${formatUnits(swapParams.amountSpecified, 6)} USDC`);
    console.log(`    - Hook Data: ${hookData.length} chars`);

    try {
      console.log("\n  - Submitting swap transaction with ZK proofs...");
      
      const swapTx = await walletClient.writeContract({
        address: POOL_MANAGER_ADDRESS,
        abi: POOL_MANAGER_ABI,
        functionName: "swap",
        args: [poolKey, swapParams, hookData]
      });

      console.log(`  ✓ Swap transaction submitted: ${swapTx}`);
      console.log("  - Waiting for confirmation...");

      const receipt = await publicClient.waitForTransactionReceipt({ hash: swapTx });
      
      console.log("  ✓ Swap executed successfully!");
      console.log(`    - Block: ${receipt.blockNumber}`);
      console.log(`    - Gas Used: ${receipt.gasUsed.toString()}`);
      console.log(`    - Transaction: https://unichain-sepolia.blockscout.com/tx/${swapTx}`);

      // Check updated balances
      const newToken0Balance = await publicClient.readContract({
        address: TOKEN0_ADDRESS,
        abi: ERC20_ABI,
        functionName: "balanceOf",
        args: [account.address]
      }) as bigint;

      let newToken1Balance: bigint;
      if (token1IsNative) {
        newToken1Balance = await publicClient.getBalance({
          address: account.address
        });
      } else {
        newToken1Balance = await publicClient.readContract({
          address: TOKEN1_ADDRESS,
          abi: ERC20_ABI,
          functionName: "balanceOf",
          args: [account.address]
        }) as bigint;
      }

      console.log("\n  📊 Balance Changes:");
      console.log(`    - USDC: ${formatUnits(token0Balance, 6)} → ${formatUnits(newToken0Balance, 6)} (${formatUnits(newToken0Balance - token0Balance, 6)})`);
      console.log(`    - ${token1IsNative ? 'ETH' : 'WETH'}: ${formatUnits(token1Balance, 18)} → ${formatUnits(newToken1Balance, 18)} (${formatUnits(newToken1Balance - token1Balance, 18)})`);
      
    } catch (swapError: any) {
      console.error("\n  ❌ Swap execution failed:");
      console.error("  ", swapError.message || swapError);
      
      if (swapError.message?.includes("Compliance Proof Verification Failed")) {
        console.log("\n  🔍 Compliance proof verification failed on-chain");
      } else if (swapError.message?.includes("Policy Proof Verification Failed")) {
        console.log("\n  🔍 Policy proof verification failed on-chain");
      } else if (swapError.message?.includes("Strategy Proof Verification Failed")) {
        console.log("\n  🔍 Strategy proof verification failed on-chain");
      }
      
      throw swapError;
    }
    
    console.log("\n" + "=".repeat(60));
    console.log("✅ E2E Test Completed Successfully!");
    console.log("=".repeat(60));
    
    console.log("\n✨ Summary:");
    console.log(`  - Trader Jurisdiction: ${traderCredential.jurisdictionCode}`);
    console.log(`  - Trade Amount: ${tradeIntent.amount}`);
    console.log(`  - Policy Max Limit: ${tradePolicy.maxLimit}`);
    console.log(`  - Strategy Limit Price: ${tradingStrategy.limitPrice}`);
    console.log(`  - Compliance Proof: ${complianceProof.proof.length} bytes`);
    console.log(`  - Policy Proof: ${policyProof.proof.length} bytes`);
    console.log(`  - Strategy Proof: ${strategyProof.proof.length} bytes`);
    console.log(`  - Hook Data Size: ${hookData.length} chars (${Math.floor(hookData.length / 2)} bytes)`);
    console.log(`  - All ZK proofs generated, formatted, and ready for on-chain verification`);
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
