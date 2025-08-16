"use client"

import { WalletCreationFlow } from "@/components/wallet-creation-flow"

export default function WalletCreatePage() {
  return (
    <main className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8 max-w-md">
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-2">
            <h1 className="text-3xl font-bold text-primary">Create Wallet</h1>
          </div>
          <p className="text-muted-foreground">Create your biometric-secured wallet</p>
        </div>

        <WalletCreationFlow />
      </div>
    </main>
  )
}