#!/bin/bash

# Deploy FRVM contracts to Sepolia

echo "🚀 Deploying FRVM contracts to Sepolia..."

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY environment variable is not set"
    echo "Please set your private key: export PRIVATE_KEY=your_private_key_here"
    exit 1
fi

# Check if RPC URL is set, otherwise use default Sepolia RPC
if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "⚠️  SEPOLIA_RPC_URL not set, using default public RPC"
    export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/demo"
fi

echo "📦 Building contracts..."
forge build

echo "🔗 Deploying to Sepolia..."
forge script script/DeployFRVM.s.sol:DeployFRVM \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv

echo "✅ Deployment complete!"
echo "Check the deployments/ directory for deployment details"