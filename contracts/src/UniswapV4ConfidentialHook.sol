// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ----- ZK Confidential Hook Proof Verifier Contract Imports -----
import { ComplianceProofVerifier } from "./circuits/ComplianceProofVerifier.sol";
import { PolicyProofVerifier } from "./circuits/PolicyProofVerifier.sol";
import { StrategysProofVerifier } from "./circuits/StrategyProofVerifier.sol";

// ----- Uniswap V4 Hook Base Contract Import -----
import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

/**
 * @title - UniswapV4ConfidentialHook contract
 * @notice - A Uniswap V4 Hook that integrates ZK Proof verification for Compliance, Policy, and Strategy using Honk verifiers.
 *           This hook verifies ZK proofs before allowing swaps and liquidity additions to ensure they meet specified criteria.
 */
contract UniswapV4ConfidentialHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    ComplianceProofVerifier public complianceProofVerifier;
    PolicyProofVerifier public policyProofVerifier;
    StrategysProofVerifier public strategyProofVerifier;

    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    mapping(PoolId => uint256 count) public beforeSwapCount;
    mapping(PoolId => uint256 count) public afterSwapCount;

    mapping(PoolId => uint256 count) public beforeAddLiquidityCount;
    mapping(PoolId => uint256 count) public beforeRemoveLiquidityCount;

    constructor(
        IPoolManager _poolManager, 
        ComplianceProofVerifier _complianceProofVerifier, 
        PolicyProofVerifier _policyProofVerifier,
        StrategysProofVerifier _strategyProofVerifier
    ) BaseHook(_poolManager) {
        complianceProofVerifier = _complianceProofVerifier;
        policyProofVerifier = _policyProofVerifier;
        strategyProofVerifier = _strategyProofVerifier;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true, // True
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,         // True
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    /**
     * @notice - Hook function called before a swap is executed
     * @dev - Verify ZK Proofs for Compliance, Policy, and Strategy before allowing the swap
     * @param complianceProof - ZK Proof for Compliance
     * @param policyProof - ZK Proof for Policy
     * @param strategyProof - ZK Proof for Strategy
     * @param compliancePublicInputs - Public Inputs for Compliance Proof
     * @param policyPublicInputs - Public Inputs for Policy Proof
     * @param strategyPublicInputs - Public Inputs for Strategy Proof
     */
    function _beforeSwap(
        address, PoolKey calldata key, 
        SwapParams calldata, 
        bytes calldata,
        // --- ZK Confidential Hook Proof Parameters ---
        bytes calldata complianceProof, 
        bytes calldata policyProof, 
        bytes calldata strategyProof, 
        bytes32[] calldata compliancePublicInputs,
        bytes32[] calldata policyPublicInputs,
        bytes32[] calldata strategyPublicInputs
    )
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // @dev - Verify ZK Confidential Hook Proofs
        bool isComplianceVerified = complianceProofVerifier.verifyComplianceProof(complianceProof, compliancePublicInputs);
        bool isPolicyVerified = policyProofVerifier.verifyPolicyProof(policyProof, policyPublicInputs);
        bool isStrategyVerified = strategyProofVerifier.verifyStrategyProof(strategyProof, strategyPublicInputs);
        require(isComplianceVerified, "Compliance Proof Verification Failed");
        require(isPolicyVerified, "Policy Proof Verification Failed");
        require(isStrategyVerified, "Strategy Proof Verification Failed");

        // @dev - Increment beforeSwapCount for the pool
        beforeSwapCount[key.toId()]++;
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    /**
     * @notice - Hook function called before a liquidity is added
     * @dev - Verify ZK Proofs for Compliance, Policy, and Strategy before allowing the liquidity addition
     * @param complianceProof - ZK Proof for Compliance
     * @param policyProof - ZK Proof for Policy
     * @param strategyProof - ZK Proof for Strategy
     * @param compliancePublicInputs - Public Inputs for Compliance Proof
     * @param policyPublicInputs - Public Inputs for Policy Proof
     * @param strategyPublicInputs - Public Inputs for Strategy Proof
     */
    function _beforeAddLiquidity(
        address, PoolKey calldata key, 
        ModifyLiquidityParams calldata, 
        bytes calldata,
        // --- ZK Confidential Hook Proof Parameters ---
        bytes calldata complianceProof, 
        bytes calldata policyProof, 
        bytes calldata strategyProof, 
        bytes32[] calldata compliancePublicInputs,
        bytes32[] calldata policyPublicInputs,
        bytes32[] calldata strategyPublicInputs
    )
        internal
        override
        returns (bytes4)
    {
        // @dev - Verify ZK Confidential Hook Proofs
        bool isComplianceVerified = complianceProofVerifier.verifyComplianceProof(complianceProof, compliancePublicInputs);
        bool isPolicyVerified = policyProofVerifier.verifyPolicyProof(policyProof, policyPublicInputs);
        bool isStrategyVerified = strategyProofVerifier.verifyStrategyProof(strategyProof, strategyPublicInputs);
        require(isComplianceVerified, "Compliance Proof Verification Failed");
        require(isPolicyVerified, "Policy Proof Verification Failed");
        require(isStrategyVerified, "Strategy Proof Verification Failed");

        // @dev - Increment beforeAddLiquidityCount for the pool
        beforeAddLiquidityCount[key.toId()]++;
        return BaseHook.beforeAddLiquidity.selector;
    }
}
