mod tests;
mod libs;
mod types;

use binary_merkle_root::binary_merkle_root;
use libs::{
    poseidon::poseidon_hash::{poseidon_hash_1, poseidon_hash_2, poseidon_hash_3, poseidon_hash_4, poseidon_hash_5},
};
use types::{
    public_inputs::PublicInputs,
    public_outputs::PublicOutputs
};


// =====================================
// Private Inputs Struct
// =====================================
pub struct PrivateInputs {
    amount: Field,                  // amount_in for the trade
    limit_price: Field,
    slippage_tolerance_bps: Field,  // e.g. 50 = 0.50%
    start_time: Field,
    end_time: Field,
    pool_state_hash: Field,
    nonce: Field,

    intent_commitment: Field,    // Intent commitment (= leaf) representing "trade intent + limit"

    intent_merkle_root: Field,
    intent_merkle_proof_length: u32,
    intent_merkle_proof_indices: [u1; 16],
    intent_merkle_proof_siblings: [Field; 16],

    nullifier: Field,             // Nullifier to prevent double approvals

    intent_secret: Field,        // stands for "intent witness"
    nullifier_secret: Field,     // stands for "nullifier witness"
}


// =====================================
// Strategy Proof Circuit (TWAP Bound)
// =====================================
fn main(
    private_inputs: PrivateInputs,
    public_inputs: PublicInputs
) -> pub (PublicOutputs) {
    // --------------------------
    // Private Inputs
    // --------------------------
    let amount = private_inputs.amount;
    let limit_price = private_inputs.limit_price;
    let slippage_tolerance_bps = private_inputs.slippage_tolerance_bps;
    let start_time = private_inputs.start_time;
    let end_time = private_inputs.end_time;
    let pool_state_hash = private_inputs.pool_state_hash;
    let nonce = private_inputs.nonce;

    let intent_commitment = private_inputs.intent_commitment;

    let intent_merkle_root = private_inputs.intent_merkle_root;
    let intent_merkle_proof_length = private_inputs.intent_merkle_proof_length;
    let intent_merkle_proof_indices = private_inputs.intent_merkle_proof_indices;
    let intent_merkle_proof_siblings = private_inputs.intent_merkle_proof_siblings;

    let nullifier = private_inputs.nullifier;
    
    let intent_secret = private_inputs.intent_secret;
    let nullifier_secret = private_inputs.nullifier_secret;

    // --------------------------
    // Public Inputs
    // --------------------------
    let twap_price = public_inputs.twap_price;
    let block_timestamp = public_inputs.block_timestamp;
    let nullifier_hash = public_inputs.nullifier_hash;

    // --------------------------
    // Circuit Logic
    // --------------------------
    // 1-1) Intent binding
    let computed_intent_commitment = poseidon_hash_4([amount, limit_price, nonce, intent_secret]);
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

    // 2) Execution window check
    assert(block_timestamp as u32 >= start_time as u32, "block timestamp is before start time");
    assert(block_timestamp as u32 <= end_time as u32, "block timestamp is after end time");

    // 3) TWAP slippage bound check:
    // limit_price >= twap_price * (1 - slippage_tolerance_bps/10000)
    let min_price = (twap_price as u128) * ((10000 - slippage_tolerance_bps) as u128) / 10000;
    assert(limit_price as u128 >= min_price, "limit price is below minimum allowed price");

    // 4) sanity binding to pool state
    assert(pool_state_hash as u32 != 0, "invalid pool state hash");

    // 6) Nullifier to prevent double approvals
    let computed_nullifier = poseidon_hash_3([
        intent_commitment, 
        intent_merkle_root,
        nullifier_secret
    ]);
    assert(computed_nullifier == nullifier, "nullifiers don't match");

    // 7) Compute nullifier hash to be stored on-chain
    let computed_nullifier_hash = poseidon_hash_1([nullifier]);
    assert(computed_nullifier_hash == nullifier_hash, "nullifier hashes don't match");

    // @dev - Return the public output 
    let public_outputs = PublicOutputs {
        intent_merkle_root,
        nullifier_hash
    };
    public_outputs
}





// fn main(x: u64, y: pub u64) {
//     assert(x != y);
// }

