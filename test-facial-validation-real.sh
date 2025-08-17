#!/bin/bash

# Test facial validation with properly encoded data
echo "🧪 Testing facial validation with real encoded data..."

VALIDATOR_ADDRESS="0x3356f1D40068bD3f05b81B0e83Fb0c58d9030574"
TEST_USER="0x861CFf1AebEEAd101e7D2629f0097bC3e4Ec3e81"
RPC_URL="https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF"

echo "Testing facial validation implementation..."
echo "User: $TEST_USER (bro.eaze.eth)"
echo ""

# Create a simple test - encode array of 3 random values
echo "Creating test embedding: [1000000, 2000000, 3000000]"

# Encode the array properly
ENCODED_EMBEDDING=$(cast abi-encode "uint256[]" "[1000000,2000000,3000000]")
echo "Encoded embedding: $ENCODED_EMBEDDING"

# Create facial signature struct
FACIAL_HASH="0x1234567890123456789012345678901234567890123456789012345678901234"
TIMESTAMP="1755372944"

echo ""
echo "Calling testValidateFacialSignature with:"
echo "  Sender: $TEST_USER"
echo "  UserOpHash: 0x0000..."
echo "  FacialSig: (hash: $FACIAL_HASH, timestamp: $TIMESTAMP, signature: $ENCODED_EMBEDDING)"
echo ""

# Call the function
cast send $VALIDATOR_ADDRESS "testValidateFacialSignature(address,bytes32,(bytes32,uint256,bytes))" \
    $TEST_USER \
    0x0000000000000000000000000000000000000000000000000000000000000000 \
    "($FACIAL_HASH,$TIMESTAMP,$ENCODED_EMBEDDING)" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

echo ""
echo "🎯 This should:"
echo "1. ✅ Fetch stored embedding from bro.eaze.eth's wallet data"
echo "2. ✅ Compare with test embedding [1000000,2000000,3000000]"
echo "3. ✅ Make real Chainlink request to CompreFace API"
echo "4. ✅ Call verificationResult() to get response"
echo "5. ✅ Return validation result"