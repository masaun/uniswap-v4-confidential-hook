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

// @dev - The depth of the Merkle Tree for invoice commitments
pub global MERKLE_TREE_DEPTH: u32 = 8;
//pub global MERKLE_TREE_DEPTH: u32 = 16;

// =====================================
// Private Inputs Struct
// =====================================
pub struct PrivateInputs {
    trader_commitment: Field,    // Trader commitment (= leaf) representing "trade intent + limit"

    trader_merkle_root: Field,   // Trader's Compliance Merkle Root
    trader_merkle_proof_length: u32,
    trader_merkle_proof_indices: [u1; MERKLE_TREE_DEPTH],
    trader_merkle_proof_siblings: [Field; MERKLE_TREE_DEPTH],

    credential_expiry: Field,
    block_timestamp: Field,
    jurisdiction_code: Field,

    nullifier: Field,             // Nullifier to prevent double approvals

    trader_secret: Field,
    liquidity_provider_signature_secret: Field,
    nullifier_secret: Field,     // stands for "nullifier witness"
}

// =====================================
// @title - Compliance Proof Circuit
// @notice - Proves trader is in allowlist + not expired.
// =====================================
fn main(
    private_inputs: PrivateInputs,
    public_inputs: PublicInputs
) -> pub (PublicOutputs) {
    // -------------------------
    // Private Inputs
    // -------------------------
    let trader_commitment = private_inputs.trader_commitment;
    let trader_merkle_root = private_inputs.trader_merkle_root; // @dev - Compiant trader merkle root of the compliant trader merkle tree 
    let trader_merkle_proof_length = private_inputs.trader_merkle_proof_length;
    let trader_merkle_proof_indices = private_inputs.trader_merkle_proof_indices;
    let trader_merkle_proof_siblings = private_inputs.trader_merkle_proof_siblings;

    let credential_expiry = private_inputs.credential_expiry;
    let block_timestamp = private_inputs.block_timestamp;
    let jurisdiction_code = private_inputs.jurisdiction_code;
    let nullifier = private_inputs.nullifier;
    
    let trader_secret = private_inputs.trader_secret;
    let liquidity_provider_signature_secret = private_inputs.liquidity_provider_signature_secret;
    let nullifier_secret = private_inputs.nullifier_secret;

    // -------------------------
    // Public Inputs
    // -------------------------
    let nullifier_hash = public_inputs.nullifier_hash;

    // 1-1) Bind proof to trader commitment (identity hidden)
    let computed_trader_commitment = poseidon_hash_2([jurisdiction_code, trader_secret]);
    assert(computed_trader_commitment == trader_commitment, "Trader commitment mismatch");

    // 1-2) Check whether the trader commitment (leaf) is included in the compliant trader merkle tree or not
    let computed_trader_merkle_root = binary_merkle_root(
        poseidon_hash_2,
        trader_commitment,
        trader_merkle_proof_length,
        trader_merkle_proof_indices,
        trader_merkle_proof_siblings,
    );
    assert(computed_trader_merkle_root == trader_merkle_root, "Trader merkle roots don't match");

    // 2) Expiry check
    assert(credential_expiry as u32 > block_timestamp as u32, "Credential expired");

    // 3) Liquidity provider signature witness
    let liquidity_provider_signature_check = poseidon_hash_2([liquidity_provider_signature_secret, trader_secret]);
    assert(liquidity_provider_signature_check != 0, "Invalid provider signature");


    // 4) Nullifier to prevent double approvals
    let computed_nullifier = poseidon_hash_3([
        trader_commitment, 
        trader_merkle_root,
        nullifier_secret
    ]);
    assert(computed_nullifier == nullifier, "nullifiers don't match");

    // 5) Compute nullifier hash to be stored on-chain
    let computed_nullifier_hash = poseidon_hash_1([nullifier]);
    assert(computed_nullifier_hash == nullifier_hash, "nullifier hashes don't match");

    // @dev - Return the public output 
    let public_outputs = PublicOutputs {
        trader_merkle_root,
        nullifier_hash
    };
    public_outputs

}


