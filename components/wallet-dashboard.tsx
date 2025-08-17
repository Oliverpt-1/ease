'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

const WalletDashboard = () => {
  const [walletAddress] = useState("0x742d35Cc6634C0532925a3b8D404d53c6a3e1bF8")
  const [balance] = useState("0.000")
  const [usdBalance] = useState("0.00")

  const recentTransactions: any[] = []

  const formatAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  return (
    <div className="space-y-6">
      <Card className="bg-gradient-to-br from-green-50 to-green-100 text-green-900 border border-green-200">
        <CardContent className="p-6">
          <div className="space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-green-600 text-sm">Wallet Address</p>
                <p className="font-mono text-sm">{formatAddress(walletAddress)}</p>
              </div>
              <Button variant="outline" size="sm" className="text-green-700 border-green-300 hover:bg-green-200">
                Copy
              </Button>
            </div>
            
            <div className="space-y-1">
              <h2 className="text-3xl font-bold">{balance} ETH</h2>
              <p className="text-green-600">${usdBalance} USD</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 gap-4">
        <Button className="h-16 flex-col gap-2 px-8 py-4">
          <span className="text-lg">↗</span>
          <span>Send</span>
        </Button>
        <Button variant="outline" className="h-16 flex-col gap-2 px-8 py-4">
          <span className="text-lg">↙</span>
          <span>Receive</span>
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Transactions</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {recentTransactions.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <p>No transactions yet</p>
            </div>
          ) : (
            recentTransactions.map((tx, index) => (
              <div key={index} className="flex items-center justify-between py-2 border-b last:border-b-0">
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm ${
                    tx.type === 'send' 
                      ? 'bg-green-100 text-green-700' 
                      : 'bg-green-100 text-green-700'
                  }`}>
                    {tx.type === 'send' ? '↗' : '↙'}
                  </div>
                  <div>
                    <p className="font-medium">{tx.amount}</p>
                    <p className="text-sm text-muted-foreground">
                      {tx.type === 'send' ? `To ${tx.to}` : `From ${tx.from}`}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm text-muted-foreground">{tx.time}</p>
                  <p className="text-xs text-green-600">{tx.status}</p>
                </div>
              </div>
            ))
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-4">
        <Button variant="outline" className="h-12">
          View All Transactions
        </Button>
        <Button variant="outline" className="h-12">
          Wallet Settings
        </Button>
      </div>
    </div>
  )
}

export default WalletDashboard