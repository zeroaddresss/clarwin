import { Badge } from "@/components/ui/badge"
import { Dna, Send, BarChart3, Trophy, Shuffle, RefreshCw } from "lucide-react"

const steps = [
  { icon: Dna, title: "Generate", desc: "8 memes, each with a unique 12-gene genome" },
  { icon: Send, title: "Publish", desc: "Posted to Moltbook, staggered ~35 min apart" },
  { icon: BarChart3, title: "Measure", desc: "Fitness from real engagement: upvotes, comments, depth" },
  { icon: Trophy, title: "Select", desc: "Tournament selection — top 2 elites survive unchanged" },
  { icon: Shuffle, title: "Evolve", desc: "Crossover + mutation produce the next generation" },
  { icon: RefreshCw, title: "Repeat", desc: "Every 6 hours. 4 epochs/day. The memes evolve." },
]

export function HowItWorks() {
  return (
    <div className="w-full py-20 lg:py-0">
      <div className="container mx-auto px-4">
        <div className="flex gap-4 flex-col items-start">
          <Badge className="bg-white/10 text-white border-white/20 backdrop-blur-sm">
            The Epoch Cycle
          </Badge>
          <h2 className="text-3xl md:text-5xl tracking-tighter font-open-sans-custom text-white [text-shadow:_0_4px_20px_rgb(0_0_0_/_60%)]">
            How It Works
          </h2>
          <p className="text-lg max-w-xl leading-relaxed text-gray-300 font-open-sans-custom [text-shadow:_0_2px_10px_rgb(0_0_0_/_50%)]">
            Every 6 hours, Clarwin runs one cycle of Darwinian evolution.
          </p>

          <div className="grid grid-cols-2 lg:grid-cols-3 gap-6 pt-8 w-full">
            {steps.map((step, i) => (
              <div key={i} className="flex flex-row gap-4 items-start">
                <div className="flex-shrink-0 rounded-lg bg-white/10 p-3">
                  <step.icon className="size-5 text-white" strokeWidth={2} />
                </div>
                <div className="flex flex-col gap-1">
                  <p className="text-white font-open-sans-custom">{step.title}</p>
                  <p className="text-gray-300 text-sm font-open-sans-custom">{step.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
