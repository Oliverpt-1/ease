# Facial Recognition Validator Module (FRVM)

An ERC-7579 compliant validator module that enables biometric-secured wallet interactions using facial recognition technology.

## Overview

FRVM allows users to:
- Generate deterministic wallet addresses using facial biometrics as salt
- Sign transactions with facial recognition instead of traditional private keys
- Sync user data across multiple chains via LayerZero
- Integrate with ENS for username-based identification
- Enable merchant checkout flows with facial authentication

## Architecture

### Core Components

- **FacialRecognitionValidator**: Main ERC-7579 validator contract
- **Cross-Chain Infrastructure**: LayerZero-based synchronization
- **ENS Integration**: Username registry and resolver
- **Factory Contracts**: Deterministic wallet deployment
- **Merchant System**: Payment processing with facial auth
- **Supporting Libraries**: Hash processing and signature validation

### Contract Structure

```
contracts/
├── validators/
│   └── FacialRecognitionValidator.sol
├── interfaces/
│   ├── IERC7579Module.sol
│   ├── IFacialRecognitionValidator.sol
│   └── ILayerZeroEndpoint.sol
├── cross-chain/
│   ├── CrossChainAttester.sol
│   └── CrossChainAssigner.sol
├── ens/
│   ├── FRVMResolver.sol
│   └── UsernameRegistry.sol
├── factories/
│   ├── FRVMWalletFactory.sol
│   └── ModuleFactory.sol
├── merchants/
│   ├── MerchantAccount.sol
│   └── CheckoutProcessor.sol
└── libraries/
    ├── FacialHashLib.sol
    ├── SignatureLib.sol
    └── CrossChainLib.sol
```

## Setup

1. **Install Dependencies**:
   ```bash
   forge install
   ```

2. **Environment Configuration**:
   ```bash
   cp .env.example .env
   # Fill in your RPC URLs and API keys
   ```

3. **Build Contracts**:
   ```bash
   forge build
   ```

4. **Run Tests**:
   ```bash
   forge test
   ```

## Deployment

### Prerequisites

- Foundry installed
- RPC endpoints configured
- Private keys set up (testnet first!)
- LayerZero endpoints deployed on target chains

### Deploy Sequence

1. **Deploy Core Validator**:
   ```bash
   forge script script/DeployValidator.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
   ```

2. **Deploy Cross-Chain Infrastructure**:
   ```bash
   forge script script/DeployCrossChain.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
   ```

3. **Deploy ENS Components**:
   ```bash
   forge script script/DeployENS.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
   ```

4. **Deploy Factory Contracts**:
   ```bash
   forge script script/DeployFactories.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
   ```

## Usage

### User Registration

1. User provides facial matrix to client-side application
2. Client generates facial hash using `FacialHashLib.hashFacialMatrix()`
3. User calls `registerUser()` with username and facial hash
4. Factory deploys wallet with FRVM validator pre-installed

### Cross-Chain Sync

1. User registration triggers LayerZero message to other chains
2. `CrossChainAssigner` creates assignment for target chains
3. `CrossChainAttester` receives and validates attestations
4. User data propagated across all supported networks

### Merchant Integration

1. Merchant registers via `MerchantAccount.registerMerchant()`
2. Customer enters ENS username at checkout
3. `CheckoutProcessor` initiates facial signature request
4. Customer signs with facial biometrics
5. Payment processed upon successful validation

## Security Considerations

- Facial matrices are hashed before storage
- Signatures include timestamp validation (5-minute window)
- Cross-chain messages require trusted remote verification
- Merchants cannot access raw biometric data
- Fallback mechanisms for hash collisions via index parameter

## Supported Chains

- Ethereum (Mainnet/Sepolia)
- Polygon
- Optimism
- Arbitrum
- Base

## Integration with Kernel

FRVM is designed to work with existing Kernel/Nexus wallet infrastructures:
- Uses Kernel factory for wallet deployment
- Implements ERC-7579 validator interface
- Compatible with multi-module architectures
- Supports existing policy and executor modules

## License

MIT License - see LICENSE file for details