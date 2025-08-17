"use client"

import { useState, useRef, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useCompreface } from "@/components/use-compreface"
import { useWalletClient } from "@/components/use-wallet-client"
import { ArrowLeft, Camera, CheckCircle } from "lucide-react"

interface FaceVerificationProps {
  totalAmount: number
  onVerificationComplete: () => void
  onBack: () => void
}

export function FaceVerification({ totalAmount, onVerificationComplete, onBack }: FaceVerificationProps) {
  const [isVerifying, setIsVerifying] = useState<boolean>(false)
  const [isVerified, setIsVerified] = useState<boolean>(false)
  const [stream, setStream] = useState<MediaStream | null>(null)
  const [capturedImage, setCapturedImage] = useState<Blob | null>(null)
  const [ensName, setEnsName] = useState<string>("")
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  
  const { recognize, loading } = useCompreface()
  const { createWalletClient, sendPayment, loading: walletLoading, error: walletError } = useWalletClient()

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
    if (!ensName.trim()) {
      alert('Please enter your ENS name')
      return
    }

    setIsVerifying(true)

    try {
      // Capture image and get embedding
      const imageBlob = await captureImage()
      
      if (!imageBlob) {
        throw new Error('Failed to capture image')
      }

      const result = await recognize(imageBlob)
      
      if (!result.result?.[0]?.embedding) {
        throw new Error('Failed to get facial embedding')
      }

      const embedding = result.result[0].embedding
      console.log('EMBEDDING:', embedding)

      // Create wallet client with ENS and embedding
      await createWalletClient(ensName, embedding)
      
      // Send payment transaction
      const recipient = '0x742d35Cc6635C0532925a3b8D77f2A8e1E0e07b2' // Merchant address
      const amountInWei = BigInt(Math.floor(totalAmount * 100 * 10**16)) // Convert dollars to wei
      
      const txHash = await sendPayment(recipient, amountInWei)
      console.log('Payment transaction:', txHash)

      // Success
      setIsVerifying(false)
      setIsVerified(true)
      stopCamera()

      setTimeout(() => {
        onVerificationComplete()
      }, 1500)

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
          <div className="space-y-2">
            <Label htmlFor="ensName">ENS Name</Label>
            <Input
              id="ensName"
              type="text"
              placeholder="alice.ourapp.eth"
              value={ensName}
              onChange={(e) => setEnsName(e.target.value)}
              disabled={isVerifying || isVerified}
            />
          </div>

          <p className="text-center text-sm text-muted-foreground">
            Enter your ENS name and position your face in the camera frame to complete payment
          </p>

          {walletError && (
            <p className="text-center text-sm text-red-500">
              {walletError}
            </p>
          )}

          {!stream && !isVerified && (
            <Button onClick={startCamera} variant="outline" className="w-full bg-transparent">
              <Camera className="h-4 w-4 mr-2" />
              Start Camera
            </Button>
          )}

          {stream && !isVerifying && !isVerified && (
            <Button 
              onClick={handleVerification} 
              className="w-full" 
              size="lg"
              disabled={!ensName.trim() || loading || walletLoading}
            >
              {loading || walletLoading ? 'Processing...' : `Verify & Pay $${totalAmount.toFixed(2)}`}
            </Button>
          )}
        </div>

        {/* Hidden canvas for image capture */}
        <canvas ref={canvasRef} style={{ display: 'none' }} />
      </CardContent>
    </Card>
  )
}
