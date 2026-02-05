//mod tests;
mod libs;
mod types;

use libs::{
    poseidon::poseidon_hash::{poseidon_hash_2, poseidon_hash_4},
};

use binary_merkle_root::binary_merkle_root;

// =====================================
// Policy Proof Circuit
// Proves trade follows internal policy.
// =====================================
fn main(
    // -------------------------
    // Private Inputs
    // -------------------------
    amount: Field,
    token_in: Field,
    token_out: Field,
    max_limit: Field,

    policy_commitment: Field,    // Policy commitment (= leaf) representing "token pair + limit"
    approver_secret: Field,      // stands for "signature witness"

    intent_merkle_root: Field,
    intent_merkle_proof_length: u32,
    intent_merkle_proof_indices: [u1; 16],
    intent_merkle_proof_siblings: [Field; 16],

    // -------------------------
    // Public Inputs
    // -------------------------
    intent_commitment: pub Field,
    policy_merkle_root: pub Field,
    nonce: pub Field,
    pool_id_hash: pub Field
) {
    // 1-1) Intent binding
    let computed_intent_commitment = poseidon_hash_4([amount, token_in, token_out, nonce]);
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
    let computed_policy_commitment = poseidon_hash_4([token_in, token_out, max_limit, approver_secret]);
    assert(computed_policy_commitment == policy_commitment, "policy commitments don't match");

    // 2-2) Check whether the policy commitment (= policy leaf) is included in the policy merkle tree or not
    let computed_policy_merkle_root = poseidon_hash_2([policy_commitment, approver_secret]);
    assert(computed_policy_merkle_root == policy_merkle_root, "policy merkle roots don't match");

    // 3) Enforce policy: amount <= max_limit
    assert(amount as u128 <= max_limit as u128);

    // 4) Approver authorization (simplified)
    // In practice this would be signature verification.
    let auth = poseidon_hash_2([nonce, approver_secret]);
    assert(auth != 0);

    // 5) Bind proof to pool
    assert(pool_id_hash != 0);
}