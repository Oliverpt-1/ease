'use client'

import { useState } from 'react'
import { fetchStoredEmbedding, getWalletAddressFromEns } from '@/utils/fetch-stored-embedding'
import FacialVerifier from './facial-verifier'

const RealFacialDemo = () => {
  const [ensName, setEnsName] = useState('')
  const [storedEmbedding, setStoredEmbedding] = useState<number[] | null>(null)
  const [freshEmbedding, setFreshEmbedding] = useState<number[] | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  // Sample fresh embedding (in real app, this would come from camera/CompreFace)
  const SAMPLE_FRESH_EMBEDDING = [1068711, 1023903, 955547, 1040324, 1022124, 1048649, 955901, 1091652, 995566, 979351]
  const DIFFERENT_FRESH_EMBEDDING = [900000, 850000, 800000, 750000, 700000, 650000, 600000, 550000, 500000, 450000]

  const fetchUserEmbedding = async () => {
    setIsLoading(true)
    setError('')
    setStoredEmbedding(null)
    
    try {
      const walletAddress = getWalletAddressFromEns(ensName)
      if (!walletAddress) {
        throw new Error('Unknown ENS name')
      }

      console.log('🔍 Fetching embedding for:', ensName, '→', walletAddress)
      const embedding = await fetchStoredEmbedding(walletAddress)
      
      if (!embedding) {
        throw new Error('No embedding found for this user')
      }

      setStoredEmbedding(embedding)
      console.log('✅ Successfully fetched stored embedding:', embedding.length, 'values')
      
    } catch (err: any) {
      console.error('❌ Error:', err)
      setError(err.message)
    } finally {
      setIsLoading(false)
    }
  }

  const useSameEmbedding = () => {
    if (storedEmbedding) {
      // Use first 10 values of stored embedding as "fresh" (simulates same person)
      setFreshEmbedding(storedEmbedding.slice(0, 10))
    }
  }

  const useDifferentEmbedding = () => {
    setFreshEmbedding(DIFFERENT_FRESH_EMBEDDING)
  }

  const useSampleEmbedding = () => {
    setFreshEmbedding(SAMPLE_FRESH_EMBEDDING)
  }

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h2 className="text-2xl font-bold mb-6">👤 Real User Facial Verification Demo</h2>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left side: Fetch stored embedding */}
        <div className="space-y-4">
          <div className="p-4 bg-blue-50 rounded-lg">
            <h3 className="font-semibold text-blue-800 mb-3">Step 1: Fetch Stored Embedding</h3>
            
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  ENS Name:
                </label>
                <input
                  type="text"
                  value={ensName}
                  onChange={(e) => setEnsName(e.target.value)}
                  placeholder="e.g., deezes.eaze.eth"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
                <div className="mt-2 text-xs text-gray-500">
                  Known wallets: deezes.eaze.eth, testuser.eaze.eth
                </div>
              </div>

              <button
                onClick={fetchUserEmbedding}
                disabled={isLoading}
                className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
              >
                {isLoading ? '⏳ Fetching...' : '📥 Fetch Stored Embedding'}
              </button>

              {storedEmbedding && (
                <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded-lg">
                  <p className="text-green-800 font-medium">✅ Stored Embedding Retrieved</p>
                  <p className="text-green-700 text-sm">
                    Length: {storedEmbedding.length} values
                  </p>
                  <p className="text-green-700 text-sm">
                    First 5: [{storedEmbedding.slice(0, 5).join(', ')}...]
                  </p>
                </div>
              )}

              {error && (
                <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-red-700 text-sm">{error}</p>
                </div>
              )}
            </div>
          </div>

          {/* Step 2: Set fresh embedding */}
          <div className="p-4 bg-green-50 rounded-lg">
            <h3 className="font-semibold text-green-800 mb-3">Step 2: Set Fresh Embedding</h3>
            <p className="text-green-700 text-sm mb-3">
              In real app, this would come from camera. For demo, choose:
            </p>
            
            <div className="space-y-2">
              <button
                onClick={useSameEmbedding}
                disabled={!storedEmbedding}
                className="w-full px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 text-sm"
              >
                ✅ Use Same Person (Should Match)
              </button>
              
              <button
                onClick={useSampleEmbedding}
                className="w-full px-3 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 text-sm"
              >
                🤔 Use Sample Embedding
              </button>
              
              <button
                onClick={useDifferentEmbedding}
                className="w-full px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
              >
                ❌ Use Different Person (Should Not Match)
              </button>
            </div>

            {freshEmbedding && (
              <div className="mt-3 p-3 bg-white border border-green-200 rounded-lg">
                <p className="text-green-800 font-medium">📱 Fresh Embedding Set</p>
                <p className="text-green-700 text-sm">
                  Length: {freshEmbedding.length} values
                </p>
                <p className="text-green-700 text-sm">
                  Values: [{freshEmbedding.slice(0, 5).join(', ')}...]
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Right side: Facial verification */}
        <div>
          <div className="p-4 bg-purple-50 rounded-lg">
            <h3 className="font-semibold text-purple-800 mb-3">Step 3: Run Verification</h3>
            
            {storedEmbedding && freshEmbedding ? (
              <FacialVerifier 
                sourceEmbedding={storedEmbedding}
                targetEmbedding={freshEmbedding}
                onResult={(result) => {
                  console.log('🎯 Verification complete:', result)
                }}
              />
            ) : (
              <div className="p-4 bg-gray-100 rounded-lg text-center">
                <p className="text-gray-600">
                  Complete steps 1 & 2 to enable verification
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="mt-6 p-4 bg-gray-50 rounded-lg text-sm">
        <h3 className="font-semibold text-gray-800">How This Works</h3>
        <ol className="text-gray-600 mt-2 space-y-1 list-decimal list-inside">
          <li>Fetch the user's stored facial embedding from the validator contract</li>
          <li>Simulate getting a fresh embedding from camera/CompreFace</li>
          <li>Send both embeddings to Chainlink for verification via CompreFace API</li>
          <li>Get similarity score back - proving the full flow works!</li>
        </ol>
      </div>
    </div>
  )
}

export default RealFacialDemo