//mod tests;

use bb_proof_verification::{
    UltraHonkProof, 
    UltraHonkVerificationKey, 
    verify_honk_proof_non_zk
};

/**
 * @notice This is the main function that verifies an UltraHonk proof.
 * @dev - Verifies the provided UltraHonk proof using the given verification key and public inputs.
 * @param verification_key The UltraHonk verification key.
 * @param proof The UltraHonk proof to be verified.
 * @param public_inputs The public inputs for the proof.
 * @param key_hash The hash of the verification key.
 */
fn main(
    verification_key: UltraHonkVerificationKey,
    proof: UltraHonkProof,
    public_inputs: pub [Field; 1],
    key_hash: Field,
) {
    verify_honk_proof_non_zk(verification_key, proof, public_inputs, key_hash);
}


// #[test]
// fn test_main() {
//     main(1, 2);

//     // Uncomment to make test fail
//     // main(1, 1);
// }
