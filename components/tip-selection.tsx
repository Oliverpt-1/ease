"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ArrowLeft, Percent, User } from "lucide-react"

interface TipSelectionProps {
  billAmount: number
  currentTip: number
  onTipChange: (percentage: number) => void
  onSubmit: (percentage: number, ensName: string) => void
  onBack: () => void
}

export function TipSelection({ billAmount, currentTip, onTipChange, onSubmit, onBack }: TipSelectionProps) {
  const [customTip, setCustomTip] = useState<string>("")
  const [isCustom, setIsCustom] = useState<boolean>(false)
  const [ensName, setEnsName] = useState<string>("")

  const presetTips = [10, 15, 20]
  const tipAmount = (billAmount * currentTip) / 100
  const totalAmount = billAmount + tipAmount

  const handlePresetTip = (percentage: number) => {
    setIsCustom(false)
    setCustomTip("")
    onTipChange(percentage)
  }

  const handleCustomTip = (value: string) => {
    setCustomTip(value)
    setIsCustom(true)
    const numValue = Number.parseFloat(value)
    if (!isNaN(numValue) && numValue >= 0) {
      onTipChange(numValue)
    }
  }

  const handleSubmit = () => {
    if (!ensName.trim()) {
      alert("Please enter your ENS name")
      return
    }
    onSubmit(currentTip, ensName)
  }

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" onClick={onBack}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <CardTitle className="flex-1 text-center">Select Tip</CardTitle>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="text-center space-y-2">
          <p className="text-sm text-muted-foreground">Bill Amount</p>
          <p className="text-2xl font-bold">${billAmount.toFixed(2)}</p>
        </div>

        <div className="grid grid-cols-3 gap-3">
          {presetTips.map((percentage) => (
            <Button
              key={percentage}
              variant={currentTip === percentage && !isCustom ? "default" : "outline"}
              onClick={() => handlePresetTip(percentage)}
              className="h-12"
            >
              {percentage}%
            </Button>
          ))}
        </div>

        <div className="space-y-2">
          <label className="text-sm font-medium">Custom Tip</label>
          <div className="relative">
            <Input
              type="number"
              step="0.1"
              placeholder="Enter custom %"
              value={customTip}
              onChange={(e) => handleCustomTip(e.target.value)}
              className="pr-10"
            />
            <Percent className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          </div>
        </div>

        <div className="space-y-2">
          <label className="text-sm font-medium">Your ENS Name</label>
          <div className="relative">
            <Input
              type="text"
              placeholder="Enter your ENS name (e.g., john)"
              value={ensName}
              onChange={(e) => setEnsName(e.target.value)}
              className="pr-10"
            />
            <User className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          </div>
          <p className="text-xs text-muted-foreground">This will be your wallet identifier (e.g., john.eaze.eth)</p>
        </div>

        <div className="bg-secondary/50 p-4 rounded-lg space-y-2">
          <div className="flex justify-between">
            <span>Tip ({currentTip}%)</span>
            <span>${tipAmount.toFixed(2)}</span>
          </div>
          <div className="flex justify-between font-bold text-lg">
            <span>Total</span>
            <span>${totalAmount.toFixed(2)}</span>
          </div>
        </div>

        <Button onClick={handleSubmit} className="w-full" size="lg">
          Continue to Payment
        </Button>
      </CardContent>
    </Card>
  )
}
