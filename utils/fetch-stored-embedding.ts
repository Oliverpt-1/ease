import { createPublicClient, http, parseAbi, decodeAbiParameters } from 'viem'
import { sepolia } from 'viem/chains'

const VALIDATOR_ADDRESS = '0xAAB9f7d4aAF5B4aa4A4bdDD35b19CC6b5DC7733C'

const validatorAbi = parseAbi([
  'function userData(address) external view returns (bytes32, bytes, string, uint256, bool, uint256)'
])

export async function fetchStoredEmbedding(walletAddress: string): Promise<number[] | null> {
  try {
    const publicClient = createPublicClient({
      chain: sepolia,
      transport: http('https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF'),
    })

    console.log('🔍 Fetching stored embedding for wallet:', walletAddress)

    const userData = await publicClient.readContract({
      address: VALIDATOR_ADDRESS,
      abi: validatorAbi,
      functionName: 'userData',
      args: [walletAddress as `0x${string}`]
    })

    console.log('📋 Raw user data:', userData)

    // userData is a tuple: [facialHash, encodedEmbedding, username, index, isRegistered, registrationTimestamp]
    const [facialHash, encodedEmbedding, username, index, isRegistered, registrationTimestamp] = userData

    if (!isRegistered) {
      console.log('❌ User not registered')
      return null
    }

    console.log('✅ User is registered:', username)
    console.log('📊 Encoded embedding length:', encodedEmbedding.length)

    // Decode the ABI-encoded embedding
    try {
      // The encodedEmbedding is abi.encode(uint256[])
      const decodedEmbedding = decodeAbiParameters(
        [{ type: 'uint256[]' }],
        encodedEmbedding as `0x${string}`
      )[0]
      
      console.log('📊 Decoded embedding length:', decodedEmbedding.length)
      console.log('📊 First 10 values:', decodedEmbedding.slice(0, 10))

      // Convert BigInt array to number array
      const embeddingArray = decodedEmbedding.map((val: any) => Number(val))
      
      return embeddingArray
    } catch (error) {
      console.error('❌ Failed to decode embedding:', error)
      return null
    }

  } catch (error) {
    console.error('❌ Failed to fetch stored embedding:', error)
    return null
  }
}

export function getWalletAddressFromEns(ensName: string): string {
  // For demo purposes, we'll use the known wallet addresses
  // In production, you'd resolve ENS to wallet address
  const knownWallets: Record<string, string> = {
    'deezes.eaze.eth': '0xc58d2e140971c90a573476b187B5B9A5b93b9850',
    'testuser.eaze.eth': '0x87633b131267AAF4950390f8baFd54e292B640fa',
    // Add more as needed
  }

  return knownWallets[ensName] || ''
}