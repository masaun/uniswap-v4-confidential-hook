//mod tests;

// =====================================
// Compliance Proof Circuit
// Proves trader is in allowlist + not expired.
// =====================================
fn main(
    // -------------------------
    // Private Inputs
    // -------------------------
    secret user_id_secret: Field,
    secret jurisdiction_code: Field,
    secret merkle_path_element: Field,
    secret provider_signature_secret: Field,

    // -------------------------
    // Public Inputs
    // -------------------------
    public compliance_root: Field,
    public credential_expiry: Field,
    public block_timestamp: Field,
    public trader_commitment: Field
) {
    // 1) Bind proof to trader commitment (identity hidden)
    let computed_trader_commitment = hash2(user_id_secret, jurisdiction_code);
    computed_trader_commitment.assert_equals(trader_commitment);

    // 2) Allowlist membership (simplified Merkle)
    let computed_root = hash2(computed_trader_commitment, merkle_path_element);
    computed_root.assert_equals(compliance_root);

    // 3) Expiry check
    credential_expiry.assert_greater_than(block_timestamp);

    // 4) Provider signature witness (placeholder)
    let sig_check = hash2(provider_signature_secret, user_id_secret);
    sig_check.assert_not_equals(0);
}


fn hash2(a: Field, b: Field) -> Field {
    a + b * 257
}


// fn main(x: u64, y: pub u64) {
//     assert(x != y);
// }

