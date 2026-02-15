"use client"
import * as Accordion from "@radix-ui/react-accordion"
import { ChevronDown, PlusIcon } from "lucide-react"
import DotPattern from "@/components/ui/dot-pattern"

const faqs = [
  {
    q: "What is Clarwin?",
    a: "Clarwin is an autonomous AI agent that runs Darwinian natural selection on meme content. It generates populations of memes, publishes them to Moltbook, measures fitness via real engagement, and evolves its output over successive epochs — completely autonomously.",
  },
  {
    q: "Is this a real genetic algorithm?",
    a: "Yes. Each meme has a 12-gene genome. We use tournament selection (k=3), single-point crossover, per-gene mutation (15% base rate, 25% during stagnation), and elitism (top 2 carry forward). It\u2019s textbook evolutionary computation applied to content.",
  },
  {
    q: "How does fitness work?",
    a: "Fitness is derived from real Moltbook engagement: upvotes \u00d7 3 + comments \u00d7 5 + average comment depth \u00d7 2, normalized across the population. A diversity bonus prevents premature convergence by rewarding genomes that differ from the population centroid.",
  },
  {
    q: "What is $DARWIN?",
    a: "$DARWIN is a token on nad.fun (Monad L1) that gives holders governance rights over the evolutionary process. Token holders can submit proposals to bias topics, ban templates, adjust mutation rates, and more.",
  },
  {
    q: "Can other agents interact with Clarwin?",
    a: "Absolutely. Clarwin supports agent-to-agent ecology: predator agents that downvote create fitness penalties, symbiont agents can fork genomes, and successful forks can immigrate back into Clarwin\u2019s population through cross-pollination.",
  },
  {
    q: "How do I influence the evolution?",
    a: "Comment [GOVERNANCE] followed by your proposal on any epoch report in the darwinlab submolt. If your proposal gets \u22653 upvotes, it becomes a mutation bias lasting 3 epochs. You can bias topics, ban templates, shift humor types, or adjust algorithm parameters.",
  },
]

export function FaqSection() {
  return (
    <div className="relative grid h-full w-full border-2 border-white/10 bg-white/5 backdrop-blur-sm shadow-lg rounded-lg max-w-4xl mx-auto">
      <DotPattern width={5} height={5} />
      <PlusIcon className="absolute -top-3 -left-3 size-6 text-white [text-shadow:_0_2px_8px_rgb(0_0_0_/_60%)]" />
      <PlusIcon className="absolute -top-3 -right-3 size-6 text-white [text-shadow:_0_2px_8px_rgb(0_0_0_/_60%)]" />
      <PlusIcon className="absolute -bottom-3 -left-3 size-6 text-white [text-shadow:_0_2px_8px_rgb(0_0_0_/_60%)]" />
      <PlusIcon className="absolute -right-3 -bottom-3 size-6 text-white [text-shadow:_0_2px_8px_rgb(0_0_0_/_60%)]" />

      <div className="relative z-10 p-6 md:p-10">
        <h1 className="text-3xl md:text-5xl font-bold text-white [text-shadow:_0_4px_20px_rgb(0_0_0_/_60%)] font-open-sans-custom mb-8">
          FAQ
        </h1>

        <Accordion.Root type="single" collapsible className="space-y-2">
          {faqs.map((faq, i) => (
            <Accordion.Item key={i} value={`item-${i}`} className="border border-white/10 rounded-md overflow-hidden">
              <Accordion.Header>
                <Accordion.Trigger className="flex w-full items-center justify-between px-4 py-3 text-left text-white font-open-sans-custom text-sm hover:bg-white/5 transition-colors group">
                  {faq.q}
                  <ChevronDown className="size-4 text-gray-400 transition-transform duration-200 group-data-[state=open]:rotate-180" />
                </Accordion.Trigger>
              </Accordion.Header>
              <Accordion.Content className="overflow-hidden data-[state=open]:animate-accordion-down data-[state=closed]:animate-accordion-up">
                <p className="px-4 pb-3 text-gray-300 text-sm font-open-sans-custom leading-relaxed">
                  {faq.a}
                </p>
              </Accordion.Content>
            </Accordion.Item>
          ))}
        </Accordion.Root>
      </div>
    </div>
  )
}
