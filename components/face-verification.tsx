"use client"

import { useState, useRef, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { useCompreface } from "@/components/use-compreface"
import { useWalletClient } from "@/components/use-wallet-client"
import { ArrowLeft, Camera, CheckCircle } from "lucide-react"
import { createPublicClient, http, parseAbi, encodePacked } from 'viem'
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
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  
  const { recognize, loading } = useCompreface()
  const { createWalletClient, sendPayment } = useWalletClient()

  // Effect to connect stream to video element when both are available
  useEffect(() => {
    if (stream && videoRef.current) {
      const video = videoRef.current
      video.srcObject = stream
      video.play().catch(() => {})
    }
  }, [stream])

  const startCamera = async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { 
          facingMode: "user",
          width: { ideal: 640 },
          height: { ideal: 480 }
        }
      })
      setStream(mediaStream)
    } catch (error) {
      console.error("Error accessing camera:", error)
    }
  }

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop())
      setStream(null)
    }
  }

  const captureImage = (): Promise<Blob | null> => {
    return new Promise((resolve) => {
      if (!videoRef.current || !canvasRef.current) {
        resolve(null)
        return
      }

      const video = videoRef.current
      const canvas = canvasRef.current
      const ctx = canvas.getContext('2d')
      
      if (!ctx || video.readyState < video.HAVE_CURRENT_DATA) {
        resolve(null)
        return
      }

      canvas.width = video.videoWidth || 640
      canvas.height = video.videoHeight || 480
      
      try {
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      } catch (drawError) {
        resolve(null)
        return
      }

      canvas.toBlob((blob) => {
        resolve(blob)
      }, 'image/jpeg', 0.8)
    })
  }

  const handleVerification = async () => {
    setIsVerifying(true)

    try {
      // Capture image and wait for it
      const imageBlob = await captureImage()
      
      if (imageBlob) {
        // Get embedding
        const recognizeResult = await recognize(imageBlob)
        
        if (recognizeResult.result?.[0]?.embedding) {
          console.log('EMBEDDING:', recognizeResult.result[0].embedding)
        }

        const embedding = recognizeResult.result[0].embedding
        console.log('FRESH EMBEDDING FOR PAYMENT:', embedding)

        // Test facial signature validation with REAL contract call
        console.log('🔍 Testing ACTUAL facial signature validation...')
        
        const publicClient = createPublicClient({
          chain: sepolia,
          transport: http('https://eth-sepolia.g.alchemy.com/v2/TAna5TyVIgrgtMUxfEYgF'),
        })

        // Get the wallet address for this ENS name
        const FACTORY_ADDRESS = '0xBC7ae078641EF45B6601aa952E495703ddDC2f28'
        const VALIDATOR_ADDRESS = '0xAAB9f7d4aAF5B4aa4A4bdDD35b19CC6b5DC7733C'
        
        // Extract subdomain from full ENS name (e.g., "bro" from "bro.eaze.eth")
        const subdomain = ensName.split('.')[0]
        
        const walletAddress = await publicClient.readContract({
          address: FACTORY_ADDRESS as `0x${string}`,
          abi: parseAbi(['function subdomainToWallet(string) view returns (address)']),
          functionName: 'subdomainToWallet',
          args: [subdomain],
        })
        
        console.log(`📍 Wallet for ${ensName} (subdomain: ${subdomain}): ${walletAddress}`)
        
        if (walletAddress === '0x0000000000000000000000000000000000000000') {
          throw new Error(`❌ No wallet found for ENS name: ${ensName}`)
        }

        // Convert fresh embedding to contract format (shift to positive range)
        const embeddingBigInts = embedding.map(n => BigInt(Math.floor((n + 1) * 1000000)))
        
        // Encode embedding as signature data
        const encodedEmbedding = encodePacked(['uint256[]'], [embeddingBigInts])
        
        // Call testValidateFacialSignature to test actual Chainlink facial validation
        console.log('🔍 Calling ACTUAL facial validation with Chainlink...')
        console.log(`  - Wallet: ${walletAddress}`)
        console.log(`  - Validator: ${VALIDATOR_ADDRESS}`)
        
        const result = await publicClient.readContract({
          address: VALIDATOR_ADDRESS as `0x${string}`,
          abi: parseAbi(['function testValidateFacialSignature(address,bytes32,(bytes32,uint256,bytes)) returns (bool,string)']),
          functionName: 'testValidateFacialSignature',
          args: [
            walletAddress, 
            '0x0000000000000000000000000000000000000000000000000000000000000000',
            [
              '0x1234567890123456789012345678901234567890123456789012345678901234', // facial hash
              BigInt(Date.now()), // timestamp
              encodedEmbedding // fresh embedding
            ]
          ],
        }) as readonly [boolean, string]
        
        const validationResult = result[0]
        const chainlinkDebugResult = result[1]
        
        console.log(`📋 Validator result: ${validationResult}`)
        console.log(`🔗 Chainlink debug result: "${chainlinkDebugResult}"`)
        
        const isValid = validationResult === true
        
        if (!isValid) {
          console.log('❌ Validation failed - checking if user is registered...')
          throw new Error('❌ Facial signature validation FAILED - face does not match stored embedding')
        }
        
        console.log('✅ Facial signature validation PASSED!')
        console.log(`🎯 Contract returned: ${validationResult}`)
        console.log(`🧬 Embedding length: ${embedding.length} dimensions`)
        console.log(`📊 Wallet: ${walletAddress}`)

        // Create wallet client with ENS and fresh embedding
        await createWalletClient(ensName, embedding)
        
        // Send payment transaction
        const recipient = '0x742d35Cc6635C0532925a3b8D77f2A8e1E0e07b2' // Merchant address
        const amountInWei = BigInt(Math.floor(totalAmount * 100 * 10**16)) // Convert dollars to wei
        
        const txHash = await sendPayment(recipient, amountInWei)
        console.log('💰 Payment transaction:', txHash)

        // Success
        setIsVerifying(false)
        setIsVerified(true)
        stopCamera()

        setTimeout(() => {
          onVerificationComplete()
        }, 1500)
      }
    } catch (error) {
      console.error('Verification failed:', error)
      setIsVerifying(false)
      alert(`Verification failed: ${error instanceof Error ? error.message : 'Unknown error'}`)
    }
  }

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" onClick={onBack}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <CardTitle className="flex-1 text-center">Face Verification</CardTitle>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="text-center space-y-2">
          <p className="text-sm text-muted-foreground">Total Amount</p>
          <p className="text-3xl font-bold text-primary">${totalAmount.toFixed(2)}</p>
        </div>

        <div className="relative bg-muted rounded-lg overflow-hidden aspect-square">
          {stream ? (
            <video 
              ref={videoRef} 
              autoPlay 
              playsInline 
              muted 
              className="w-full h-full object-cover"
              style={{ transform: 'scaleX(-1)' }}
            />
          ) : (
            <div className="flex items-center justify-center h-full">
              <div className="text-center space-y-4">
                <Camera className="h-16 w-16 text-muted-foreground mx-auto" />
                <p className="text-muted-foreground">Camera not active</p>
              </div>
            </div>
          )}

          {isVerifying && (
            <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
              <div className="text-center text-white space-y-2">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white mx-auto"></div>
                <p>Verifying...</p>
              </div>
            </div>
          )}

          {isVerified && (
            <div className="absolute inset-0 bg-primary/90 flex items-center justify-center">
              <div className="text-center text-white space-y-2">
                <CheckCircle className="h-16 w-16 mx-auto" />
                <p className="text-lg font-semibold">Verified!</p>
              </div>
            </div>
          )}
        </div>

        <div className="space-y-4">
          <p className="text-center text-sm text-muted-foreground">
            Position your face in the camera frame and tap verify to complete payment
          </p>

          {!stream && !isVerified && (
            <Button onClick={startCamera} variant="outline" className="w-full bg-transparent">
              <Camera className="h-4 w-4 mr-2" />
              Start Camera
            </Button>
          )}

          {stream && !isVerifying && !isVerified && (
            <Button onClick={handleVerification} className="w-full" size="lg">
              Verify & Pay ${totalAmount.toFixed(2)}
            </Button>
          )}
        </div>

        {/* Hidden canvas for image capture */}
        <canvas ref={canvasRef} style={{ display: 'none' }} />
      </CardContent>
    </Card>
  )
}
