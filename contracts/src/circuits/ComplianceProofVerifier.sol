// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { HonkVerifier } from "./honk-verifier/compliance/HonkVerifier.sol";

contract ComplianceProofVerifier {
    HonkVerifier public verifier;

    constructor(address _verifier) {
        verifier = HonkVerifier(_verifier);
    }

    function verifyComplianceProof(
        bytes calldata proof, 
        bytes32[] calldata publicInputs
    ) external view returns (bool) {
        bool isValidProof = verifier.verify(proof, publicInputs);
        require(isValidProof, "Invalid ZK Compliance Proof");
        return isValidProof;
    }
}