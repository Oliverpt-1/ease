"use client"

import { useState, useRef, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { useCompreface } from "@/components/use-compreface"
import { toast } from "sonner"
import { Wallet, Camera, CheckCircle, Copy, QrCode, User } from "lucide-react"

const HAMMING_THRESHOLD = 0.6

interface WalletCreationState {
  status: 'idle' | 'capturing' | 'processing' | 'deploying' | 'registering' | 'broadcasting' | 'completed'
  account?: string
  transactionHash?: string
  bioBits?: string
  ensName: string
  error?: string
}

async function captureImageAndGetEmbedding(
  videoRef: React.RefObject<HTMLVideoElement | null>,
  canvasRef: React.RefObject<HTMLCanvasElement | null>,
  recognize: (blob: Blob) => Promise<any>
): Promise<number[]> {
  return new Promise((resolve, reject) => {
    if (!videoRef.current || !canvasRef.current) {
      reject(new Error("Video or canvas ref not available"))
      return
    }

    const video = videoRef.current
    const canvas = canvasRef.current
    const ctx = canvas.getContext('2d')
    
    if (!ctx || video.readyState < video.HAVE_CURRENT_DATA) {
      reject(new Error("Cannot capture image from video"))
      return
    }

    canvas.width = video.videoWidth || 640
    canvas.height = video.videoHeight || 480
    
    try {
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    } catch (drawError) {
      reject(new Error("Failed to draw image to canvas"))
      return
    }

    canvas.toBlob(async (blob) => {
      if (!blob) {
        reject(new Error("Failed to create image blob"))
        return
      }

      try {
        const result = await recognize(blob)
        
        if (!result.result?.[0]?.embedding) {
          reject(new Error("No face detected or embedding not available"))
          return
        }

        const embedding = result.result[0].embedding
        resolve(embedding)
      } catch (error) {
        reject(error)
      }
    }, 'image/jpeg', 0.8)
  })
}

async function deployContract(): Promise<void> {
  // TODO: Implement contract deployment
}

export function WalletCreationFlow() {
  const [state, setState] = useState<WalletCreationState>({ 
    status: 'idle',
    ensName: ''
  })
  const [stream, setStream] = useState<MediaStream | null>(null)
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  
  const { recognize, loading } = useCompreface()

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
    if (!state.ensName.trim()) {
      toast.error("Please enter an ENS name")
      return
    }

    try {
      setState(prev => ({ ...prev, status: 'capturing' }))
      toast.info("Capturing face and processing biometrics...")
      
      const embedding = await captureImageAndGetEmbedding(videoRef, canvasRef, recognize)
      
      setState(prev => ({ 
        ...prev,
        status: 'completed'
      }))
      
      console.log('EMBEDDING:', embedding)
      
      stopCamera()
      toast.success("Biometrics processed successfully!")
      
    } catch (error) {
      console.error("Processing failed:", error)
      setState(prev => ({ 
        ...prev,
        status: 'idle', 
        error: error instanceof Error ? error.message : 'Unknown error' 
      }))
      toast.error("Biometric processing failed")
      stopCamera()
    }
  }

  const copyAddress = () => {
    if (state.account) {
      navigator.clipboard.writeText(state.account)
      toast.success("Address copied to clipboard")
    }
  }

  const isProcessing = ['capturing', 'processing', 'deploying', 'broadcasting'].includes(state.status)

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle className="flex items-center justify-center gap-2">
          <Wallet className="h-6 w-6 text-primary" />
          Create Biometric Wallet
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {state.status !== 'completed' && (
          <>
            {/* ENS Name Input */}
            <div className="space-y-2">
              <label className="text-sm font-medium flex items-center gap-2">
                <User className="h-4 w-4" />
                ENS Name
              </label>
              <div className="relative">
                <Input
                  type="text"
                  placeholder="yourname"
                  value={state.ensName}
                  onChange={(e) => setState(prev => ({ ...prev, ensName: e.target.value }))}
                  className="pr-20 text-center"
                  disabled={isProcessing}
                />
                <div className="absolute right-3 top-1/2 transform -translate-y-1/2 text-muted-foreground text-sm pointer-events-none">
                  .ease.eth
                </div>
              </div>
            </div>

            <div className="text-center space-y-2">
              <p className="text-sm text-muted-foreground">
                Create a wallet secured by your biometric data
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

              {isProcessing && (
                <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                  <div className="text-center text-white space-y-2">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white mx-auto"></div>
                    <p>
                      {state.status === 'capturing' && 'Capturing...'}
                      {state.status === 'processing' && 'Processing...'}
                      {state.status === 'deploying' && 'Deploying...'}
                      {state.status === 'broadcasting' && 'Broadcasting...'}
                    </p>
                  </div>
                </div>
              )}
            </div>

            <div className="space-y-4">
              <p className="text-center text-sm text-muted-foreground">
                Position your face in the camera frame to create your wallet
              </p>

              {!stream && state.status === 'idle' && (
                <Button onClick={startCamera} variant="outline" className="w-full">
                  <Camera className="h-4 w-4 mr-2" />
                  Start Camera
                </Button>
              )}

              {stream && state.status === 'idle' && (
                <Button 
                  onClick={createWallet} 
                  className="w-full" 
                  size="lg"
                  disabled={!state.ensName.trim()}
                >
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
              <p className="text-sm text-muted-foreground mt-2">
                ENS: {state.ensName}
              </p>
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

        {/* Hidden canvas for image capture */}
        <canvas ref={canvasRef} style={{ display: 'none' }} />
      </CardContent>
    </Card>
  )
}