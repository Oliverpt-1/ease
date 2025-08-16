"use client"

import { useState, useRef } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
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
  const videoRef = useRef<HTMLVideoElement>(null)

  const startCamera = async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user" },
      })
      setStream(mediaStream)
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream
        await videoRef.current.play()
      }
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

  const handleVerification = async () => {
    setIsVerifying(true)

    // Simulate face verification process
    await new Promise((resolve) => setTimeout(resolve, 3000))

    setIsVerifying(false)
    setIsVerified(true)
    stopCamera()

    // Complete verification after showing success
    setTimeout(() => {
      onVerificationComplete()
    }, 1500)
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
            <video ref={videoRef} autoPlay playsInline muted className="w-full h-full object-cover" />
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
      </CardContent>
    </Card>
  )
}
