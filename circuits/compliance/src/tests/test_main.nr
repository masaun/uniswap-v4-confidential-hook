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


// =========================================================
// @title - Compliance Proof Circuit Test
// @notice - Tests trader is in allowlist + not expired.
// =========================================================
#[test]
fn test_main_success() {
    //--------------------------
    // Test Private Inputs
    //--------------------------
    let credential_expiry = 2000;
    let block_timestamp = 1500;
    let jurisdiction_code = 1; // +1 for US

    let trader_secret = 999;
    let liquidity_provider_signature_secret = 888;
    let nullifier_secret = 666;

    let trader_commitment = poseidon_hash_2([jurisdiction_code, trader_secret]);
    let trader_merkle_proof_length = 0;
    let trader_merkle_proof_indices = [0; MERKLE_TREE_DEPTH];
    let trader_merkle_proof_siblings = [0; MERKLE_TREE_DEPTH];
    let trader_merkle_root = binary_merkle_root(
        poseidon_hash_2,
        trader_commitment,
        trader_merkle_proof_length,
        trader_merkle_proof_indices,
        trader_merkle_proof_siblings,
    );

    let nullifier = poseidon_hash_3([trader_commitment, trader_merkle_root, nullifier_secret]);

    let private_inputs = PrivateInputs {
        trader_commitment,
        trader_merkle_root,
        trader_merkle_proof_length,
        trader_merkle_proof_indices,
        trader_merkle_proof_siblings,
        credential_expiry,
        block_timestamp,
        jurisdiction_code,
        nullifier,
        trader_secret,
        liquidity_provider_signature_secret,
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
        trader_merkle_root,
        nullifier_hash
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
    assert(public_outputs.trader_merkle_root == private_inputs.trader_merkle_root, "Trader Merkle Roots don't match");
    assert(public_outputs.nullifier_hash == public_inputs.nullifier_hash, "Nullifier Hashes don't match");
}
