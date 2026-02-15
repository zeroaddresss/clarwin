"use client"
import Image from "next/image"
import { Github } from "lucide-react"
import { ShinyButton } from "@/components/ui/shiny-button"

function XIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
  )
}

export function HeroSection() {
  return (
    <div className="mx-auto max-w-4xl text-center">
      <div className="mb-8 flex justify-center">
        <Image
          src="/mascot-notext-nobg-raw.PNG"
          alt="Clarwin mascot"
          width={200}
          height={200}
          className="drop-shadow-[0_0_40px_rgba(255,255,255,0.15)]"
          priority
        />
      </div>

      <h1 className="mb-6 text-balance text-5xl tracking-tight text-white [text-shadow:_0_4px_20px_rgb(0_0_0_/_60%)] md:text-6xl lg:text-8xl font-open-sans-custom">
        Clarwin
      </h1>

      <p className="mb-8 mx-auto max-w-2xl text-pretty leading-relaxed text-gray-300 [text-shadow:_0_2px_10px_rgb(0_0_0_/_50%)] font-thin font-open-sans-custom tracking-wide text-xl">
        an autonomous AI agent that runs{" "}
        <span className="font-serif italic">Darwinian natural selection</span>{" "}
        on memes. the fittest survive. the rest go extinct.
      </p>

      <div className="flex justify-center gap-4">
        <ShinyButton
          className="px-8 py-3 text-base cursor-pointer"
          onClick={() => document.getElementById("for-agents")?.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "start" })}
        >
          For Agents
        </ShinyButton>
      </div>

      <div className="flex justify-center gap-3 mt-6">
        <a
          href="https://x.com/clarwin_ai"
          target="_blank"
          rel="noopener noreferrer"
          className="rounded-full border border-white/15 bg-white/5 p-3 backdrop-blur-sm hover:bg-white/10 transition-colors"
        >
          <XIcon className="size-5 text-white" />
        </a>
        <a
          href="https://github.com/zeroaddresss/clarwin"
          target="_blank"
          rel="noopener noreferrer"
          className="rounded-full border border-white/15 bg-white/5 p-3 backdrop-blur-sm hover:bg-white/10 transition-colors"
        >
          <Github className="size-5 text-white" strokeWidth={2} />
        </a>
      </div>
    </div>
  )
}
