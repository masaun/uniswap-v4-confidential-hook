//mod tests;

// =====================================
// Strategy Proof Circuit (TWAP Bound)
// =====================================
fn main(
    // -------------------------
    // Private Inputs
    // -------------------------
    secret amount: Field,
    secret limit_price: Field,
    secret epsilon_bps: Field,     // e.g. 50 = 0.50%
    secret start_time: Field,
    secret end_time: Field,

    // -------------------------
    // Public Inputs
    // -------------------------
    public intent_commitment: Field,
    public twap_price: Field,
    public block_timestamp: Field,
    public pool_state_hash: Field,
    public nonce: Field
) {
    // 1) Intent binding
    let computed_commitment = hash3(amount, limit_price, nonce);
    computed_commitment.assert_equals(intent_commitment);

    // 2) Execution window check
    block_timestamp.assert_greater_than_or_equal(start_time);
    block_timestamp.assert_less_than_or_equal(end_time);

    // 3) TWAP slippage bound check:
    // limit_price >= twap_price * (1 - epsilon_bps/10000)
    let min_price = twap_price * (10000 - epsilon_bps) / 10000;
    limit_price.assert_greater_than_or_equal(min_price);

    // 4) sanity binding to pool state
    pool_state_hash.assert_not_equals(0);
}


fn hash3(a: Field, b: Field, c: Field) -> Field {
    a + b * 19 + c * 97
}




// fn main(x: u64, y: pub u64) {
//     assert(x != y);
// }

