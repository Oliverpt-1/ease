"use client"

import { createPublicClient, http, toHex, encodeFunctionData, parseAbi } from 'viem'
import { sepolia } from 'viem/chains'
import { toSmartAccount } from 'viem/account-abstraction'
import { createSmartAccountClient } from 'permissionless'
import { entryPoint07Address, entryPoint07Abi } from 'viem/account-abstraction'
import { createPimlicoClient } from 'permissionless/clients/pimlico'
import { useState, useCallback } from 'react'

// Constants (replace with actual deployed addresses)
const KERNEL_FACTORY_ADDRESS = '0x...YourFactoryAddress...'
const KERNEL_IMPLEMENTATION_ADDRESS = '0x...KernelImplAddress...'
const FACIAL_VALIDATOR_ADDRESS = '0x...FacialRecognitionValidatorAddress...'
const ROOT_ENS_NAME = 'ease.eth'

// ABI snippets
const factoryAbi = parseAbi([
  'function createWallet(uint256[] calldata facialEmbedding, string calldata username, uint256 index) external returns (address)',
])
const kernelAbi = parseAbi([
  'function execute(address to, uint256 value, bytes calldata data, uint8 operation) external',
])

interface UseWalletClientReturn {
  createWalletClient: (username: string, facialEmbedding: number[]) => Promise<any>
  sendPayment: (recipient: string, amount: bigint) => Promise<string>
  loading: boolean
  error: string | null
}

export function useWalletClient(): UseWalletClientReturn {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [currentClient, setCurrentClient] = useState<any>(null)
  const [currentEmbedding, setCurrentEmbedding] = useState<number[]>([])

  const createWalletClient = useCallback(async (username: string, facialEmbedding: number[]) => {
    setLoading(true)
    setError(null)
    setCurrentEmbedding(facialEmbedding)

    try {
      const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(),
      })

      // Resolve ENS subdomain to wallet address
      const ensName = `${username}.${ROOT_ENS_NAME}`
      const walletAddress = await publicClient.getEnsAddress({ name: ensName })

      if (!walletAddress) {
        throw new Error('Wallet not deployed or ENS not set')
      }

      // Create custom smart account with facial validator
      const account = await toSmartAccount({
        client: publicClient,
        entryPoint: {
          address: entryPoint07Address,
          version: '0.7',
          abi: entryPoint07Abi,
        },
        async getAddress() {
          return walletAddress
        },
        async encodeCalls(calls) {
          if (calls.length === 1) {
            const { to, value = BigInt(0), data = '0x' } = calls[0]
            return encodeFunctionData({
              abi: kernelAbi,
              functionName: 'execute',
              args: [to, value, data, 0],
            })
          } else {
            throw new Error('Batch calls not implemented')
          }
        },
        async decodeCalls() {
          return []
        },
        async getNonce({ key } = {}) {
          return await publicClient.readContract({
            address: entryPoint07Address,
            abi: entryPoint07Abi,
            functionName: 'getNonce',
            args: [walletAddress, key ?? BigInt(0)],
          })
        },
        async getStubSignature() {
          return '0x'
        },
        async signUserOperation() {
          // Use the stored facial embedding for signature
          const facialMatrix = new Uint8Array(facialEmbedding.map(n => Math.floor(n * 255)))
          return toHex(facialMatrix)
        },
        async signMessage() {
          const facialMatrix = new Uint8Array(facialEmbedding.map(n => Math.floor(n * 255)))
          return toHex(facialMatrix)
        },
        async signTypedData() {
          const facialMatrix = new Uint8Array(facialEmbedding.map(n => Math.floor(n * 255)))
          return toHex(facialMatrix)
        },
        async getFactoryArgs() {
          throw new Error('Wallet must be deployed first')
        },
      })

      // Create Pimlico client
      const pimlicoClient = createPimlicoClient({
        transport: http(`https://api.pimlico.io/v2/sepolia/rpc?apikey=${process.env.NEXT_PUBLIC_PIMLICO_API_KEY}`),
        entryPoint: {
          address: entryPoint07Address,
          version: '0.7',
        },
      })

      // Create the smart account client
      const walletClient = createSmartAccountClient({
        account,
        chain: sepolia,
        bundlerTransport: http(`https://api.pimlico.io/v2/sepolia/rpc?apikey=${process.env.NEXT_PUBLIC_PIMLICO_API_KEY}`),
        userOperation: {
          estimateFeesPerGas: async () => (await pimlicoClient.getUserOperationGasPrice()).fast,
        },
      })

      setCurrentClient(walletClient)
      return walletClient

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to create wallet client'
      setError(errorMessage)
      throw new Error(errorMessage)
    } finally {
      setLoading(false)
    }
  }, [])

  const sendPayment = useCallback(async (recipient: string, amount: bigint) => {
    if (!currentClient) {
      throw new Error('Wallet client not initialized')
    }

    setLoading(true)
    setError(null)

    try {
      const txHash = await currentClient.sendTransaction({
        to: recipient,
        value: amount,
        data: '0x',
      })

      return txHash
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Payment failed'
      setError(errorMessage)
      throw new Error(errorMessage)
    } finally {
      setLoading(false)
    }
  }, [currentClient])

  return {
    createWalletClient,
    sendPayment,
    loading,
    error,
  }
}