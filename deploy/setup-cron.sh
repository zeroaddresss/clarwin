#!/usr/bin/env bash
set -euo pipefail

# Clarwin — Cron Job Setup
# Registers automated epoch cycles and heartbeat

echo "=== Setting Up Clarwin Cron Jobs ==="

# Main epoch cycle — every 6 hours (00:00, 06:00, 12:00, 18:00 UTC)
echo "Adding darwin-epoch cron job (every 6h)..."
openclaw cron add \
  --name "darwin-epoch" \
  --cron "0 0,6,12,18 * * *" \
  --session isolated \
  --message "Run the full epoch cycle: 1) Invoke fitness-tracker to collect engagement data for the previous epoch. 2) Invoke evolution-engine to run selection, crossover, and mutation. 3) Invoke darwin-governance to check for and process any governance proposals. 4) Invoke meme-generator to generate phenotypes for the new population. 5) Run scripts/epoch-runner.sh to publish memes staggered ~35min apart. 6) Invoke epoch-reporter to generate and publish the epoch report. 7) Update MEMORY.md with evolutionary insights." \
  2>/dev/null && echo "  ✓ darwin-epoch registered" || echo "  ⚠ Failed to register darwin-epoch"

# Pre-epoch fitness collection — 30 min before each epoch
echo "Adding darwin-fitness-collect cron job (30min before epochs)..."
openclaw cron add \
  --name "darwin-fitness-collect" \
  --cron "30 5,11,17,23 * * *" \
  --session isolated \
  --message "Pre-epoch fitness collection: Run scripts/fitness-scraper.sh to collect engagement metrics for the current epoch's memes. Save results to data/fitness-logs/. This runs 30 minutes before each epoch cycle to ensure fresh data." \
  2>/dev/null && echo "  ✓ darwin-fitness-collect registered" || echo "  ⚠ Failed to register darwin-fitness-collect"

# Heartbeat — every 2 hours
echo "Adding darwin-heartbeat cron job (every 2h)..."
openclaw cron add \
  --name "darwin-heartbeat" \
  --every 7200000 \
  --session main \
  --message "Heartbeat: Check HEARTBEAT.md and perform the checklist items. Respond to comments, check governance proposals, engage with other agents, browse the feed." \
  2>/dev/null && echo "  ✓ darwin-heartbeat registered" || echo "  ⚠ Failed to register darwin-heartbeat"

echo ""
echo "=== Cron Jobs Configured ==="
echo "Registered 3 cron jobs:"
echo "  • darwin-epoch: Every 6h (00:00, 06:00, 12:00, 18:00 UTC)"
echo "  • darwin-fitness-collect: 30min before epochs (05:30, 11:30, 17:30, 23:30 UTC)"
echo "  • darwin-heartbeat: Every 2h (engagement and social)"
echo ""
openclaw cron list 2>/dev/null || echo "(Run 'openclaw cron list' to verify)"
