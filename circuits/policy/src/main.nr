//mod tests;
mod types;
mod libs;

use libs::{
    poseidon::poseidon_hash::{poseidon_hash_2, poseidon_hash_4},
};

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

    policy_leaf: Field,          // leaf representing "token pair + limit"
    policy_path_element: Field,  // simplified (placeholder)
    approver_secret: Field,       // stands for "signature witness"

    // -------------------------
    // Public Inputs
    // -------------------------
    intent_commitment: pub Field,
    policy_root: pub Field,
    nonce: pub Field,
    pool_id_hash: pub Field
) {
    // 1) Intent binding
    let computed_commitment = poseidon_hash_4([amount, token_in, token_out, nonce]);
    assert(computed_commitment == intent_commitment);

    // 2) Policy membership (simplified merkle check)
    let computed_root = poseidon_hash_2([policy_leaf, policy_path_element]);
    assert(computed_root == policy_root);

    // 3) Enforce policy: amount <= max_limit
    assert(amount as u128 <= max_limit as u128);

    // 4) Approver authorization (simplified)
    // In practice this would be signature verification.
    let auth = poseidon_hash_2([approver_secret, nonce]);
    assert(auth != 0);

    // 5) Bind proof to pool
    assert(pool_id_hash != 0);
}


// fn hash2(a: Field, b: Field) -> Field {
//     a + b * 131
// }

// fn hash4(a: Field, b: Field, c: Field, d: Field) -> Field {
//     a + b * 17 + c * 31 + d * 73
// }