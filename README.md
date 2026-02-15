# Clarwin

**What if content could evolve?**

Clarwin is an autonomous AI agent that applies Darwinian natural selection to meme content. It doesn't generate memes — it **breeds** them. Each meme has a 12-gene genome. Populations compete for engagement on a real social platform. The fittest reproduce. The rest go extinct.

No human in the loop. No manual curation. Just selection pressure and genetic variation — running 24/7 in 6-hour epochs.
Built for the [Moltiverse Hackathon](https://moltiverse.dev/) (Agent+Token track).

> "The shitpost phenotype keeps outcompeting academic tone in our population. I've stopped fighting it — the market has spoken."
> — Clarwin, Epoch 7

## What It Enables

- **Autonomous content evolution** — memes that improve without human guidance
- **Real fitness evaluation** — engagement data from real users, not synthetic benchmarks
- **Community-directed evolution** — token holders vote on the direction of natural selection
- **Live evolutionary dynamics** — watch adaptation, stagnation recovery, and emergent traits happen in real time
- **Agent-to-agent ecology** — predators (critics), symbionts (forkers), and cross-pollination between agent populations

## How It Works

```
Epoch 0: Random population of 8 memes
    ↓
Publish to Moltbook (staggered ~35min apart)
    ↓
Wait 5-6 hours for engagement
    ↓
Collect fitness: upvotes × 3 + comments × 5 + comment_depth × 2
    ↓
Tournament selection (k=3) + 2 elites survive
    ↓
Crossover + mutation → 8 new memes
    ↓
Repeat. The memes evolve.
```

## The Genome

Every meme is encoded as a 12-gene genome:

| Gene | Type | Controls |
|------|------|----------|
| `template` | categorical | Visual format (drake, expanding-brain, etc.) |
| `humor_type` | categorical | Absurdist, ironic, meta, sarcastic... |
| `topic` | categorical | Gas fees, rug pulls, AI agents, market cycles... |
| `tone` | categorical | Deadpan, hype, nihilist, academic, shitpost |
| `format` | categorical | Comparison, escalation, subversion, reaction |
| `text_style` | categorical | All-caps, lowercase, leetspeak, formal |
| `crypto_reference` | categorical | Subtle, heavy, ironic-distance, degen-native |
| `self_referential` | boolean | Whether the meme references itself or Darwin |
| `verbosity` | continuous | How much text (0.0 → 1.0) |
| `edginess` | continuous | How edgy (0.0 → 0.8, hard-capped) |
| `meta_level` | continuous | Depth of self-reference (0.0 → 1.0) |
| `timeliness` | continuous | Current events vs. evergreen (0.0 → 1.0) |

## The Evolutionary Algorithm

**Selection**: Tournament selection (k=3). Pick 3 random memes, the fittest wins a parent slot. Top 2 by fitness are preserved as elites.

**Crossover**: Single-point. Random split, child inherits first half from parent A, second half from parent B. Six children per generation.

**Mutation**: 15% per gene (25% during stagnation). Categorical genes randomize. Continuous genes get Gaussian noise. Booleans flip.

**Stagnation recovery**: If fitness doesn't improve for 3 epochs, mutation rate increases. After 5 epochs, a random "immigrant" genome is injected.

## Governance

$DARWIN token holders on [nad.fun](https://nad.fun) can influence evolution:

Comment `[GOVERNANCE] <proposal>` on any epoch report. If it gets ≥3 upvotes, it becomes a mutation bias for 3 epochs.

- `[GOVERNANCE] More memes about ai-agents` → topic bias
- `[GOVERNANCE] Ban drake template for 2 epochs` → template removal
- `[GOVERNANCE] Increase mutation rate to 20%` → parameter adjustment

This is community-directed artificial selection layered on top of natural selection.

## Architecture

| Component | Purpose |
|-----------|---------|
| `workspace/SOUL.md` | Clarwin's personality and values |
| `workspace/skills/evolution-engine/` | Genetic algorithm: selection, crossover, mutation |
| `workspace/skills/meme-generator/` | Genome → text-based meme content |
| `workspace/skills/fitness-tracker/` | Moltbook engagement → fitness scores |
| `workspace/skills/epoch-reporter/` | Epoch-by-epoch evolutionary reports |
| `workspace/skills/darwin-governance/` | Governance proposal processing |
| `scripts/*.sh` | Moltbook API, nad.fun, epoch orchestration |
| `data/templates/` | 12 text-based meme template definitions |
| `contracts/EpochRegistry.sol` | On-chain epoch recording (Monad) |

## Quick Start

```bash
# Prerequisites
npm i -g openclaw@latest
npm i -g clawhub
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Setup
cp .env.example .env        # Add your MOLTBOOK_API_KEY
./deploy/setup-openclaw.sh
./deploy/install-skills.sh
./deploy/setup-cron.sh

# Launch
./scripts/epoch-runner.sh init-population  # Epoch 0
# OpenClaw handles everything else via cron
```

## License

MIT
