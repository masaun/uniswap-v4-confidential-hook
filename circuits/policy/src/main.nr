mod tests;
mod libs;
mod types;

use binary_merkle_root::binary_merkle_root;
use libs::{
    poseidon::poseidon_hash::{poseidon_hash_1, poseidon_hash_2, poseidon_hash_4, poseidon_hash_5},
};
use types::{
    public_inputs::PublicInputs,
    public_outputs::PublicOutputs
};

// @dev - The depth of the Merkle Tree for invoice commitments
pub global MERKLE_TREE_DEPTH: u32 = 8;
//pub global MERKLE_TREE_DEPTH: u32 = 16;

// =====================================
// Private Inputs Struct
// =====================================
pub struct PrivateInputs {
    amount: Field,    // amount_in for the trade
    token_in: Field,
    token_out: Field,
    max_limit: Field,
    nonce: Field,
    pool_id_hash: Field,

    intent_commitment: Field,    // Intent commitment (= leaf) representing "trade intent + limit"
    policy_commitment: Field,    // Policy commitment (= leaf) representing "token pair + limit"

    intent_merkle_proof_length: u32,
    intent_merkle_proof_indices: [u1; MERKLE_TREE_DEPTH],
    intent_merkle_proof_siblings: [Field; MERKLE_TREE_DEPTH],

    policy_merkle_proof_length: u32,
    policy_merkle_proof_indices: [u1; MERKLE_TREE_DEPTH],
    policy_merkle_proof_siblings: [Field; MERKLE_TREE_DEPTH],

    nullifier: Field,            // Nullifier to prevent double approvals

    intent_secret: Field,        // stands for "intent witness"
    policy_secret: Field,        // stands for "policy witness"
    approver_secret: Field,      // stands for "signature witness"
    nullifier_secret: Field,     // stands for "nullifier witness"
}


// =================================================
// @title - Policy Proof Circuit
// @notice - Proves trade follows internal policy.
// =================================================
fn main(
    private_inputs: PrivateInputs,
    public_inputs: PublicInputs,
) -> pub (PublicOutputs) {
    // --------------------------
    // Private Inputs
    // --------------------------
    let amount = private_inputs.amount;
    let token_in = private_inputs.token_in;
    let token_out = private_inputs.token_out;
    let max_limit = private_inputs.max_limit;
    let nonce = private_inputs.nonce;
    let pool_id_hash = private_inputs.pool_id_hash;

    let intent_commitment = private_inputs.intent_commitment;
    let policy_commitment = private_inputs.policy_commitment;

    let intent_merkle_proof_length = private_inputs.intent_merkle_proof_length;
    let intent_merkle_proof_indices = private_inputs.intent_merkle_proof_indices;
    let intent_merkle_proof_siblings = private_inputs.intent_merkle_proof_siblings;

    let policy_merkle_proof_length = private_inputs.policy_merkle_proof_length;
    let policy_merkle_proof_indices = private_inputs.policy_merkle_proof_indices;
    let policy_merkle_proof_siblings = private_inputs.policy_merkle_proof_siblings;

    let nullifier = private_inputs.nullifier;

    let intent_secret = private_inputs.intent_secret;
    let policy_secret = private_inputs.policy_secret;
    let approver_secret = private_inputs.approver_secret;
    let nullifier_secret = private_inputs.nullifier_secret;

    // --------------------------
    // Public Inputs
    // --------------------------
    let nullifier_hash = public_inputs.nullifier_hash;
    let intent_merkle_root = public_inputs.intent_merkle_root;
    let policy_merkle_root = public_inputs.policy_merkle_root;

    // --------------------------
    // Circuit Logic
    // --------------------------
    // 1-1) Intent binding
    let computed_intent_commitment = poseidon_hash_4([amount, token_in, token_out, intent_secret]);
    assert(computed_intent_commitment == intent_commitment, "intent commitments don't match");

    // 1-2) Check whether the intent commitment (leaf) is included in the intent merkle tree or not
    let computed_intent_merkle_root = binary_merkle_root(
        poseidon_hash_2,
        intent_commitment,
        intent_merkle_proof_length,
        intent_merkle_proof_indices,
        intent_merkle_proof_siblings,
    );
    assert(computed_intent_merkle_root == intent_merkle_root, "merkle roots don't match");

    // 2-1) Policy membership (simplified merkle check)
    let computed_policy_commitment = poseidon_hash_4([token_in, token_out, max_limit, policy_secret]);
    assert(computed_policy_commitment == policy_commitment, "policy commitments don't match");

    // 2-2) Check whether the policy commitment (= policy leaf) is included in the policy merkle tree or not
    let computed_policy_merkle_root = binary_merkle_root(
        poseidon_hash_2,
        policy_commitment,
        policy_merkle_proof_length,
        policy_merkle_proof_indices,
        policy_merkle_proof_siblings,
    );
    assert(computed_policy_merkle_root == policy_merkle_root, "policy merkle roots don't match");

    // 3) Enforce policy: amount <= max_limit
    assert(amount as u128 <= max_limit as u128);

    // 4) Approver authorization (simplified)
    // In practice this would be signature verification.
    let auth = poseidon_hash_2([nonce, approver_secret]);
    assert(auth != 0);

    // 5) Bind proof to pool
    assert(pool_id_hash != 0);

    // 6) Nullifier to prevent double approvals
    let computed_nullifier = poseidon_hash_5([
        intent_commitment, 
        intent_merkle_root,
        policy_commitment, 
        policy_merkle_root, 
        nullifier_secret
    ]);
    assert(computed_nullifier == nullifier, "nullifiers don't match");

    // 7) Compute nullifier hash to be stored on-chain
    let computed_nullifier_hash = poseidon_hash_1([nullifier]);
    assert(computed_nullifier_hash == nullifier_hash, "nullifier hashes don't match");

    // @dev - Return the public output 
    let public_outputs = PublicOutputs {
        intent_merkle_root,
        policy_merkle_root,
        nullifier_hash
    };
    public_outputs
}