#!/bin/bash

# Extract version from Nargo.toml
VERSION=$(grep '^version = ' Nargo.toml | cut -d '"' -f 2)
echo "Circuit version: $VERSION"

# Clean previous build
rm -rf target

# Install Noir/Nargo
#echo "Install the Noir/Nargo v1.0.0-beta.18..."
#noirup --version 1.0.0-beta.18

# Align the Noir/Nargo version (v1.0.0-beta.18) and bb.js version (v3.0.0-devnet.6-patch.1) of the local machine.
#echo "Install the bb.js version v3.0.0-devnet.6-patch.1..."
#bbup --version 3.0.0-devnet.6-patch.1 (Previous bb.js version: v0.87.0)

echo "Check the Noir/Nargo version of the local machine (This version is supposed to be v1.0.0-beta.18)..."
nargo -V

echo "Check the bb.js version of the local machine (This version is supposed to be v3.0.0-devnet.6-patch.1)..."
bb --version

# Compile the ZK circuit
echo "Compiling circuit..."
if ! nargo compile; then
    echo "Compilation failed. Exiting..."
    exit 1
fi

echo "Gate count:"
bb gates -b target/strategy.json | jq '.functions[0].circuit_size'

# Create version-specific directory
mkdir -p "../../scripts/circuit-artifacts/strategy/strategy-$VERSION"
#mkdir -p "../app/circuits/strategy-$VERSION"
mkdir -p "target/vk"

echo "Copying strategy.json to scripts/circuit-artifacts/strategy/strategy-$VERSION..."
cp target/strategy.json "../../scripts/circuit-artifacts/strategy/strategy-$VERSION/strategy.json"

echo "Generating a vkey (verification key)..."
bb write_vk -b ./target/strategy.json -o ./target/vk --oracle_hash keccak   # bb.js v3.0.0-devnet.6-patch.1
#bb write_vk -b ./target/strategy.json -o ./target/vk --oracle_hash keccak  # bb.js v0.87.0 (Same with v3.0.0-devnet.6-patch.1)

echo "Generating vk.json to scripts/circuit-artifacts/strategy/strategy-$VERSION..."
node -e "const fs = require('fs'); fs.writeFileSync('../../scripts/circuit-artifacts/strategy/strategy-$VERSION/vk.json', JSON.stringify(Array.from(Uint8Array.from(fs.readFileSync('./target/vk/vk')))));"

echo "Generate a Solidity Verifier contract from the vkey..."
bb write_solidity_verifier -k ./target/vk/vk -o ./target/Verifier.sol

echo "Copy a Solidity Verifier contract-generated (Verifier.sol) into the ../../contracts/src/circuits/strategy-verifier directory"
cp ./target/Verifier.sol ../../contracts/src/circuits/honk-verifier/strategy/Verifier.sol

echo "Rename the Verifier.sol with the honk_vk.sol in the ../../contracts/src/circuits/honk-verifier directory"
mv ../../contracts/src/circuits/honk-verifier/strategy/Verifier.sol ../../contracts/src/circuits/honk-verifier/strategy/HonkVerifier.sol
echo "Done" 