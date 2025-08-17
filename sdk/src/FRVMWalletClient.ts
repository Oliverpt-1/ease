import { createPublicClient, http, keccak256, toHex, encodeFunctionData, computeCreate2Address, parseAbi } from 'viem'
import { sepolia } from 'viem/chains' // Assume Sepolia for example; replace with your chain
import { toSmartAccount } from 'viem/account-abstraction'
import { createSmartAccountClient } from 'permissionless'
import { entryPoint07Address, entryPoint07Abi } from 'viem/account-abstraction'
import { createPimlicoClient } from 'permissionless/clients/pimlico'

// Constants (replace with actual deployed addresses)
const KERNEL_FACTORY_ADDRESS = '0x...YourFactoryAddress...' // WalletFactoryAndResolver address
const KERNEL_IMPLEMENTATION_ADDRESS = '0x...KernelImplAddress...'
const FACIAL_VALIDATOR_ADDRESS = '0x...FacialRecognitionValidatorAddress...'
const ROOT_ENS_NAME = 'ourapp.eth' // Root domain for subdomains

// ABI snippets for relevant functions
const factoryAbi = parseAbi([
  'function createWallet(bytes calldata facialMatrix, string calldata username, uint256 index) external returns (address)',
])
const kernelAbi = parseAbi([
  'function execute(address to, uint256 value, bytes calldata data, uint8 operation) external',
  // Add more if needed for batch, etc.
])
const entryPointAbi = entryPoint07Abi // From viem

// Placeholder function to get facial matrix (e.g., from biometric scan)
// In real app, this would integrate with facial recognition software
async function getFacialMatrix() {
  // Simulate getting matrix; return as Uint8Array
  return new Uint8Array([/* facial matrix bytes */]) // Replace with actual logic
}

// Function to create the wallet client using ENS subdomain
async function createWalletClientUsingENS(username: string, bundlerUrl: string, paymasterUrl: string, apiKey: string) {
  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(),
  })

  // Resolve ENS subdomain to wallet address
  const ensName = `${username}.${ROOT_ENS_NAME}`
  let walletAddress = await publicClient.resolveName({ name: ensName })

  if (walletAddress === '0x0000000000000000000000000000000000000000') {
    throw new Error('Wallet not deployed or ENS not set')
    // Optionally, handle creation here if needed
  }

  // Create custom smart account with facial validator
  const account = await toSmartAccount({
    client: publicClient,
    entryPoint: {
      address: entryPoint07Address,
      version: '0.7',
      abi: entryPointAbi,
    },
    async getAddress() {
      return walletAddress
    },
    async encodeCalls(calls) {
      // For Kernel, encode as execute or batch
      if (calls.length === 1) {
        const { to, value = 0n, data = '0x' } = calls[0]
        return encodeFunctionData({
          abi: kernelAbi,
          functionName: 'execute',
          args: [to, value, data, 0], // operation 0 for call
        })
      } else {
        // Handle batch if needed
        throw new Error('Batch calls not implemented')
      }
    },
    async decodeCalls(data) {
      // Decode Kernel execute calldata
      // Implement if needed for your app
      return [] // Placeholder
    },
    async getNonce({ key } = {}) {
      // Use entryPoint getNonce
      return await publicClient.readContract({
        address: entryPoint07Address,
        abi: entryPointAbi,
        functionName: 'getNonce',
        args: [walletAddress, key ?? 0n],
      })
    },
    async getStubSignature() {
      // For facial validator, stub can be empty or fixed
      return '0x'
    },
    async signUserOperation(userOperation) {
      const facialMatrix = await getFacialMatrix()
      return {
        ...userOperation,
        signature: toHex(facialMatrix),
      }
    },
    async signMessage({ message }) {
      // For EIP-1271, but since custom, perhaps hash message and sign with matrix
      const facialMatrix = await getFacialMatrix()
      return toHex(facialMatrix) // Placeholder; adjust based on validator's isValidSignature
    },
    async signTypedData(typedData) {
      // Similar placeholder
      const facialMatrix = await getFacialMatrix()
      return toHex(facialMatrix)
    },
    // If needed for deployment
    async getFactoryArgs() {
      // If not deployed, provide initCode args
      // But since we assume deployed, throw error or handle
      throw new Error('Wallet must be deployed first')
    },
  })

  // Optional: Pimlico bundler and paymaster
  const pimlicoClient = createPimlicoClient({
    transport: http(`${PIMLICO_BUNDLER_URL}?apikey=${PIMLICO_API_KEY}`),
    entryPoint: {
      address: entryPoint07Address,
      version: '0.7',
    },
  })

  // Create the smart account client
  const walletClient = createSmartAccountClient({
    account,
    chain: sepolia,
    bundlerTransport: http(`${bundlerUrl}?apikey=${apiKey}`),
    middleware: {
      sponsorUserOperation: pimlicoClient.sponsorUserOperation,
      gasPrice: async () => (await pimlicoClient.getUserOperationGasPrice()).fast,
    },
  })

  return walletClient
}

// Example usage to sign in / send a transaction on behalf of the user
async function exampleSignIn(username: string) {
  const walletClient = await createWalletClientUsingENS(
    username,
    'https://api.pimlico.io/v2/sepolia/rpc',
    'https://api.pimlico.io/v2/sepolia/rpc',
    'PIMLICO-API-KEY'
  )

  // Now, send a transaction (which will prompt facial scan in getFacialMatrix)
  const txHash = await walletClient.sendTransaction({
    to: '0x...recipient...',
    value: 0n,
    data: '0x',
  })

  console.log('Transaction hash:', txHash)

}