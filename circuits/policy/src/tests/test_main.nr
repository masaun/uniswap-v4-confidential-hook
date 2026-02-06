use binary_merkle_root::binary_merkle_root;

use crate::{
    main,
    libs::{
        poseidon::poseidon_hash::{poseidon_hash_1, poseidon_hash_2, poseidon_hash_4, poseidon_hash_5},
    },
    types::{
        public_inputs::PublicInputs,
        public_outputs::PublicOutputs
    },
    PrivateInputs,
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
    let token_in = 1;
    let token_out = 2;
    let max_limit = 200;
    let nonce = 0;
    let pool_id_hash = 12345;

    let intent_merkle_proof_length = 0;
    let intent_merkle_proof_indices = [0; 16];
    let intent_merkle_proof_siblings = [0; 16];

    let policy_merkle_proof_length = 0;
    let policy_merkle_proof_indices = [0; 16];
    let policy_merkle_proof_siblings = [0; 16];

    let intent_secret = 999;
    let policy_secret = 888;
    let approver_secret = 777;
    let nullifier_secret = 666;

    let intent_commitment = poseidon_hash_4([amount, token_in, token_out, intent_secret]);
    let policy_commitment = poseidon_hash_4([token_in, token_out, max_limit, policy_secret]);

    let intent_merkle_root = binary_merkle_root(
        poseidon_hash_2,
        intent_commitment,
        intent_merkle_proof_length,
        intent_merkle_proof_indices,
        intent_merkle_proof_siblings,
    );
    let policy_merkle_root = binary_merkle_root(
        poseidon_hash_2,
        policy_commitment,
        policy_merkle_proof_length,
        policy_merkle_proof_indices,
        policy_merkle_proof_siblings,
    );

    let nullifier = poseidon_hash_5([
        intent_commitment,
        intent_merkle_root,
        policy_commitment,
        policy_merkle_root,
        nullifier_secret,
    ]);

    let private_inputs = PrivateInputs {
        amount,
        token_in,
        token_out,
        max_limit,
        nonce,
        pool_id_hash,

        intent_commitment,
        policy_commitment,

        intent_merkle_proof_length,
        intent_merkle_proof_indices,
        intent_merkle_proof_siblings,

        policy_merkle_proof_length,
        policy_merkle_proof_indices,
        policy_merkle_proof_siblings,

        intent_secret,
        policy_secret,
        approver_secret,
        nullifier_secret,
    };

    //--------------------------
    // Test Public Inputs
    //--------------------------
    let public_inputs = PublicInputs {
        intent_merkle_root,
        policy_merkle_root,
        nullifier,
    };

    //------------------------------------------------
    // Compute expected nullifier hash
    //-------------------------------------------------
    let expected_nullifier_hash = poseidon_hash_1([nullifier]);
    
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
    assert(public_outputs.intent_merkle_root == public_inputs.intent_merkle_root, "Intent Merkle Roots don't match");
    assert(public_outputs.policy_merkle_root == public_inputs.policy_merkle_root, "Policy Merkle Roots don't match");
    assert(public_outputs.nullifier_hash == expected_nullifier_hash, "Nullifiers don't match");
}
