#!/bin/bash

# Extract version from Nargo.toml
VERSION=$(grep '^version = ' Nargo.toml | cut -d '"' -f 2)
echo "Circuit version: $VERSION"

# Clean previous build
rm -rf target

# Install Noir/Nargo
#echo "Install the Noir/Nargo v1.0.0-beta.17..."
#noirup --version 1.0.0-beta.17

# Align the Noir/Nargo version (v1.0.0-beta.17) and bb.js version (v3.0.0-nightly.20251104) of the local machine.
#echo "Install the bb.js version v3.0.0-nightly.20251104..."
#bbup --version 3.0.0-nightly.20251104 (Previous bb.js version: v0.87.0)

echo "Check the Noir/Nargo version of the local machine (This version is supposed to be v1.0.0-beta.17)..."
nargo -V

echo "Check the bb.js version of the local machine (This version is supposed to be v0.87.0)..."
bb --version

# Compile the ZK circuit
echo "Compiling circuit..."
if ! nargo compile; then
    echo "Compilation failed. Exiting..."
    exit 1
fi

echo "Gate count:"
bb gates -b target/compliance.json | jq '.functions[0].circuit_size'

# Create version-specific directory
mkdir -p "../../scripts/circuit-artifacts/compliance/compliance-$VERSION"
#mkdir -p "../app/circuits/compliance-$VERSION"
mkdir -p "target/vk"

echo "Copying compliance.json to scripts/circuit-artifacts/compliance/compliance-$VERSION..."
cp target/compliance.json "../../scripts/circuit-artifacts/compliance/compliance-$VERSION/compliance.json"

echo "Generating a vkey (verification key)..."
bb write_vk -b ./target/compliance.json -o ./target/vk --oracle_hash keccak   # bb.js v3.0.0-nightly.20251104
#bb write_vk -b ./target/compliance.json -o ./target/vk --oracle_hash keccak  # bb.js v0.87.0 (Same with v3.0.0-nightly.20251104)

echo "Generating vk.json to scripts/circuit-artifacts/compliance/compliance-$VERSION..."
node -e "const fs = require('fs'); fs.writeFileSync('../../scripts/circuit-artifacts/compliance/compliance-$VERSION/vk.json', JSON.stringify(Array.from(Uint8Array.from(fs.readFileSync('./target/vk/vk')))));"

echo "Generate a Solidity Verifier contract from the vkey..."
bb write_solidity_verifier -k ./target/vk/vk -o ./target/Verifier.sol

echo "Copy a Solidity Verifier contract-generated (Verifier.sol) into the ../../contracts/src/circuits/compliance-verifier directory"
cp ./target/Verifier.sol ../../contracts/src/circuits/honk-verifier/compliance/Verifier.sol

echo "Rename the Verifier.sol with the honk_vk.sol in the ../../contracts/src/circuits/honk-verifier directory"
mv ../../contracts/src/circuits/honk-verifier/compliance/Verifier.sol ../../contracts/src/circuits/honk-verifier/compliance/HonkVerifier.sol
echo "Done" 