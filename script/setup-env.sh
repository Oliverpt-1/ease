#!/bin/bash

# FRVM Multi-Chain Deployment Setup Script
# This script helps set up the environment for multi-chain deployment

echo "========================================="
echo "FRVM Multi-Chain Deployment Setup"
echo "========================================="
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << 'EOF'
# Private key for deployment (DO NOT COMMIT!)
PRIVATE_KEY=

# RPC URLs for different chains
SEPOLIA_RPC_URL=https://ethereum-sepolia.publicnode.com
BASE_SEPOLIA_RPC_URL=https://base-sepolia-rpc.publicnode.com
ARBITRUM_SEPOLIA_RPC_URL=https://arbitrum-sepolia.publicnode.com
OPTIMISM_SEPOLIA_RPC_URL=https://optimism-sepolia.publicnode.com
POLYGON_AMOY_RPC_URL=https://polygon-amoy-bor-rpc.publicnode.com

# Etherscan API Keys for verification
ETHERSCAN_API_KEY=
BASESCAN_API_KEY=
ARBISCAN_API_KEY=
OPTIMISM_API_KEY=
POLYGONSCAN_API_KEY=

# LayerZero configuration
LZ_ENDPOINT_SEPOLIA=0x6EDCE65403992e310A62460808c4b910D972f10f
LZ_ENDPOINT_BASE_SEPOLIA=0x6EDCE65403992e310A62460808c4b910D972f10f
LZ_ENDPOINT_ARBITRUM_SEPOLIA=0x6EDCE65403992e310A62460808c4b910D972f10f
LZ_ENDPOINT_OPTIMISM_SEPOLIA=0x6EDCE65403992e310A62460808c4b910D972f10f
LZ_ENDPOINT_POLYGON_AMOY=0x6EDCE65403992e310A62460808c4b910D972f10f

# ENS Registry (Ethereum Sepolia only)
ENS_REGISTRY_SEPOLIA=0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
EOF
    echo "✅ .env file created. Please fill in your private key and API keys."
else
    echo "⚠️  .env file already exists. Skipping creation."
fi

echo ""
echo "========================================="
echo "Deployment Commands:"
echo "========================================="
echo ""
echo "1. Deploy to all chains:"
echo "   forge script script/DeployMultiChain.s.sol:DeployMultiChain --sig 'deployAllChains()' --broadcast"
echo ""
echo "2. Deploy to specific chain (example: Ethereum Sepolia):"
echo "   forge script script/DeployMultiChain.s.sol:DeployMultiChain --sig 'deployToChain(uint256)' 11155111 --rpc-url \$SEPOLIA_RPC_URL --broadcast"
echo ""
echo "3. Deploy core contracts only:"
echo "   forge script script/DeployCore.s.sol:DeployCore --rpc-url \$SEPOLIA_RPC_URL --broadcast"
echo ""
echo "4. Export deployment addresses:"
echo "   forge script script/DeployMultiChain.s.sol:DeployMultiChain --sig 'exportDeployments()'"
echo ""
echo "========================================="
echo "Chain IDs Reference:"
echo "========================================="
echo "Ethereum Sepolia: 11155111"
echo "Base Sepolia: 84532"
echo "Arbitrum Sepolia: 421614"
echo "Optimism Sepolia: 11155420"
echo "Polygon Amoy: 80002"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo "1. Fill in your PRIVATE_KEY in .env file"
echo "2. Add RPC URLs if using different providers"
echo "3. Add Etherscan API keys for contract verification"
echo "4. Run deployment scripts as needed"
echo ""
echo "For hackathon deployment, you can use the simplified DeployCore.s.sol"
echo "for single-chain deployment, or DeployMultiChain.s.sol for full"
echo "multi-chain deployment with cross-chain configuration."
echo ""