import DotPattern from "@/components/ui/dot-pattern"
import { Badge } from "@/components/ui/badge"
import { BookOpen, GitBranch, Github, MessageSquare, ExternalLink } from "lucide-react"

const docs = [
  { icon: BookOpen, title: "Architecture", desc: "System diagram, data flow, component overview", href: "https://github.com/zeroaddresss/clarwin#architecture" },
  { icon: GitBranch, title: "Evolutionary Algorithm", desc: "Genome spec, fitness function, selection, mutation", href: "https://github.com/zeroaddresss/clarwin#the-evolutionary-algorithm" },
  { icon: Github, title: "Source Code", desc: "Full codebase — scripts, skills, templates, contracts", href: "https://github.com/zeroaddresss/clarwin" },
  { icon: MessageSquare, title: "Darwinlab", desc: "Our submolt — comment on epoch reports, vote on governance", href: "https://moltbook.com/m/darwinlab" },
]

const techStack = [
  "OpenClaw", "Claude Opus 4.6", "Next.js", "Moltbook API",
  "Monad (EVM L1)", "Solidity", "Foundry", "nad.fun", "bash/jq",
]

export function DocsSection() {
  return (
    <div className="mx-auto w-full max-w-7xl">
      <div className="relative flex flex-col items-center border-2 border-white/20 rounded-lg backdrop-blur-sm bg-white/5">
        <DotPattern width={5} height={5} />
        <div className="absolute -left-1.5 -top-1.5 size-3 bg-white/80" />
        <div className="absolute -bottom-1.5 -left-1.5 size-3 bg-white/80" />
        <div className="absolute -right-1.5 -top-1.5 size-3 bg-white/80" />
        <div className="absolute -bottom-1.5 -right-1.5 size-3 bg-white/80" />

        <div className="relative z-20 mx-auto max-w-5xl w-full py-10 md:p-10 xl:py-16 px-6">
          <h1 className="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight text-white [text-shadow:_0_4px_20px_rgb(0_0_0_/_60%)] mb-8 font-open-sans-custom">
            Documentation
          </h1>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-10">
            {docs.map((doc, i) => (
              <a
                key={i}
                href={doc.href}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-white/5 border border-white/10 rounded-md p-4 hover:bg-white/10 transition-colors group"
              >
                <div className="flex items-center gap-3 mb-2">
                  <doc.icon className="size-5 text-white" strokeWidth={2} />
                  <h3 className="text-white font-open-sans-custom">{doc.title}</h3>
                  <ExternalLink className="size-3 text-gray-500 ml-auto group-hover:text-white transition-colors" />
                </div>
                <p className="text-gray-400 text-sm font-open-sans-custom">{doc.desc}</p>
              </a>
            ))}
          </div>

          <div>
            <h3 className="text-white font-open-sans-custom mb-3 text-sm">Tech Stack</h3>
            <div className="flex flex-wrap gap-2">
              {techStack.map((tech, i) => (
                <Badge
                  key={i}
                  variant="secondary"
                  className="bg-white/10 text-gray-300 border-white/10 font-open-sans-custom text-xs"
                >
                  {tech}
                </Badge>
              ))}
            </div>
          </div>

          <div className="mt-8 pt-6 border-t border-white/10">
            <p className="text-gray-400 text-sm font-open-sans-custom">
              Built for the{" "}
              <a href="https://moltiverse.dev/" target="_blank" rel="noopener noreferrer" className="text-white underline underline-offset-2 hover:text-gray-300">
                Moltiverse Hackathon
              </a>
              {" "}&mdash; Agent+Token track
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
