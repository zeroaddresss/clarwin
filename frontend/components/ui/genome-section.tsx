import { Badge } from "@/components/ui/badge"
import { Check } from "lucide-react"
import DotPattern from "@/components/ui/dot-pattern"
import { cn } from "@/lib/utils"

const categoricalGenes = [
  { name: "template", values: "drake, expanding-brain, galaxy-brain, +9 more" },
  { name: "humor_type", values: "absurdist, ironic, meta, sarcastic, +3 more" },
  { name: "topic", values: "gas-fees, rug-pulls, ai-agents, monad, +8 more" },
  { name: "tone", values: "deadpan, hype, nihilist, academic, shitpost, wholesome" },
  { name: "format", values: "comparison, escalation, subversion, reaction, label, dialogue" },
  { name: "text_style", values: "all-caps, lowercase, leetspeak, formal, emoji-heavy, mixed" },
  { name: "crypto_reference", values: "subtle, heavy, none, ironic-distance, technical, degen" },
]

const continuousGenes = [
  { name: "verbosity", range: "0.0 → 1.0", desc: "text length" },
  { name: "edginess", range: "0.0 → 0.8", desc: "hard-capped" },
  { name: "meta_level", range: "0.0 → 1.0", desc: "self-reference depth" },
  { name: "timeliness", range: "0.0 → 1.0", desc: "current events vs evergreen" },
]

export function GenomeSection() {
  return (
    <div className="mx-auto w-full max-w-6xl">
      <div className="mx-auto mb-10 max-w-2xl text-center">
        <h1 className="text-4xl font-extrabold tracking-tight lg:text-6xl text-white [text-shadow:_0_4px_20px_rgb(0_0_0_/_60%)] font-open-sans-custom">
          The Genome
        </h1>
        <p className="text-gray-300 mt-4 text-sm md:text-base font-open-sans-custom [text-shadow:_0_2px_10px_rgb(0_0_0_/_50%)]">
          Every meme is encoded as a 12-gene genome. No two memes share the same DNA.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-1.5 lg:grid-cols-8">
        {/* Categorical genes - large card */}
        <div className={cn(
          "bg-white/5 border-white/10 relative overflow-hidden rounded-md border-2 backdrop-blur-sm lg:col-span-5"
        )}>
          <DotPattern width={5} height={5} />
          <div className="flex items-center gap-3 p-3">
            <Badge variant="secondary" className="bg-white/10 text-white border-white/20 font-open-sans-custom text-xs">
              CATEGORICAL x 7
            </Badge>
          </div>
          <ul className="text-gray-300 grid gap-2 p-3 text-xs font-open-sans-custom">
            {categoricalGenes.map((g, i) => (
              <li key={i} className="flex items-start gap-2">
                <Check className="size-4 text-white flex-shrink-0 mt-0.5" strokeWidth={3} />
                <span>
                  <span className="text-white font-mono">{g.name}</span>
                  <span className="text-gray-400 ml-2">{g.values}</span>
                </span>
              </li>
            ))}
          </ul>
        </div>

        {/* Boolean + Continuous genes */}
        <div className={cn(
          "bg-white/5 border-white/10 relative overflow-hidden rounded-md border-2 backdrop-blur-sm lg:col-span-3"
        )}>
          <DotPattern width={5} height={5} />
          <div className="flex items-center gap-3 p-3">
            <Badge variant="secondary" className="bg-white/10 text-white border-white/20 font-open-sans-custom text-xs">
              BOOLEAN x 1
            </Badge>
          </div>
          <div className="p-3 text-xs">
            <div className="flex items-center gap-2">
              <Check className="size-4 text-white flex-shrink-0" strokeWidth={3} />
              <span className="text-white font-mono">self_referential</span>
              <span className="text-gray-400">true / false</span>
            </div>
          </div>

          <div className="flex items-center gap-3 p-3 pt-4">
            <Badge variant="secondary" className="bg-white/10 text-white border-white/20 font-open-sans-custom text-xs">
              CONTINUOUS x 4
            </Badge>
          </div>
          <ul className="text-gray-300 grid gap-2 p-3 text-xs font-open-sans-custom">
            {continuousGenes.map((g, i) => (
              <li key={i} className="flex items-center gap-2">
                <Check className="size-4 text-white flex-shrink-0" strokeWidth={3} />
                <span className="text-white font-mono">{g.name}</span>
                <span className="text-gray-400 ml-1">[{g.range}]</span>
                <span className="text-gray-500 ml-1">{g.desc}</span>
              </li>
            ))}
          </ul>
        </div>

        {/* Fitness function - full width */}
        <div className={cn(
          "bg-white/5 border-white/10 relative overflow-hidden rounded-md border-2 backdrop-blur-sm lg:col-span-8"
        )}>
          <DotPattern width={5} height={5} />
          <div className="flex items-center gap-3 p-3">
            <Badge variant="secondary" className="bg-white/10 text-white border-white/20 font-open-sans-custom text-xs">
              FITNESS FUNCTION
            </Badge>
          </div>
          <div className="p-3 pt-0">
            <code className="text-sm text-white font-mono leading-relaxed block">
              fitness = normalize(upvotes x 3 + comments x 5 + comment_depth x 2) + diversity_bonus
            </code>
            <p className="text-gray-400 text-xs mt-2 font-open-sans-custom">
              Comments weighted highest — deeper engagement signals stronger fitness. Diversity bonus prevents convergence.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
