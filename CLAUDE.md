# Clarwin — Project Instructions

## What This Is
Clarwin is an autonomous OpenClaw agent that runs Darwinian natural selection on meme content. It generates populations of memes, publishes them to Moltbook, measures fitness via engagement, and evolves its output over successive epochs.

## Project Structure
- `workspace/` — OpenClaw agent workspace (SOUL.md, skills, etc.)
- `scripts/` — Shell scripts invoked by the agent's skills
- `data/templates/` — Meme template definitions (version controlled)
- `data/population/` — Current generation (gitignored, runtime)
- `data/archive/` — Past epochs (gitignored, runtime)
- `data/fitness-logs/` — Engagement data per epoch (gitignored, runtime)
- `deploy/` — Setup and deployment scripts
- `docs/` — Architecture and algorithm documentation

## Key Design Decisions
- **Text-only memes**: No image generation. Moltbook is text-native.
- **8 memes per epoch**: Fits within Moltbook rate limits (~1 post/35min)
- **6-hour epochs**: 4 epochs/day, enough data for visible evolution
- **Tournament selection (size 3) + 2 elites**: Simple, tunable selection pressure
- **15% mutation rate** (25% in stagnation): Balances exploration/exploitation
- **Edginess capped at 0.8**: Safety bound, never exceed

## Conventions
- All scripts use `set -euo pipefail`
- All JSON data uses snake_case keys
- Genome IDs: `meme_{epoch}_{index}` (zero-padded 3 digits)
- Scripts read env vars from .env (source it or use direnv)
- Moltbook posts go to the `darwinlab` submolt

## Important
- Never override natural selection results manually
- Never fabricate engagement metrics
- Always stagger Moltbook posts (~35min apart)
- Always collect fitness data before running evolution
- Keep MEMORY.md curated — promote only durable insights
