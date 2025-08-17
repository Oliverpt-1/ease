"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { DollarSign, Camera, User } from "lucide-react"

interface BillEntryProps {
  onSubmit: (amount: number) => void
  onPayment: (billAmount: number, tipAmount: number, totalAmount: number, ensName: string) => void
}

export function BillEntry({ onSubmit, onPayment }: BillEntryProps) {
  const [amount, setAmount] = useState<string>("")
  const [error, setError] = useState<string>("")
  const [selectedTip, setSelectedTip] = useState<number | null>(null)
  const [customTip, setCustomTip] = useState<string>("")
  const [ensName, setEnsName] = useState<string>("")

  const billAmount = Number.parseFloat(amount) || 0
  const tipPercentages = [10, 15, 20]

  const calculateTip = (percentage: number) => {
    return (billAmount * percentage) / 100
  }

  const getTipAmount = () => {
    if (selectedTip === -1) {
      return Number.parseFloat(customTip) || 0
    }
    return selectedTip ? calculateTip(selectedTip) : 0
  }

  const totalAmount = billAmount + getTipAmount()

  const handlePayment = () => {
    const numAmount = Number.parseFloat(amount)

    if (isNaN(numAmount) || numAmount <= 0) {
      setError("Please enter a valid amount")
      return
    }

    if (selectedTip === null) {
      setError("Please select a tip amount")
      return
    }

    if (!ensName.trim()) {
      setError("Please enter your ENS name")
      return
    }

    setError("")
    const tipAmount = getTipAmount()
    onPayment(billAmount, tipAmount, totalAmount, ensName)
  }

  return (
    <Card className="w-full">
      <CardHeader className="text-center">
        <CardTitle className="flex items-center justify-center gap-2">
          <DollarSign className="h-6 w-6 text-primary" />
          Enter Bill & Select Tip
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* Bill Amount Entry */}
          <div className="space-y-2">
            <h3 className="text-lg font-semibold text-center">Bill Amount</h3>
            <div className="relative">
              <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                type="number"
                step="0.01"
                placeholder="0.00"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="pl-10 text-lg text-center"
                autoFocus
              />
            </div>
            {error && <p className="text-destructive text-sm text-center">{error}</p>}
          </div>

          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-center">Select Tip</h3>

            {/* Preset Tip Buttons */}
            <div className="grid grid-cols-3 gap-3">
              {tipPercentages.map((percentage) => (
                <Button
                  key={percentage}
                  variant={selectedTip === percentage ? "default" : "outline"}
                  onClick={() => {
                    setSelectedTip(percentage)
                    setCustomTip("")
                  }}
                  className="flex flex-col py-8 px-4"
                >
                  <span className="text-lg font-bold">{percentage}%</span>
                  <span className="text-sm">${calculateTip(percentage).toFixed(2)}</span>
                </Button>
              ))}
            </div>

            {/* Custom Tip */}
            <div className="space-y-2">
              <Button
                variant={selectedTip === -1 ? "default" : "outline"}
                onClick={() => setSelectedTip(-1)}
                className="w-full"
              >
                Custom Tip
              </Button>

              {selectedTip === -1 && (
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    type="number"
                    step="0.01"
                    placeholder="0.00"
                    value={customTip}
                    onChange={(e) => setCustomTip(e.target.value)}
                    className="pl-10 text-center"
                  />
                </div>
              )}
            </div>
          </div>

          {/* ENS Name Input */}
          <div className="space-y-2">
            <h3 className="text-lg font-semibold text-center">Your ENS Name</h3>
            <div className="relative">
              <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                type="text"
                placeholder="Enter your ENS name (e.g., john)"
                value={ensName}
                onChange={(e) => setEnsName(e.target.value)}
                className="pl-10 text-center"
              />
            </div>
            <p className="text-xs text-muted-foreground text-center">This will identify your wallet (e.g., john.eaze.eth)</p>
          </div>

          <div className="text-center p-4 bg-primary/10 rounded-lg border-2 border-primary/20">
            <div className="space-y-1">
              <div className="flex justify-between text-sm">
                <span>Bill:</span>
                <span>${billAmount.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span>Tip:</span>
                <span>${getTipAmount().toFixed(2)}</span>
              </div>
              <div className="border-t pt-1 mt-2">
                <div className="flex justify-between font-bold text-lg">
                  <span>Total:</span>
                  <span>${totalAmount.toFixed(2)}</span>
                </div>
              </div>
            </div>
          </div>

          <Button
            onClick={handlePayment}
            disabled={billAmount <= 0 || selectedTip === null || !ensName.trim()}
            className="w-full"
            size="lg"
          >
            <Camera className="mr-2 h-5 w-5" />
            Pay ${totalAmount.toFixed(2)}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
