"use client"
import Image from "next/image"
import { Button } from "@/components/ui/button"

export function FloatingNavbar() {
  const scrollToSection = (sectionId: string) => {
    const section = document.getElementById(sectionId)
    if (section) {
      section.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "start" })
    }
  }

  return (
    <nav className="fixed left-0 right-0 top-0 z-50 px-4 py-4">
      <div className="mx-auto max-w-7xl rounded-2xl border-2 border-white/10 bg-white/5 px-6 py-3 backdrop-blur-sm">
        <div className="flex items-center justify-between">
          <button onClick={() => scrollToSection("home")} className="cursor-pointer flex items-center gap-2">
            <Image
              src="/mascot-notext-nobg-raw.PNG"
              alt="Clarwin"
              width={36}
              height={36}
              className="rounded-full"
            />
            <span className="text-white font-open-sans-custom text-lg [text-shadow:_0_2px_8px_rgb(0_0_0_/_40%)]">
              Clarwin
            </span>
          </button>

          <div className="hidden items-center gap-6 md:flex">
            {[
              ["how-it-works", "How It Works"],
              ["genome", "Genome"],
              ["for-agents", "For Agents"],
              ["docs", "Docs"],
              ["faq", "FAQ"],
            ].map(([id, label]) => (
              <button
                key={id}
                onClick={() => scrollToSection(id)}
                className="text-sm font-open-sans-custom text-gray-300 transition-colors hover:text-white [text-shadow:_0_2px_6px_rgb(0_0_0_/_40%)]"
              >
                {label}
              </button>
            ))}
          </div>

          <a href="https://github.com/zeroaddresss/clarwin" target="_blank" rel="noopener noreferrer">
            <Button
              size="sm"
              variant="ghost"
              className="border border-white/15 bg-white/5 text-gray-300 hover:bg-white/10 hover:text-white backdrop-blur-sm font-open-sans-custom text-sm"
            >
              View on GitHub
            </Button>
          </a>
        </div>
      </div>
    </nav>
  )
}
