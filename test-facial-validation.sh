#!/bin/bash

# Test script for facial validation integration
# This script runs integration tests against the deployed contracts on Sepolia

echo "🧪 Running Facial Validation Integration Tests"
echo "=============================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please create one with SEPOLIA_RPC_URL"
    exit 1
fi

# Source environment variables
source .env

# Check if SEPOLIA_RPC_URL is set
if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "❌ SEPOLIA_RPC_URL not found in .env file"
    echo "Please add: SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
    exit 1
fi

echo "🌐 Using Sepolia RPC: ${SEPOLIA_RPC_URL:0:50}..."
echo ""

# Run the integration tests
echo "🔍 Running facial validation integration tests..."
forge test --match-contract FacialValidationIntegrationTest --fork-url $SEPOLIA_RPC_URL -vvv

echo ""
echo "📊 Test Results Summary:"
echo "========================"

# Run specific test functions with detailed output
echo ""
echo "1️⃣ Testing Chainlink Integration..."
forge test --match-test testChainlinkIntegrationDirect --fork-url $SEPOLIA_RPC_URL -vvv

echo ""
echo "2️⃣ Testing Embedding Conversion..."
forge test --match-test testEmbeddingToStringConversion --fork-url $SEPOLIA_RPC_URL -vv

echo ""
echo "3️⃣ Testing User Data Retrieval..."
forge test --match-test testUserDataRetrieval --fork-url $SEPOLIA_RPC_URL -vv

echo ""
echo "✅ Integration tests completed!"
echo ""
echo "📝 Next steps:"
echo "   1. If Chainlink requests succeed, check the callback results"
echo "   2. Monitor Sepolia transactions for actual Chainlink calls"
echo "   3. Verify facial embeddings are properly formatted for CompreFace API"