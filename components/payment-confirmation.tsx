"use client"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { CheckCircle, Receipt } from "lucide-react"

interface PaymentConfirmationProps {
  billAmount: number
  tipAmount: number
  totalAmount: number
  onNewTransaction: () => void
}

export function PaymentConfirmation({
  billAmount,
  tipAmount,
  totalAmount,
  onNewTransaction,
}: PaymentConfirmationProps) {
  return (
    <Card className="w-full">
      <CardHeader className="text-center">
        <div className="mx-auto mb-4 h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center">
          <CheckCircle className="h-8 w-8 text-primary" />
        </div>
        <CardTitle className="text-2xl text-primary">Payment Successful!</CardTitle>
        <p className="text-muted-foreground">Your payment has been processed</p>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="bg-secondary/30 p-4 rounded-lg space-y-3">
          <div className="flex items-center gap-2 mb-3">
            <Receipt className="h-4 w-4 text-muted-foreground" />
            <span className="font-medium">Transaction Summary</span>
          </div>

          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span>Bill Amount</span>
              <span>${billAmount.toFixed(2)}</span>
            </div>
            <div className="flex justify-between">
              <span>Tip</span>
              <span>${tipAmount.toFixed(2)}</span>
            </div>
            <div className="border-t pt-2 flex justify-between font-bold text-base">
              <span>Total Paid</span>
              <span>${totalAmount.toFixed(2)}</span>
            </div>
          </div>
        </div>

        <div className="text-center space-y-2">
          <p className="text-sm text-muted-foreground">
            Transaction ID: {Math.random().toString(36).substr(2, 9).toUpperCase()}
          </p>
          <p className="text-xs text-muted-foreground">{new Date().toLocaleString()}</p>
        </div>

        <Button onClick={onNewTransaction} className="w-full" size="lg">
          New Transaction
        </Button>
      </CardContent>
    </Card>
  )
}
