
"use client"

import { Navigation } from "@/components/Navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ShieldAlert, MapPin, Siren, Hospital, Hotel, MessageSquare, ArrowRight, Star, Shield } from "lucide-react"
import Link from "next/link"
import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"

export default function Home() {
  const [location, setLocation] = useState<string | null>(null)
  const router = useRouter()

  useEffect(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition((position) => {
        setLocation(`${position.coords.latitude.toFixed(4)}, ${position.coords.longitude.toFixed(4)}`)
      })
    }
  }, [])

  return (
    <div className="min-h-screen md:pl-20 pb-20 md:pb-0">
      <Navigation />
      
      <main className="max-w-4xl mx-auto p-6 space-y-8">
        <header className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold font-headline text-foreground">Guardian Angel</h1>
            <p className="text-muted-foreground">Your personal safety companion.</p>
          </div>
          <div className="flex items-center gap-2 bg-white px-3 py-1.5 rounded-full border border-border shadow-sm">
            <MapPin className="w-4 h-4 text-primary" />
            <span className="text-xs font-medium">{location || "Locating..."}</span>
          </div>
        </header>

        {/* SOS Section */}
        <div className="flex flex-col items-center justify-center py-12 space-y-6">
          <Link href="/sos" className="relative group">
            <div className="absolute inset-0 bg-red-500 rounded-full blur-xl opacity-20 group-hover:opacity-30 transition-opacity sos-pulse"></div>
            <button className="relative w-48 h-48 bg-red-600 rounded-full border-8 border-red-100 shadow-2xl flex flex-col items-center justify-center text-white transition-transform active:scale-95 group-hover:scale-105">
              <Siren className="w-16 h-16 mb-2" />
              <span className="text-3xl font-black tracking-widest">SOS</span>
            </button>
          </Link>
          <p className="text-sm font-medium text-center max-w-xs text-muted-foreground">
            Press and hold to trigger an emergency signal to your designated contacts.
          </p>
        </div>

        {/* Quick Actions Grid */}
        <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card className="hover:shadow-md transition-shadow cursor-pointer overflow-hidden border-none bg-white">
            <Link href="/chat">
              <CardContent className="p-6 flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600">
                  <MessageSquare className="w-6 h-6" />
                </div>
                <div className="flex-1">
                  <h3 className="font-bold">Chat Assistance</h3>
                  <p className="text-sm text-muted-foreground">Immediate guidance during distress.</p>
                </div>
                <ArrowRight className="w-5 h-5 text-muted-foreground" />
              </CardContent>
            </Link>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer overflow-hidden border-none bg-white">
            <Link href="/nearby">
              <CardContent className="p-6 flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-orange-100 flex items-center justify-center text-orange-600">
                  <ShieldAlert className="w-6 h-6" />
                </div>
                <div className="flex-1">
                  <h3 className="font-bold">Nearby Resources</h3>
                  <p className="text-sm text-muted-foreground">Find police and hospitals nearby.</p>
                </div>
                <ArrowRight className="w-5 h-5 text-muted-foreground" />
              </CardContent>
            </Link>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer overflow-hidden border-none bg-white">
            <Link href="/hotels">
              <CardContent className="p-6 flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-green-600">
                  <Hotel className="w-6 h-6" />
                </div>
                <div className="flex-1">
                  <h3 className="font-bold">Safe Hotels</h3>
                  <p className="text-sm text-muted-foreground">AI-vetted safe accommodation suggestions.</p>
                </div>
                <ArrowRight className="w-5 h-5 text-muted-foreground" />
              </CardContent>
            </Link>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer overflow-hidden border-none bg-white">
            <Link href="/feedback">
              <CardContent className="p-6 flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center text-gray-600">
                  <Star className="w-6 h-6" />
                </div>
                <div className="flex-1">
                  <h3 className="font-bold">Feedback</h3>
                  <p className="text-sm text-muted-foreground">Help us improve your safety tools.</p>
                </div>
                <ArrowRight className="w-5 h-5 text-muted-foreground" />
              </CardContent>
            </Link>
          </Card>
        </section>

        <section className="bg-primary/10 rounded-2xl p-6 border border-primary/20 flex items-start gap-4">
          <div className="p-2 bg-primary rounded-lg text-white">
            <Shield className="w-5 h-5" />
          </div>
          <div>
            <h4 className="font-bold text-primary">Safety Tip</h4>
            <p className="text-sm text-foreground/80 leading-relaxed">
              Always keep your live location sharing on when walking alone at night. Guardian Angel keeps your contacts informed until you reach your destination safely.
            </p>
          </div>
        </section>
      </main>
    </div>
  )
}
