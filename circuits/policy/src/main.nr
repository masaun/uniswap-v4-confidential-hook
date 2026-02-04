//mod tests;

// =====================================
// Policy Proof Circuit
// Proves trade follows internal policy.
// =====================================
fn main(
    // -------------------------
    // Private Inputs
    // -------------------------
    secret amount: Field,
    secret token_in: Field,
    secret token_out: Field,
    secret max_limit: Field,

    secret policy_leaf: Field,          // leaf representing "token pair + limit"
    secret policy_path_element: Field,  // simplified (placeholder)
    secret approver_secret: Field,       // stands for "signature witness"

    // -------------------------
    // Public Inputs
    // -------------------------
    public intent_commitment: Field,
    public policy_root: Field,
    public nonce: Field,
    public pool_id_hash: Field
) {
    // 1) Intent binding
    let computed_commitment = hash4(amount, token_in, token_out, nonce);
    computed_commitment.assert_equals(intent_commitment);

    // 2) Policy membership (simplified merkle check)
    let computed_root = hash2(policy_leaf, policy_path_element);
    computed_root.assert_equals(policy_root);

    // 3) Enforce policy: amount <= max_limit
    amount.assert_less_than_or_equal(max_limit);

    // 4) Approver authorization (simplified)
    // In practice this would be signature verification.
    let auth = hash2(approver_secret, nonce);
    auth.assert_not_equals(0);

    // 5) Bind proof to pool
    pool_id_hash.assert_not_equals(0);
}


fn hash2(a: Field, b: Field) -> Field {
    a + b * 131
}

fn hash4(a: Field, b: Field, c: Field, d: Field) -> Field {
    a + b * 17 + c * 31 + d * 73
}




// fn main(x: u64, y: pub u64) {
//     assert(x != y);
// }
