# Ease - Facial Recognition Verified Multi-chain Smart Wallets

Ease is a revolutionary decentralized application that combines facial recognition technology with smart contract wallets, providing secure, passwordless wallet management with seamless cross-chain functionality.

## Features

- **Facial Recognition Authentication**: Secure wallet access using advanced facial biometric verification
- **Multi-chain Support**: Deploy and manage wallets across multiple blockchain networks
- **Account Abstraction**: ERC-4337 compliant smart wallets with gas sponsorship
- **ENS Integration**: Human-readable usernames via ENS subdomains (username.eaze.eth)
- **Cross-chain Operations**: Seamless asset management across different chains
- **Merchant Integration**: Built-in payment processing for businesses
- **Gasless Transactions**: Optional gas sponsorship for improved UX

## Architecture

### Smart Contracts

- **`FRVMWalletFactory.sol`**: Main factory for deploying facial recognition verified wallets
- **`faceRecognitionValidator.sol`**: ERC-7579 validator module for facial authentication
- **`MerchantAccount.sol`**: Business account management for payment processing
- **`CheckoutProcessor.sol`**: Payment flow management for merchant transactions

### Frontend Components

- **Next.js 15**: Modern React framework with App Router
- **Account Abstraction**: Integration with Permissionless.js and Pimlico
- **Facial Recognition**: CompreFace integration for biometric verification
- **Wallet Management**: Viem-based wallet client with smart account support

## Quick Start

### Prerequisites

- Node.js 18+ and npm
- Foundry (for smart contract development)
- CompreFace instance (for facial recognition)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Ease
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env.local
   ```
   Configure the following variables:
   - `NEXT_PUBLIC_COMPREFACE_API_URL`: Your CompreFace instance URL
   - `NEXT_PUBLIC_COMPREFACE_API_KEY`: CompreFace API key
   - `NEXT_PUBLIC_PIMLICO_API_KEY`: Pimlico bundler API key
   - Blockchain RPC URLs and contract addresses

4. **Start the development server**
   ```bash
   npm run dev
   ```

5. **Visit the application**
   Open [http://localhost:3000](http://localhost:3000) in your browser

## 🔧 Smart Contract Development

### Setup

```bash
# Install Foundry dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test
```

### Deployment

Deploy to Sepolia testnet:

```bash
# Set environment variables
source script/setup-env.sh

# Deploy contracts
forge script script/DeployOnly.s.sol:DeployOnly --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Contract Addresses (Sepolia)

| Contract | Address | Description |
|----------|---------|-------------|
| FRVMWalletFactory | `0xA052A466e52f0ac53B9647eadcCA865eF8adD003` | Main wallet factory |
| FacialValidator | `0x3356f1D40068bD3f05b81B0e83Fb0c58d9030574` | Facial recognition validator |

## 📱 Usage

### Creating a Wallet

1. **Visit the application** and click "Create Wallet"
2. **Choose a username** (will become username.eaze.eth)
3. **Complete facial registration** using the camera interface
4. **Deploy your wallet** - the system will create your smart wallet and ENS subdomain

### Accessing Your Wallet

1. **Enter your username** (or username.eaze.eth)
2. **Complete facial verification** using the camera
3. **Access your wallet** - perform transactions with facial authentication

### Making Payments

1. **Access your wallet** via facial verification
2. **Enter recipient and amount**
3. **Confirm with facial scan** - transaction is submitted with gas sponsorship

## 🛠️ API Reference

### Wallet Client Hook

```typescript
import { useWalletClient } from '@/components/use-wallet-client'

const { deployWallet, createWalletClient, sendPayment } = useWalletClient()

// Deploy a new wallet
const { address, transactionHash } = await deployWallet(username, facialEmbedding)

// Create wallet client for existing wallet
const client = await createWalletClient(username, facialEmbedding)

// Send payment
const txHash = await sendPayment(recipientAddress, amount)
```

### Facial Recognition Integration

```typescript
import { useCompreFace } from '@/components/use-compreface'

const { registerFace, verifyFace, isLoading } = useCompreFace()

// Register a new face
const embedding = await registerFace(imageData, userId)

// Verify a face
const isValid = await verifyFace(imageData, userId)
```

## 🧪 Testing

### Smart Contract Tests

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testFacialValidation

# Run with verbose output
forge test -vvv
```

### Frontend Testing

```bash
# Run component tests
npm test

# Run e2e tests
npm run test:e2e
```

## 🌐 Deployment

### Frontend Deployment (Railway)

1. **Install Railway CLI**
   ```bash
   npm install -g @railway/cli
   ```

2. **Deploy to Railway**
   ```bash
   railway login
   railway up
   ```

3. **Configure environment variables** in Railway dashboard

See [README-DEPLOYMENT.md](./README-DEPLOYMENT.md) for detailed deployment instructions.

### Smart Contract Deployment

Use the provided deployment scripts for different networks:

```bash
# Deploy to Sepolia
./deploy-sepolia.sh

# Verify deployment
./verify-deployment.sh
```

## 🔒 Security

- **Facial Data**: All facial embeddings are processed locally and stored securely on-chain
- **Private Keys**: No traditional private keys - authentication via biometric verification
- **Smart Contract Security**: Audited ERC-7579 compliant modules
- **Gas Safety**: Built-in gas limit and value validation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the [deployment guide](./README-DEPLOYMENT.md)
- **Issues**: Report bugs via GitHub Issues
- **Discord**: Join our community for support and discussions

## 🔗 Links

- **Demo**: [ease-demo.railway.app](https://ease-demo.railway.app)
- **Sepolia Testnet**: [sepolia.etherscan.io](https://sepolia.etherscan.io)
- **ENS Domains**: [app.ens.domains](https://app.ens.domains)

---

Built with ❤️ using modern web3 technologies for the future of decentralized identity.