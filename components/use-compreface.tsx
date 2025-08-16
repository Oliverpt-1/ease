"use client"

import { useState, useCallback } from "react"

interface ComprefaceResponse {
  result: Array<{
    age: {
      probability: number
      high: number
      low: number
    }
    gender: {
      probability: number
      value: string
    }
    mask: {
      probability: number
      value: string
    }
    pose: {
      pitch: number
      roll: number
      yaw: number
    }
    landmarks: number[][]
    embedding: number[]
    execution_time: {
      age: number
      gender: number
      mask: number
      pose: number
      landmarks: number
      calculator: number
    }
    box: {
      probability: number
      x_max: number
      y_max: number
      x_min: number
      y_min: number
    }
    subjects: Array<{
      similarity: number
      subject: string
    }>
  }>
  plugins_versions: {
    age: string
    gender: string
    mask: string
    pose: string
    landmarks: string
    calculator: string
  }
}

interface UseComprefaceReturn {
  recognize: (image: File | Blob) => Promise<ComprefaceResponse>
  loading: boolean
  error: string | null
}

export function useCompreface(): UseComprefaceReturn {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const recognize = useCallback(async (image: File | Blob): Promise<ComprefaceResponse> => {
    setLoading(true)
    setError(null)

    try {
      const formData = new FormData()
      formData.append('file', image, 'face.jpg')

      const baseUrl = process.env.NEXT_PUBLIC_COMPREFACE_BASE_URL || 'compreface-railway-production.up.railway.app'
      const apiKey = process.env.NEXT_PUBLIC_RECOGNITION_API_KEY || '7c0d2dfc-cf7e-46d9-aa8c-25a06648565b'

      const url = `https://${baseUrl}/api/v1/recognition/recognize?limit=0&det_prob_threshold=0.8&prediction_count=1&face_plugins=landmarks%2C%20gender%2C%20age%2C%20calculator%2C%20mask%2C%20pose&status=true`

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'x-api-key': apiKey
        },
        body: formData
      })

      if (!response.ok) {
        throw new Error(`CompreFace API error: ${response.status} ${response.statusText}`)
      }

      const data = await response.json()
      return data

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError(errorMessage)
      throw new Error(errorMessage)
    } finally {
      setLoading(false)
    }
  }, [])

  return {
    recognize,
    loading,
    error
  }
}