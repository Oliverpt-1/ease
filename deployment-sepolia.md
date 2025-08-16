# FRVM Deployment - Ethereum Sepolia

## Deployment Date
August 16, 2025

## Network Details
- **Network**: Ethereum Sepolia
- **Chain ID**: 11155111
- **RPC URL**: https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF
- **Deployer**: 0xeFDF58E251B6aC6A9E9e6151DBfde8E0fBe93c38

## Deployed Contracts

| Contract | Address | Etherscan Link |
|----------|---------|---------------|
| **UsernameRegistry** | `0xd80db8207FA37911Aa6D00f6D1a73aE0d9E996e2` | [View on Etherscan](https://sepolia.etherscan.io/address/0xd80db8207FA37911Aa6D00f6D1a73aE0d9E996e2) |
| **FacialRecognitionValidator** | `0xF6107fAde1Bb2384616Ad4B4c3e9DFbDc1ed599a` | [View on Etherscan](https://sepolia.etherscan.io/address/0xF6107fAde1Bb2384616Ad4B4c3e9DFbDc1ed599a) |
| **MerchantAccount** | `0x13aE8f6734F4fF12C35D34cDd165A91d458d7382` | [View on Etherscan](https://sepolia.etherscan.io/address/0x13aE8f6734F4fF12C35D34cDd165A91d458d7382) |
| **CrossChainAttester** | `0xd64d4fA8783316b8C5A67f125c21c592651C10b8` | [View on Etherscan](https://sepolia.etherscan.io/address/0xd64d4fA8783316b8C5A67f125c21c592651C10b8) |

## External Dependencies
- **LayerZero Endpoint**: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- **ENS Registry**: `0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e`

## Gas Usage
- **Total Gas Used**: 7,300,079
- **Gas Price**: 0.385092484 gwei
- **Total Cost**: 0.00281 ETH

## Next Steps

### 1. Verify Contracts on Etherscan
```bash
forge verify-contract 0xd80db8207FA37911Aa6D00f6D1a73aE0d9E996e2 UsernameRegistry --chain-id 11155111
forge verify-contract 0xF6107fAde1Bb2384616Ad4B4c3e9DFbDc1ed599a FacialRecognitionValidator --chain-id 11155111 --constructor-args $(cast abi-encode "constructor(address)" 0x6EDCE65403992e310A62460808c4b910D972f10f)
forge verify-contract 0x13aE8f6734F4fF12C35D34cDd165A91d458d7382 MerchantAccount --chain-id 11155111 --constructor-args $(cast abi-encode "constructor(address,address)" 0xF6107fAde1Bb2384616Ad4B4c3e9DFbDc1ed599a 0xd80db8207FA37911Aa6D00f6D1a73aE0d9E996e2)
forge verify-contract 0xd64d4fA8783316b8C5A67f125c21c592651C10b8 CrossChainAttester --chain-id 11155111 --constructor-args $(cast abi-encode "constructor(address)" 0x6EDCE65403992e310A62460808c4b910D972f10f)
```

### 2. Configure Cross-Chain (if deploying to other chains)
When you deploy to other chains, you'll need to set trusted remotes for LayerZero communication.

### 3. Test the System
1. Register a test merchant account
2. Create a test user with facial hash
3. Test payment flow through merchant account
4. Test cross-chain attestation (when other chains are deployed)

## Frontend Integration
Update your frontend with these contract addresses:

```javascript
const CONTRACTS = {
  usernameRegistry: "0xd80db8207FA37911Aa6D00f6D1a73aE0d9E996e2",
  frvmValidator: "0xF6107fAde1Bb2384616Ad4B4c3e9DFbDc1ed599a",
  merchantAccount: "0x13aE8f6734F4fF12C35D34cDd165A91d458d7382",
  crossChainAttester: "0xd64d4fA8783316b8C5A67f125c21c592651C10b8"
};
```

## Transaction Details
Full transaction details are saved in:
- `/broadcast/DeployCore.s.sol/11155111/run-latest.json`