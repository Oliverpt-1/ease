# Railway Deployment Guide

## Quick Deploy

1. **Connect to Railway**
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli
   
   # Login to Railway
   railway login
   
   # Deploy from this directory
   railway up
   ```

2. **Set Environment Variables**
   Copy `.env.example` to set up your environment variables in Railway dashboard:
   - Go to your Railway project dashboard
   - Navigate to Variables tab
   - Add all required environment variables from `.env.example`

## Required Environment Variables

### Essential for Basic Functionality
- `NEXT_PUBLIC_COMPREFACE_API_URL` - Your CompreFace instance URL
- `NEXT_PUBLIC_COMPREFACE_API_KEY` - CompreFace API key

### Blockchain Configuration (for wallet features)
- `NEXT_PUBLIC_CHAIN_ID` - Target blockchain network
- `NEXT_PUBLIC_RPC_URL` - RPC endpoint for blockchain
- Contract addresses for deployed smart contracts

## Deployment Options

### Option 1: Railway CLI (Recommended)
```bash
railway up
```

### Option 2: GitHub Integration
1. Push to GitHub repository
2. Connect repository in Railway dashboard
3. Configure environment variables
4. Deploy automatically on commits

### Option 3: Docker
```bash
# Build Docker image
docker build -t ease-dapp .

# Run locally to test
docker run -p 3000:3000 ease-dapp
```

## Notes

- The app will be available at your Railway-provided domain
- Update `NEXTAUTH_URL` environment variable with your Railway domain
- Ensure CompreFace service is accessible from Railway
- Configure CORS on CompreFace to allow your Railway domain