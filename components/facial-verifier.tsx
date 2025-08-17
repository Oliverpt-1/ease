'use client'

import { useState } from 'react'
import { sepolia } from 'viem/chains'
import { createPublicClient, createWalletClient, http, parseAbi } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'

interface FacialVerifierProps {
  sourceEmbedding: number[]
  targetEmbedding: number[]
  onResult?: (result: string) => void
}

const FacialVerifier = ({ sourceEmbedding, targetEmbedding, onResult }: FacialVerifierProps) => {
  const [isLoading, setIsLoading] = useState(false)
  const [result, setResult] = useState<string>('')
  const [error, setError] = useState<string>('')

  const CHAINLINK_CONTRACT = '0xb0E7ceeA189C96dBFf02aC7819699Dcf1F81b95b'
  const SUBSCRIPTION_ID = 5463

  const chainlinkAbi = parseAbi([
    'function sendRequest(uint64 subscriptionId, string[] calldata args) external returns (bytes32 requestId)',
    'function verificationResult() external view returns (string)',
    'function s_lastResponse() external view returns (bytes)',
    'function s_lastError() external view returns (bytes)'
  ])

  const runVerification = async () => {
    setIsLoading(true)
    setError('')
    setResult('')

    try {
      console.log('🧪 Running facial verification...')
      
      const publicClient = createPublicClient({
        chain: sepolia,
        transport: http('https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF'),
      })

      // Create wallet client with owner's private key
      const account = privateKeyToAccount(`0x6fddd15647f0bfe65a1b1abac121b1b71c1d3349b257595cde7b816a89029561`)
      const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http('https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF'),
      })

      // Convert embeddings to JSON strings (what Chainlink expects)
      const sourceJson = JSON.stringify(sourceEmbedding)
      const targetJson = JSON.stringify([targetEmbedding]) // Targets is array of arrays
      
      console.log('📤 Source embedding:', sourceJson)
      console.log('📤 Target embedding:', targetJson)

      // Call the Chainlink contract with wallet client (write function)
      const hash = await walletClient.writeContract({
        address: CHAINLINK_CONTRACT,
        abi: chainlinkAbi,
        functionName: 'sendRequest',
        args: [BigInt(SUBSCRIPTION_ID), [sourceJson, targetJson]]
      })

      console.log('📋 Transaction hash:', hash)
      
      // Wait for transaction confirmation
      const receipt = await publicClient.waitForTransactionReceipt({ hash })
      console.log('✅ Transaction confirmed:', receipt)

      setResult('Transaction confirmed. Waiting for Chainlink response...')

      // Poll for result
      let attempts = 0
      const maxAttempts = 30 // 30 seconds max wait
      
      while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 1000)) // Wait 1 second
        
        try {
          const verificationResult = await publicClient.readContract({
            address: CHAINLINK_CONTRACT,
            abi: chainlinkAbi,
            functionName: 'verificationResult'
          })

          if (verificationResult && verificationResult.trim() !== '') {
            console.log('✅ Got result:', verificationResult)
            const finalResult = `Verification Result: ${verificationResult}`
            setResult(finalResult)
            onResult?.(verificationResult)
            break
          }
        } catch (err) {
          console.log('⏳ Still waiting for result...')
        }
        
        attempts++
      }

      if (attempts >= maxAttempts) {
        setResult('Timeout waiting for response')
      }

    } catch (err: any) {
      console.error('❌ Verification failed:', err)
      setError(`Verification failed: ${err.message}`)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="p-4 bg-gray-50 rounded-lg">
      <h3 className="text-lg font-semibold mb-4">🔗 Chainlink Facial Verification</h3>
      
      <div className="space-y-3 mb-4">
        <div className="text-sm">
          <span className="font-medium">Source Embedding:</span> {sourceEmbedding.slice(0, 5).join(', ')}... (length: {sourceEmbedding.length})
        </div>
        <div className="text-sm">
          <span className="font-medium">Target Embedding:</span> {targetEmbedding.slice(0, 5).join(', ')}... (length: {targetEmbedding.length})
        </div>
      </div>

      <button
        onClick={runVerification}
        disabled={isLoading}
        className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
      >
        {isLoading ? '⏳ Verifying...' : '🔍 Run Facial Verification'}
      </button>

      {result && (
        <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-lg">
          <p className="text-green-700 text-sm">{result}</p>
        </div>
      )}

      {error && (
        <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-red-700 text-sm">{error}</p>
        </div>
      )}
    </div>
  )
}

export default FacialVerifier