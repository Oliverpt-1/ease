"use client"

import { useState, useRef, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { useCompreface } from "@/components/use-compreface"
import { useWalletClient } from "@/components/use-wallet-client"
import { fetchStoredEmbedding } from "@/utils/fetch-stored-embedding"
import { ArrowLeft, Camera, CheckCircle } from "lucide-react"
import { createPublicClient, createWalletClient, http, parseAbi } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { sepolia } from 'viem/chains'

interface FaceVerificationProps {
  totalAmount: number
  onVerificationComplete: () => void
  onBack: () => void
  ensName: string
}

export function FaceVerification({ totalAmount, onVerificationComplete, onBack, ensName }: FaceVerificationProps) {
  const [isVerifying, setIsVerifying] = useState<boolean>(false)
  const [isVerified, setIsVerified] = useState<boolean>(false)
  const [stream, setStream] = useState<MediaStream | null>(null)
  const [capturedImage, setCapturedImage] = useState<Blob | null>(null)
  const [freshEmbedding, setFreshEmbedding] = useState<number[] | null>(null)
  const [storedEmbedding, setStoredEmbedding] = useState<number[] | null>(null)
  const [verificationStep, setVerificationStep] = useState<'camera' | 'processing' | 'verifying' | 'complete'>('camera')
  const [verificationResult, setVerificationResult] = useState<string>('')
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  
  const { recognize } = useCompreface()
  const { createWalletClient: createWallet, sendPayment } = useWalletClient()

  // Effect to connect stream to video element when both are available
  useEffect(() => {
    if (stream && videoRef.current) {
      videoRef.current.srcObject = stream
    }
  }, [stream])

  // Cleanup camera stream on unmount
  useEffect(() => {
    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop())
      }
    }
  }, [stream])

  const startCamera = async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({ 
        video: { width: 640, height: 480 } 
      })
      setStream(mediaStream)
    } catch (error) {
      console.error('Error accessing camera:', error)
    }
  }

  const captureImage = (): Promise<Blob | null> => {
    return new Promise((resolve) => {
      if (!videoRef.current || !canvasRef.current) {
        resolve(null)
        return
      }

      const canvas = canvasRef.current
      const video = videoRef.current
      const context = canvas.getContext('2d')
      
      if (!context) {
        resolve(null)
        return
      }

      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      context.drawImage(video, 0, 0)
      
      canvas.toBlob((blob) => {
        setCapturedImage(blob)
        resolve(blob)
      }, 'image/jpeg', 0.8)
    })
  }

  const handleVerification = async () => {
    setIsVerifying(true)
    setVerificationStep('processing')

    try {
      console.log('🔍 Starting real facial verification for:', ensName)
      
      // Step 1: Capture image and get fresh embedding
      const imageBlob = await captureImage()
      if (!imageBlob) throw new Error('Failed to capture image')
      
      const recognizeResult = await recognize(imageBlob)
      if (!recognizeResult.result?.[0]?.embedding) {
        throw new Error('Failed to get facial embedding from image')
      }

      const freshEmbedding = recognizeResult.result[0].embedding
      setFreshEmbedding(freshEmbedding)
      console.log('✅ Fresh embedding captured:', freshEmbedding.slice(0, 5))

      // Step 2: Get wallet address from ENS
      const publicClient = createPublicClient({
        chain: sepolia,
        transport: http('https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF'),
      })

      const FACTORY_ADDRESS = '0xBC7ae078641EF45B6601aa952E495703ddDC2f28'
      const subdomain = ensName.split('.')[0]
      
      const walletAddress = await publicClient.readContract({
        address: FACTORY_ADDRESS as `0x${string}`,
        abi: parseAbi(['function subdomainToWallet(string) view returns (address)']),
        functionName: 'subdomainToWallet',
        args: [subdomain],
      }) as string
      
      console.log(`📍 Wallet for ${ensName}: ${walletAddress}`)
      
      if (walletAddress === '0x0000000000000000000000000000000000000000') {
        throw new Error(`No wallet found for ENS name: ${ensName}`)
      }

      // Step 3: Fetch stored embedding from validator contract
      const storedEmbedding = await fetchStoredEmbedding(walletAddress)
      if (!storedEmbedding) {
        throw new Error('No stored embedding found for this user')
      }
      
      setStoredEmbedding(storedEmbedding)
      console.log('✅ Stored embedding fetched:', storedEmbedding.slice(0, 5))

      // Step 4: Run Chainlink verification
      setVerificationStep('verifying')
      await runChainlinkVerification(storedEmbedding, freshEmbedding)

    } catch (error: any) {
      console.error('❌ Verification failed:', error)
      setVerificationResult(error.message)
      setVerificationStep('complete')
    } finally {
      setIsVerifying(false)
    }
  }

  const runChainlinkVerification = async (storedEmbedding: number[], freshEmbedding: number[]) => {
    try {
      const CHAINLINK_CONTRACT = '0xb0E7ceeA189C96dBFf02aC7819699Dcf1F81b95b'
      const SUBSCRIPTION_ID = 5463

      const publicClient = createPublicClient({
        chain: sepolia,
        transport: http('https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF'),
      })

      const account = privateKeyToAccount(`0x6fddd15647f0bfe65a1b1abac121b1b71c1d3349b257595cde7b816a89029561`)
      const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http('https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF'),
      })

      const chainlinkAbi = parseAbi([
        'function sendRequest(uint64 subscriptionId, string[] calldata args) external returns (bytes32 requestId)',
        'function verificationResult() external view returns (string)'
      ])

      // Convert embeddings to JSON strings
      const sourceJson = JSON.stringify(storedEmbedding)
      const targetJson = JSON.stringify([freshEmbedding])

      console.log('🔗 Sending to Chainlink for verification...')

      // Send request to Chainlink
      const hash = await walletClient.writeContract({
        address: CHAINLINK_CONTRACT,
        abi: chainlinkAbi,
        functionName: 'sendRequest',
        args: [BigInt(SUBSCRIPTION_ID), [sourceJson, targetJson]]
      })

      // Wait for transaction
      await publicClient.waitForTransactionReceipt({ hash })
      console.log('✅ Chainlink request sent')

      // Poll for result - increased timeout for Chainlink Functions
      let attempts = 0
      while (attempts < 60) {
        await new Promise(resolve => setTimeout(resolve, 2000))
        
        try {
          const result = await publicClient.readContract({
            address: CHAINLINK_CONTRACT,
            abi: chainlinkAbi,
            functionName: 'verificationResult'
          }) as string

          console.log(`🔍 Polling attempt ${attempts + 1}: result = "${result}"`)
          
          if (result && result.trim() !== '' && result !== '0x' && result !== '""') {
            console.log('🎯 Verification result:', result)
            const parsedResult = JSON.parse(result)
            const similarity = parsedResult.result?.[0]?.similarity || 0
            
            setVerificationResult(`Similarity: ${similarity}`)
            setIsVerified(similarity > 0.7) // Threshold for verification
            setVerificationStep('complete')
            
            if (similarity > 0.7) {
              setTimeout(() => onVerificationComplete(), 2000)
            }
            return
          }
        } catch (err) {
          console.log(`⏳ Waiting for Chainlink response... (attempt ${attempts + 1}/60)`)
        }
        
        attempts++
      }

      throw new Error('Timeout waiting for verification result')
      
    } catch (error) {
      console.error('❌ Chainlink verification failed:', error)
      throw error
    }
  }

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={onBack}>
            <ArrowLeft className="h-4 w-4" />
            Back
          </Button>
          <CardTitle>Face Verification</CardTitle>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="text-center">
          <div className="text-lg font-semibold">Payment: ${totalAmount.toFixed(2)}</div>
          <div className="text-sm text-gray-600">For: {ensName}</div>
        </div>

        {verificationStep === 'camera' && (
          <div className="space-y-4">
            <div className="relative aspect-video bg-gray-100 rounded-lg overflow-hidden">
              {!stream ? (
                <div className="flex items-center justify-center h-full">
                  <Button onClick={startCamera}>
                    <Camera className="h-4 w-4 mr-2" />
                    Start Camera
                  </Button>
                </div>
              ) : (
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  className="w-full h-full object-cover"
                />
              )}
            </div>
            
            {stream && (
              <Button 
                onClick={handleVerification} 
                disabled={isVerifying}
                className="w-full"
              >
                {isVerifying ? 'Verifying...' : 'Capture & Verify Face'}
              </Button>
            )}
          </div>
        )}

        {verificationStep === 'processing' && (
          <div className="text-center space-y-2">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
            <p>Processing facial recognition...</p>
          </div>
        )}

        {verificationStep === 'verifying' && (
          <div className="text-center space-y-2">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
            <p>Verifying with Chainlink...</p>
          </div>
        )}

        {verificationStep === 'complete' && (
          <div className="text-center space-y-4">
            {isVerified ? (
              <div className="text-green-600">
                <CheckCircle className="h-12 w-12 mx-auto mb-2" />
                <h3 className="text-lg font-semibold">Verification Successful!</h3>
                <p className="text-sm">{verificationResult}</p>
              </div>
            ) : (
              <div className="text-red-600">
                <div className="h-12 w-12 mx-auto mb-2 bg-red-100 rounded-full flex items-center justify-center">
                  ❌
                </div>
                <h3 className="text-lg font-semibold">Verification Failed</h3>
                <p className="text-sm">{verificationResult}</p>
              </div>
            )}
          </div>
        )}

        <canvas ref={canvasRef} className="hidden" />
      </CardContent>
    </Card>
  )
}