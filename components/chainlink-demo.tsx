'use client'

import { useState } from 'react'
import { sepolia } from 'viem/chains'
import { createPublicClient, createWalletClient, http, parseAbi } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'

const ChainlinkDemo = () => {
  const [isLoading, setIsLoading] = useState(false)
  const [result, setResult] = useState<string>('')
  const [error, setError] = useState<string>('')

  // Hardcoded facial embeddings for demo
  const DEMO_EMBEDDING_1 = [1068711, 1023903, 955547, 1040324, 1022124, 1048649, 955901, 1091652, 995566, 979351] // Sample face 1
  const DEMO_EMBEDDING_2 = [1068711, 1023903, 955547, 1040324, 1022124, 1048649, 955901, 1091652, 995566, 979351] // Same face (should match)
  const DEMO_EMBEDDING_3 = [-100,-200,5,34,5,1,6,8,9,1000] // Different face (should not match)

  const CHAINLINK_CONTRACT = '0xb0E7ceeA189C96dBFf02aC7819699Dcf1F81b95b'
  const SUBSCRIPTION_ID = 5463

  const chainlinkAbi = parseAbi([
    'function sendRequest(uint64 subscriptionId, string[] calldata args) external returns (bytes32 requestId)',
    'function verificationResult() external view returns (string)',
    'function s_lastResponse() external view returns (bytes)',
    'function s_lastError() external view returns (bytes)'
  ])

  const testSameFace = async () => {
    await runTest(DEMO_EMBEDDING_1, DEMO_EMBEDDING_2, "Same Face Test")
  }

  const testDifferentFace = async () => {
    await runTest(DEMO_EMBEDDING_1, DEMO_EMBEDDING_3, "Different Face Test")
  }

  const runTest = async (sourceEmbedding: number[], targetEmbedding: number[], testName: string) => {
    setIsLoading(true)
    setError('')
    setResult('')

    try {
      console.log(`🧪 Running ${testName}...`)
      
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

      setResult(`${testName}: Transaction confirmed. Waiting for Chainlink response...`)

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
            setResult(`${testName} Result: ${verificationResult}`)
            break
          }
        } catch (err) {
          console.log('⏳ Still waiting for result...')
        }
        
        attempts++
      }

      if (attempts >= maxAttempts) {
        setResult(`${testName}: Timeout waiting for response`)
      }

    } catch (err: any) {
      console.error('❌ Test failed:', err)
      setError(`${testName} failed: ${err.message}`)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="p-6 max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold mb-6">Chainlink Facial Verification Demo</h2>
      
      <div className="space-y-4 mb-6">
        <div className="p-4 bg-green-50 rounded-lg border border-green-200">
          <h3 className="font-semibold text-green-800">Test Overview</h3>
          <p className="text-green-700">
            This demo directly calls the Chainlink facial verification contract with hardcoded embeddings 
            to prove the CompreFace API integration works.
          </p>
        </div>

        <div className="flex justify-center">
          <button
            onClick={testSameFace}
            disabled={isLoading}
            className="px-8 py-4 bg-blue-100 text-blue-800 border border-blue-300 rounded-lg hover:bg-blue-200 disabled:opacity-50 transition-colors"
          >
            {isLoading ? 'Testing...' : 'Test Facial Verification'}
          </button>
        </div>
      </div>

      {result && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-lg mb-4">
          <h3 className="font-semibold text-green-800">Result</h3>
          <p className="text-green-700">{result}</p>
        </div>
      )}

      {error && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
          <h3 className="font-semibold text-green-800">Error</h3>
          <p className="text-green-700">{error}</p>
        </div>
      )}

      <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg text-sm">
        <h3 className="font-semibold text-green-800">Technical Details</h3>
        <ul className="text-green-700 mt-2 space-y-1">
          <li>• Chainlink Contract: {CHAINLINK_CONTRACT}</li>
          <li>• Subscription ID: {SUBSCRIPTION_ID}</li>
          <li>• CompreFace API: Railway Production Endpoint</li>
          <li>• Network: Ethereum Sepolia Testnet</li>
        </ul>
      </div>
    </div>
  )
}

export default ChainlinkDemo