use binary_merkle_root::binary_merkle_root;

use crate::{
    main,
    libs::{
        poseidon::poseidon_hash::{poseidon_hash_1, poseidon_hash_2, poseidon_hash_3, poseidon_hash_4, poseidon_hash_5},
    },
    types::{
        public_inputs::PublicInputs,
        public_outputs::PublicOutputs
    },
    PrivateInputs,
    MERKLE_TREE_DEPTH
};


// =====================================
// @title - Policy Proof Circuit Test
// @notice - Tests trade follows internal policy.
// =====================================
#[test]
fn test_main_success() {
    //--------------------------
    // Test Private Inputs
    //--------------------------
    let amount = 100;
    let limit_price = 160;
    let slippage_tolerance_bps = 50; // 0.50%
    let start_time = 1000;
    let end_time = 2000;
    let pool_state_hash = 12345;
    let nonce = 0;

    let intent_merkle_proof_length = 0;
    let intent_merkle_proof_indices = [0; MERKLE_TREE_DEPTH];
    let intent_merkle_proof_siblings = [0; MERKLE_TREE_DEPTH];
    let intent_secret = 999;
    let nullifier_secret = 666;

    let intent_commitment = poseidon_hash_4([amount, limit_price, nonce, intent_secret]);
    let intent_merkle_root = binary_merkle_root(
        poseidon_hash_2,
        intent_commitment,
        intent_merkle_proof_length,
        intent_merkle_proof_indices,
        intent_merkle_proof_siblings,
    );

    let nullifier = poseidon_hash_3([intent_commitment, intent_merkle_root, nullifier_secret]);

    let private_inputs = PrivateInputs {
        amount,
        limit_price,
        slippage_tolerance_bps,
        start_time,
        end_time,
        pool_state_hash,
        nonce,
        intent_commitment,
        intent_merkle_root,
        intent_merkle_proof_length,
        intent_merkle_proof_indices,
        intent_merkle_proof_siblings,
        nullifier,
        intent_secret,
        nullifier_secret,
    };

    //------------------------------------------------
    // Compute expected nullifier hash
    //-------------------------------------------------
    let nullifier_hash = poseidon_hash_1([nullifier]);

    //--------------------------
    // Test Public Inputs
    //--------------------------
    let public_inputs = PublicInputs {
        twap_price: 155,
        block_timestamp: 1500,  
        nullifier_hash: nullifier_hash,
    };
    
    //------------------------------------------------
    // Run the Circuit with Test Private/PublicInputs
    //-------------------------------------------------
    let public_outputs = main(
        private_inputs, 
        public_inputs
    );

    //----------------------------- 
    // Validate the Public Outputs
    //-----------------------------
    assert(public_outputs.intent_merkle_root == private_inputs.intent_merkle_root, "Intent Merkle Roots don't match");
    assert(public_outputs.nullifier_hash == public_inputs.nullifier_hash, "Nullifier Hashes don't match");
}
