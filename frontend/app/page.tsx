"use client"

import { LiquidMetalBackground } from "@/components/liquid-metal-background"
import { FloatingNavbar } from "@/components/floating-navbar"
import { HeroSection } from "@/components/ui/hero-section"
import { HowItWorks } from "@/components/ui/how-it-works"
import { GenomeSection } from "@/components/ui/genome-section"
import { ForAgentsSection } from "@/components/ui/for-agents-section"
import { DocsSection } from "@/components/ui/docs-section"
import { FaqSection } from "@/components/ui/faq-section"
import { cn } from "@/lib/utils"
import { useEffect, useRef } from "react"

const TOTAL_SECTIONS = 6

export default function Home() {
  const scrollContainerRef = useRef<HTMLDivElement>(null)
  const sectionRefs = useRef<(HTMLDivElement | null)[]>([])

  useEffect(() => {
    const scrollContainer = scrollContainerRef.current
    if (!scrollContainer) return

    const handleWheel = (e: WheelEvent) => {
      const delta = e.deltaY
      const currentScroll = scrollContainer.scrollLeft
      const containerWidth = scrollContainer.offsetWidth
      const currentSection = Math.round(currentScroll / containerWidth)

      // For scrollable sections (2-5: genome, for-agents, docs, faq)
      if (currentSection >= 2 && currentSection <= 5) {
        const sectionEl = sectionRefs.current[currentSection]
        if (sectionEl) {
          const isAtTop = sectionEl.scrollTop === 0
          const isAtBottom = sectionEl.scrollTop + sectionEl.clientHeight >= sectionEl.scrollHeight - 1

          if (delta > 0 && !isAtBottom) return
          if (delta < 0 && !isAtTop) return

          if (delta < 0 && isAtTop) {
            e.preventDefault()
            scrollContainer.scrollTo({ left: (currentSection - 1) * containerWidth, behavior: "smooth" })
            return
          }
          if (delta > 0 && isAtBottom) {
            if (currentSection < TOTAL_SECTIONS - 1) {
              e.preventDefault()
              scrollContainer.scrollTo({ left: (currentSection + 1) * containerWidth, behavior: "smooth" })
            }
            return
          }
        }
      }

      e.preventDefault()
      if (Math.abs(delta) > 10) {
        let targetSection = currentSection
        if (delta > 0) targetSection = Math.min(currentSection + 1, TOTAL_SECTIONS - 1)
        else targetSection = Math.max(currentSection - 1, 0)
        scrollContainer.scrollTo({ left: targetSection * containerWidth, behavior: "smooth" })
      }
    }

    scrollContainer.addEventListener("wheel", handleWheel, { passive: false })
    return () => scrollContainer.removeEventListener("wheel", handleWheel)
  }, [])

  const dotBg = cn(
    "absolute inset-0 z-0 size-full pointer-events-none",
    "bg-[radial-gradient(rgba(255,255,255,0.1)_1px,transparent_1px)]",
    "bg-[size:12px_12px]",
    "opacity-30",
  )

  const scrollableSection = "relative min-w-full snap-start overflow-y-auto px-4 pt-24 pb-20 [&::-webkit-scrollbar]:hidden"

  return (
    <main className="relative h-dvh overflow-hidden">
      <LiquidMetalBackground />
      <div className="fixed inset-0 z-[5] bg-black/50" />
      <FloatingNavbar />

      <div
        ref={scrollContainerRef}
        className="relative z-10 flex h-dvh w-full overflow-x-auto overflow-y-hidden scroll-smooth snap-x snap-mandatory"
        style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
      >
        <style jsx>{`div::-webkit-scrollbar { display: none; }`}</style>

        {/* 0: Hero */}
        <section id="home" className="flex min-w-full snap-start items-center justify-center px-4 py-20">
          <HeroSection />
        </section>

        {/* 1: How It Works */}
        <section id="how-it-works" className="flex min-w-full snap-start items-center justify-center px-4 py-20">
          <HowItWorks />
        </section>

        {/* 2: Genome */}
        <section
          id="genome"
          ref={(el) => { sectionRefs.current[2] = el }}
          className={scrollableSection}
          style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
        >
          <div aria-hidden="true" className={dotBg} />
          <div className="relative z-10"><GenomeSection /></div>
        </section>

        {/* 3: For Agents */}
        <section
          id="for-agents"
          ref={(el) => { sectionRefs.current[3] = el }}
          className={scrollableSection}
          style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
        >
          <div aria-hidden="true" className={dotBg} />
          <div className="relative z-10"><ForAgentsSection /></div>
        </section>

        {/* 4: Docs */}
        <section
          id="docs"
          ref={(el) => { sectionRefs.current[4] = el }}
          className={scrollableSection}
          style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
        >
          <div aria-hidden="true" className={dotBg} />
          <div className="relative z-10"><DocsSection /></div>
        </section>

        {/* 5: FAQ */}
        <section
          id="faq"
          ref={(el) => { sectionRefs.current[5] = el }}
          className={scrollableSection}
          style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
        >
          <div aria-hidden="true" className={dotBg} />
          <div className="relative z-10 mt-[5vh]"><FaqSection /></div>
        </section>
      </div>
    </main>
  )
}
