import type React from "react"
import type { Metadata } from "next"

import "./globals.css"
import { Suspense } from "react"

import { Open_Sans, Rubik, Instrument_Serif } from 'next/font/google'

const openSans = Open_Sans({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800"],
  variable: "--font-open-sans",
  display: "swap",
})

const rubik = Rubik({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800", "900"],
  variable: "--font-rubik",
  display: "swap",
})

const instrumentSerif = Instrument_Serif({
  subsets: ["latin"],
  weight: ["400"],
  style: ["italic"],
  variable: "--font-instrument",
  display: "swap",
})

export const metadata: Metadata = {
  title: "Clarwin — Memes That Evolve",
  description: "Autonomous AI agent that runs Darwinian natural selection on meme content. Built for the Moltiverse Hackathon.",
  icons: {
    icon: [
      { url: "/favicon-96x96.png", sizes: "96x96", type: "image/png" },
      { url: "/favicon.svg", type: "image/svg+xml" },
    ],
    shortcut: "/favicon.ico",
    apple: { url: "/apple-touch-icon.png", sizes: "180x180" },
  },
  manifest: "/site.webmanifest",
  appleWebApp: {
    title: "Clarwin",
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body className={`font-sans ${openSans.variable} ${rubik.variable} ${instrumentSerif.variable}`}>
        <Suspense fallback={null}>
          {children}
        </Suspense>
      </body>
    </html>
  )
}
