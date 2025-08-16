#!/bin/bash

# Load environment variables
source .env

echo "======================================"
echo "🔍 VERIFYING DEPLOYMENT ON SEPOLIA"
echo "======================================"
echo ""

# Contract addresses from deployment
FRVM_VALIDATOR="0xB44c071f26066947a7f0cdF830f608c29D3659cE"
WALLET_FACTORY="0x113B34718B4D69Ff3612A9685967802914E1913e"
MODULE_FACTORY="0x58bc346173bCAA058B74D533F860Ae25c76E1906"
MERCHANT_ACCOUNT="0x284AA25FedBD37591c3723630377d8eB3b8C4C74"
USERNAME_REGISTRY="0xabBf19fef8faEf1b8EBc258aB166E52bAA6A4ec9"
CROSS_CHAIN_ATTESTER="0x40ABE76af8b94D9D19dBDfBEa00e239306496aCB"

# Expected values
EXPECTED_LZ_ENDPOINT="0x6EDCE65403992e310A62460808c4b910D972f10f"
EXPECTED_KERNEL_FACTORY="0xd6CEDDe84be40893d153Be9d467CD6aD37875b28"

echo "1. Checking contract deployment..."
echo "-----------------------------------"

# Check if contracts have bytecode
for CONTRACT in $FRVM_VALIDATOR $WALLET_FACTORY $MODULE_FACTORY $MERCHANT_ACCOUNT $USERNAME_REGISTRY $CROSS_CHAIN_ATTESTER; do
    CODE=$(cast code $CONTRACT --rpc-url $SEPOLIA_RPC_URL 2>/dev/null | head -c 10)
    if [ "$CODE" = "0x" ] || [ -z "$CODE" ]; then
        echo "❌ Contract $CONTRACT not deployed"
    else
        echo "✅ Contract $CONTRACT deployed"
    fi
done

echo ""
echo "2. Verifying contract configurations..."
echo "----------------------------------------"

# Check FRVMValidator configuration
LZ_ENDPOINT=$(cast call $FRVM_VALIDATOR "lzEndpoint()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
if [ "$LZ_ENDPOINT" = "0x0000000000000000000000006edce65403992e310a62460808c4b910d972f10f" ]; then
    echo "✅ FRVMValidator: LayerZero endpoint configured correctly"
else
    echo "❌ FRVMValidator: LayerZero endpoint mismatch"
fi

# Check WalletFactory configuration
KERNEL_FACTORY=$(cast call $WALLET_FACTORY "kernelFactory()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
if [ "$KERNEL_FACTORY" = "0x000000000000000000000000d6cedde84be40893d153be9d467cd6ad37875b28" ]; then
    echo "✅ WalletFactory: Kernel Factory configured correctly"
else
    echo "❌ WalletFactory: Kernel Factory mismatch"
fi

FRVM_REF=$(cast call $WALLET_FACTORY "frvmValidator()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
if [ "$FRVM_REF" = "0x000000000000000000000000b44c071f26066947a7f0cdf830f608c29d3659ce" ]; then
    echo "✅ WalletFactory: FRVM Validator reference correct"
else
    echo "❌ WalletFactory: FRVM Validator reference mismatch"
fi

# Check MerchantAccount configuration
MERCHANT_FRVM=$(cast call $MERCHANT_ACCOUNT "frvmValidator()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
if [ "$MERCHANT_FRVM" = "0x000000000000000000000000b44c071f26066947a7f0cdf830f608c29d3659ce" ]; then
    echo "✅ MerchantAccount: FRVM Validator reference correct"
else
    echo "❌ MerchantAccount: FRVM Validator reference mismatch"
fi

echo ""
echo "3. Testing contract functionality..."
echo "-------------------------------------"

# Test FRVM module type
MODULE_TYPE=$(cast call $FRVM_VALIDATOR "isModuleType(uint256)" 1 --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
if [ "$MODULE_TYPE" = "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo "✅ FRVMValidator: Module type check passed (is validator)"
else
    echo "❌ FRVMValidator: Module type check failed"
fi

echo ""
echo "4. Checking Etherscan verification..."
echo "--------------------------------------"

for CONTRACT_NAME in "FRVMValidator" "WalletFactory" "ModuleFactory" "MerchantAccount" "UsernameRegistry" "CrossChainAttester"; do
    case $CONTRACT_NAME in
        "FRVMValidator") ADDRESS=$FRVM_VALIDATOR ;;
        "WalletFactory") ADDRESS=$WALLET_FACTORY ;;
        "ModuleFactory") ADDRESS=$MODULE_FACTORY ;;
        "MerchantAccount") ADDRESS=$MERCHANT_ACCOUNT ;;
        "UsernameRegistry") ADDRESS=$USERNAME_REGISTRY ;;
        "CrossChainAttester") ADDRESS=$CROSS_CHAIN_ATTESTER ;;
    esac
    echo "🔗 $CONTRACT_NAME: https://sepolia.etherscan.io/address/$ADDRESS"
done

echo ""
echo "======================================"
echo "📊 DEPLOYMENT VERIFICATION COMPLETE"
echo "======================================"