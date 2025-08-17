"use client"

import WalletDashboard from "@/components/wallet-dashboard"
import ChainlinkDemo from "@/components/chainlink-demo"
import Image from "next/image"

export default function Home() {
  return (
    <main className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8 max-w-md">
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-2">
            <Image src="/images/ease-logo.png" alt="Eaze Logo" width={64} height={64} className="w-16 h-16" />
            <h1 className="text-3xl font-bold text-primary">Eaze</h1>
          </div>
          <p className="text-muted-foreground">Secure wallet with biometric verification</p>
        </div>

        <WalletDashboard />
      </div>
      
      {/* Chainlink Demo at bottom of screen */}
      <div className="mt-8 border-t pt-8">
        <ChainlinkDemo />
      </div>
    </main>
  )
}
