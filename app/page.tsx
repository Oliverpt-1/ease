"use client"

import { useState } from "react"
import { BillEntry } from "@/components/bill-entry"
import { TipSelection } from "@/components/tip-selection"
import { FaceVerification } from "@/components/face-verification"
import { PaymentConfirmation } from "@/components/payment-confirmation"
import ChainlinkDemo from "@/components/chainlink-demo"
import Image from "next/image"

type Step = "bill-entry" | "tip-selection" | "face-verification" | "confirmation"

export default function Home() {
  const [currentStep, setCurrentStep] = useState<Step>("bill-entry")
  const [billAmount, setBillAmount] = useState<number>(0)
  const [tipPercentage, setTipPercentage] = useState<number>(15)
  const [isVerified, setIsVerified] = useState<boolean>(false)
  const [ensName, setEnsName] = useState<string>("")

  const tipAmount = (billAmount * tipPercentage) / 100
  const totalAmount = billAmount + tipAmount

  const handleBillSubmit = (amount: number) => {
    setBillAmount(amount)
    setCurrentStep("tip-selection")
  }

  const handleTipSubmit = (percentage: number, ensName: string) => {
    setTipPercentage(percentage)
    setEnsName(ensName)
    setCurrentStep("face-verification")
  }

  const handleVerificationComplete = () => {
    setIsVerified(true)
    setCurrentStep("confirmation")
  }

  const handleNewTransaction = () => {
    setBillAmount(0)
    setTipPercentage(15)
    setIsVerified(false)
    setEnsName("")
    setCurrentStep("bill-entry")
  }

  const handlePayment = (billAmount: number, tipAmount: number, totalAmount: number, ensName: string) => {
    setBillAmount(billAmount)
    setEnsName(ensName)
    setCurrentStep("face-verification") // Skip the redundant tip selection page
  }

  return (
    <main className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8 max-w-md">
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-2">
            <Image src="/images/ease-logo.png" alt="Eaze Logo" width={64} height={64} className="w-16 h-16" />
            <h1 className="text-3xl font-bold text-primary">Eaze</h1>
          </div>
          <p className="text-muted-foreground">Simple restaurant payments</p>
        </div>

        {currentStep === "bill-entry" && <BillEntry onSubmit={handleBillSubmit} onPayment={handlePayment} />}

        {currentStep === "tip-selection" && (
          <TipSelection
            billAmount={billAmount}
            currentTip={tipPercentage}
            onTipChange={setTipPercentage}
            onSubmit={handleTipSubmit}
            onBack={() => setCurrentStep("bill-entry")}
          />
        )}

        {currentStep === "face-verification" && (
          <FaceVerification
            totalAmount={totalAmount}
            onVerificationComplete={handleVerificationComplete}
            onBack={() => setCurrentStep("tip-selection")}
            ensName={ensName}
          />
        )}

        {currentStep === "confirmation" && (
          <PaymentConfirmation
            billAmount={billAmount}
            tipAmount={tipAmount}
            totalAmount={totalAmount}
            onNewTransaction={handleNewTransaction}
          />
        )}

      </div>
      
      {/* Chainlink Demo at bottom of screen */}
      <div className="mt-8 border-t pt-8">
        <ChainlinkDemo />
      </div>
    </main>
  )
}
