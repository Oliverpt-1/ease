"use client"

import { useState, useRef } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { toast } from "sonner"
import { Wallet, Camera, CheckCircle, Copy, QrCode, User } from "lucide-react"

const HAMMING_THRESHOLD = 0.6

interface WalletCreationProps {
  onWalletCreated?: (account: string) => void
}

interface BiometricEmbeddingResponse {
  embeddings: number[][]
}

interface WalletCreationState {
  status: 'idle' | 'capturing' | 'processing' | 'deploying' | 'registering' | 'completed'
  account?: string
  transactionHash?: string
  biometricHash?: string
  ensName?: string
  error?: string
}

async function captureFrame(): Promise<Blob> {
  const stream = await navigator.mediaDevices.getUserMedia({
    video: { facingMode: "user" }
  })
  
  const video = document.createElement('video')
  video.srcObject = stream
  video.play()
  
  return new Promise((resolve, reject) => {
    video.onloadedmetadata = () => {
      const canvas = document.createElement('canvas')
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      
      const ctx = canvas.getContext('2d')
      if (!ctx) {
        reject(new Error('Failed to get canvas context'))
        return
      }
      
      ctx.drawImage(video, 0, 0)
      
      // Stop the stream
      stream.getTracks().forEach(track => track.stop())
      
      canvas.toBlob((blob) => {
        if (blob) {
          resolve(blob)
        } else {
          reject(new Error('Failed to capture frame'))
        }
      }, 'image/jpeg', 0.8)
    }
  })
}

async function getBiometricEmbedding(imageBlob: Blob): Promise<BiometricEmbeddingResponse> {
  // TODO: Replace with actual CompreFace API endpoint
  // This should call the CompreFace embeddings endpoint:
  // POST {{compreface_base_url}}/api/v1/recognition/embeddings/faces/{subject_id}/verify
  // Headers: Content-Type: application/json, x-api-key: {{recognition_api_key}}
  
  const formData = new FormData()
  formData.append('image', imageBlob, 'face.jpg')
  
  const response = await fetch('/api/biometric/embedding', {
    method: 'POST', 
    body: formData
  })
  
  if (!response.ok) {
    throw new Error(`Biometric processing failed: ${response.statusText}`)
  }
  
  return response.json()
}

function generateBiometricHash(embeddings: number[]): string {
  // Convert embedding array to deterministic hash for wallet salt
  // This creates a consistent hash from the facial embedding vector
  const embeddingString = embeddings.join(',')
  
  // TODO: Use a proper cryptographic hash function (e.g., keccak256)
  // For now, using a simple hash for demonstration
  let hash = 0
  for (let i = 0; i < embeddingString.length; i++) {
    const char = embeddingString.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32-bit integer
  }
  
  // Convert to hex and pad to 64 characters (32 bytes)
  return '0x' + Math.abs(hash).toString(16).padStart(64, '0')
}

async function deployKernelWithInit(bioBits: string): Promise<{ account: string; transactionHash: string }> {
  // TODO: Implement actual wallet deployment with permissionless.js/ZeroDev
  // This is a placeholder implementation
  
  // Simulate deployment process
  await new Promise(resolve => setTimeout(resolve, 2000))
  
  // Mock account address and transaction hash
  const mockAccount = `0x${Math.random().toString(16).slice(2, 42).padStart(40, '0')}`
  const mockTxHash = `0x${Math.random().toString(16).slice(2, 66).padStart(64, '0')}`
  
  return {
    account: mockAccount,
    transactionHash: mockTxHash
  }
}

async function lzBroadcast(payload: { account: string; bioBits: string }): Promise<void> {
  // TODO: Implement LayerZero cross-chain broadcast
  // This is a placeholder implementation
  
  console.log('LayerZero broadcast (placeholder):', payload)
  
  // Simulate broadcast delay
  await new Promise(resolve => setTimeout(resolve, 500))
}

export function WalletCreation({ onWalletCreated }: WalletCreationProps) {
  const [state, setState] = useState<WalletCreationState>({ status: 'idle' })
  const [stream, setStream] = useState<MediaStream | null>(null)
  const videoRef = useRef<HTMLVideoElement>(null)

  const startCamera = async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user" }
      })
      setStream(mediaStream)
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream
      }
    } catch (error) {
      console.error("Error accessing camera:", error)
      toast.error("Failed to access camera")
    }
  }

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop())
      setStream(null)
    }
  }

  const createWallet = async () => {
    try {
      // Step 1: Capture face
      setState({ status: 'capturing' })
      toast.info("Capturing face...")
      
      const frame = await captureFrame()
      
      // Step 2: Enroll biometrics
      setState({ status: 'enrolling' })
      toast.info("Processing biometrics...")
      
      const { bioBits } = await enrollBiometrics(frame)
      
      // Step 3: Deploy wallet
      setState({ status: 'deploying' })
      toast.info("Deploying wallet...")
      
      const { account, transactionHash } = await deployKernelWithInit(bioBits)
      
      // Step 4: Cross-chain broadcast (placeholder)
      await lzBroadcast({ account, bioBits })
      
      // Step 5: Complete
      setState({ 
        status: 'completed', 
        account, 
        transactionHash 
      })
      
      stopCamera()
      toast.success("Wallet created successfully!")
      
      if (onWalletCreated) {
        onWalletCreated(account)
      }
      
    } catch (error) {
      console.error("Wallet creation failed:", error)
      setState({ 
        status: 'idle', 
        error: error instanceof Error ? error.message : 'Unknown error' 
      })
      toast.error("Wallet creation failed")
      stopCamera()
    }
  }

  const copyAddress = () => {
    if (state.account) {
      navigator.clipboard.writeText(state.account)
      toast.success("Address copied to clipboard")
    }
  }

  const isProcessing = ['capturing', 'enrolling', 'deploying'].includes(state.status)

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle className="flex items-center justify-center gap-2">
          <Wallet className="h-6 w-6 text-primary" />
          Create Wallet
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {state.status !== 'completed' && (
          <>
            <div className="text-center space-y-2">
              <p className="text-sm text-muted-foreground">
                Create a biometric-secured wallet with cross-chain support
              </p>
            </div>

            <div className="relative bg-muted rounded-lg overflow-hidden aspect-square">
              {stream ? (
                <video 
                  ref={videoRef} 
                  autoPlay 
                  playsInline 
                  muted 
                  className="w-full h-full object-cover" 
                />
              ) : (
                <div className="flex items-center justify-center h-full">
                  <div className="text-center space-y-4">
                    <Camera className="h-16 w-16 text-muted-foreground mx-auto" />
                    <p className="text-muted-foreground">Camera not active</p>
                  </div>
                </div>
              )}

              {isProcessing && (
                <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                  <div className="text-center text-white space-y-2">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white mx-auto"></div>
                    <p>
                      {state.status === 'capturing' && 'Capturing...'}
                      {state.status === 'enrolling' && 'Processing...'}
                      {state.status === 'deploying' && 'Deploying...'}
                    </p>
                  </div>
                </div>
              )}
            </div>

            <div className="space-y-4">
              <p className="text-center text-sm text-muted-foreground">
                Position your face in the camera frame and create your biometric wallet
              </p>

              {!stream && state.status === 'idle' && (
                <Button onClick={startCamera} variant="outline" className="w-full">
                  <Camera className="h-4 w-4 mr-2" />
                  Start Camera
                </Button>
              )}

              {stream && state.status === 'idle' && (
                <Button onClick={createWallet} className="w-full" size="lg">
                  <Wallet className="h-4 w-4 mr-2" />
                  Create Wallet
                </Button>
              )}

              {state.error && (
                <div className="text-center p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
                  <p className="text-destructive text-sm">{state.error}</p>
                </div>
              )}
            </div>
          </>
        )}

        {state.status === 'completed' && state.account && (
          <div className="space-y-6">
            <div className="text-center">
              <CheckCircle className="h-16 w-16 text-green-500 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-green-700">Wallet Created Successfully!</h3>
            </div>

            <div className="space-y-4">
              <div className="p-4 bg-primary/10 border border-primary/20 rounded-lg">
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-medium">Account Address:</span>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={copyAddress}
                      className="h-auto p-1"
                    >
                      <Copy className="h-3 w-3" />
                    </Button>
                  </div>
                  <div className="font-mono text-xs break-all bg-background p-2 rounded border">
                    {state.account}
                  </div>
                </div>
              </div>

              {state.transactionHash && (
                <div className="p-4 bg-muted rounded-lg">
                  <div className="space-y-2">
                    <span className="text-sm font-medium">Transaction Hash:</span>
                    <div className="font-mono text-xs break-all bg-background p-2 rounded border">
                      {state.transactionHash}
                    </div>
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <Button variant="outline" className="w-full">
                  <QrCode className="h-4 w-4 mr-2" />
                  Show QR Code
                </Button>
                <Button variant="outline" className="w-full">
                  Test Scan
                </Button>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}