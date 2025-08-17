#!/bin/bash

# Simple test to verify storage concept without compilation issues
echo "Testing storage retrieval concept..."

# Use cast to call the actual contract on Sepolia
VALIDATOR_ADDRESS="0x3356f1D40068bD3f05b81B0e83Fb0c58d9030574"
TEST_USER="0x861CFf1AebEEAd101e7D2629f0097bC3e4Ec3e81"
RPC_URL="https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF"

echo "Calling getUserData for bro.eaze.eth wallet..."
echo "Address: $TEST_USER"

# Call getUserData function
cast call $VALIDATOR_ADDRESS "getUserData(address)" $TEST_USER --rpc-url $RPC_URL

echo ""
echo "If this returns data, it means:"
echo "1. ✓ User is registered in the contract"
echo "2. ✓ Facial embedding is stored and retrievable"
echo "3. ✓ Storage system is working properly"

echo ""
echo "Next step: Use this stored embedding vs a random one in Chainlink comparison"