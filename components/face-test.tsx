"use client"

import { useState, useRef, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { useCompreface } from "@/components/use-compreface"
import { Camera, Upload } from "lucide-react"

export function FaceTest() {
  const [stream, setStream] = useState<MediaStream | null>(null)
  const [capturedImage, setCapturedImage] = useState<Blob | null>(null)
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  
  const { recognize, loading, error } = useCompreface()

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

  const captureImage = () => {
    if (!videoRef.current || !canvasRef.current) return

    const video = videoRef.current
    const canvas = canvasRef.current
    const ctx = canvas.getContext('2d')
    
    if (!ctx) return
    if (video.readyState < video.HAVE_CURRENT_DATA) return

    canvas.width = video.videoWidth || 640
    canvas.height = video.videoHeight || 480
    
    try {
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    } catch (drawError) {
      return
    }

    canvas.toBlob((blob) => {
      if (blob) {
        setCapturedImage(blob)
      }
    }, 'image/jpeg', 0.8)
  }

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setCapturedImage(file)
    }
  }

  const processImage = async () => {
    if (!capturedImage) return

    try {
      const result = await recognize(capturedImage)
      
      if (result.result && result.result.length > 0) {
        const faceData = result.result[0]
        
        if (faceData.embedding && Array.isArray(faceData.embedding)) {
          const embedding = faceData.embedding
          console.log('EMBEDDING:', embedding)
        }
      }
    } catch (err) {
      console.error('Failed to process image:', err)
    }
  }

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>Face Recognition Test</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Camera Section */}
        <div className="space-y-2">
          <h3 className="font-semibold">Camera Capture</h3>
          
          {/* Debug Info */}
          <div className="text-xs bg-gray-100 p-2 rounded">
            <div>Stream: {stream ? '✅ Active' : '❌ None'}</div>
            <div>Video Element: {videoRef.current ? '✅ Ready' : '❌ Not ready'}</div>
            {videoRef.current && (
              <>
                <div>Ready State: {videoRef.current.readyState}/4</div>
                <div>Dimensions: {videoRef.current.videoWidth}x{videoRef.current.videoHeight}</div>
                <div>Paused: {videoRef.current.paused ? 'Yes' : 'No'}</div>
              </>
            )}
          </div>
          
          <div className="relative bg-muted rounded-lg overflow-hidden aspect-video">
            {stream ? (
              <video 
                ref={videoRef} 
                autoPlay 
                playsInline 
                muted 
                className="w-full h-full object-cover" 
                style={{ transform: 'scaleX(-1)' }} // Mirror the video
              />
            ) : (
              <div className="flex items-center justify-center h-full">
                <Camera className="h-16 w-16 text-muted-foreground" />
              </div>
            )}
          </div>
          
          <div className="flex gap-2">
            {!stream ? (
              <Button onClick={startCamera} variant="outline">
                <Camera className="h-4 w-4 mr-2" />
                Start Camera
              </Button>
            ) : (
              <>
                <Button onClick={captureImage}>Capture</Button>
                <Button onClick={stopCamera} variant="outline">Stop</Button>
              </>
            )}
          </div>
        </div>

        {/* File Upload Section */}
        <div className="space-y-2">
          <h3 className="font-semibold">File Upload</h3>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileUpload}
            className="hidden"
          />
          <Button 
            onClick={() => fileInputRef.current?.click()} 
            variant="outline"
            className="w-full"
          >
            <Upload className="h-4 w-4 mr-2" />
            Upload Image
          </Button>
        </div>

        {/* Process Button */}
        {capturedImage && (
          <div className="space-y-2">
            <h3 className="font-semibold">Process Image</h3>
            <Button 
              onClick={processImage} 
              disabled={loading}
              className="w-full"
            >
              {loading ? 'Processing...' : 'Get Embedding'}
            </Button>
          </div>
        )}

        {/* Error Display */}
        {error && (
          <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
            <p className="text-destructive text-sm">{error}</p>
          </div>
        )}

        {/* Hidden canvas for image capture */}
        <canvas ref={canvasRef} style={{ display: 'none' }} />
      </CardContent>
    </Card>
  )
}