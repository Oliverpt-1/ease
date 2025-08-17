"use client"

import { useState, useRef, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { useCompreface } from "@/components/use-compreface"
import { toast } from "sonner"
import { Wallet, Camera } from "lucide-react"

interface WalletCreationState {
  status: 'idle' | 'capturing' | 'completed'
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

async function createWallet(): Promise<void> {
  // TODO: Implement wallet creation functionality
}

export function WalletCreationFlow() {
  const [state, setState] = useState<WalletCreationState>({ 
    status: 'idle'
  })
  const [stream, setStream] = useState<MediaStream | null>(null)
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  
  const { recognize } = useCompreface()

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


  const handleCaptureAndProcess = async () => {
    try {
      setState(prev => ({ ...prev, status: 'capturing' }))
      toast.info("Capturing face and processing biometrics...")
      
      const embedding = await captureImageAndGetEmbedding(videoRef, canvasRef, recognize)
      console.log('EMBEDDING:', embedding)

      //Hash the embedding
      
      //Call create wallet address contract with the desired ens name 

      setState(prev => ({ 
        ...prev,
        status: 'completed'
      }))
      
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

  const isProcessing = state.status === 'capturing'

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
            <div className="text-center space-y-2">
              <p className="text-sm text-muted-foreground">
                Capture your face to get biometric embedding
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
                    <p>Capturing...</p>
                  </div>
                </div>
              )}
            </div>

            <div className="space-y-4">
              <p className="text-center text-sm text-muted-foreground">
                Position your face in the camera frame
              </p>

              {!stream && state.status === 'idle' && (
                <Button onClick={startCamera} variant="outline" className="w-full">
                  <Camera className="h-4 w-4 mr-2" />
                  Start Camera
                </Button>
              )}

              {stream && state.status === 'idle' && (
                <Button 
                  onClick={handleCaptureAndProcess} 
                  className="w-full" 
                  size="lg"
                >
                  <Camera className="h-4 w-4 mr-2" />
                  Capture & Process
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

        {state.status === 'completed' && (
          <div className="text-center space-y-4">
            <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
              <p className="text-green-700 font-medium">Biometric embedding captured successfully!</p>
              <p className="text-sm text-muted-foreground mt-1">Check console for embedding data</p>
            </div>
            <Button onClick={() => setState({ status: 'idle' })} variant="outline" className="w-full">
              Capture Another
            </Button>
          </div>
        )}

        {/* Hidden canvas for image capture */}
        <canvas ref={canvasRef} style={{ display: 'none' }} />
      </CardContent>
    </Card>
  )
}