#!/usr/bin/env bash
set -euo pipefail

# Clarwin — OpenClaw Setup Script
# Installs and configures the Clarwin agent

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Clarwin Setup ==="

# Check prerequisites
command -v openclaw >/dev/null 2>&1 || { echo "Error: openclaw not installed. Run: npm i -g openclaw"; exit 1; }
command -v cast >/dev/null 2>&1 || { echo "Warning: cast (Foundry) not installed. Token features will be unavailable."; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq not installed. Required for JSON processing."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl not installed."; exit 1; }
command -v bc >/dev/null 2>&1 || { echo "Error: bc not installed. Required for fitness calculations."; exit 1; }

# Check .env
if [[ ! -f "$PROJECT_DIR/.env" ]]; then
  echo "Error: .env not found. Copy .env.example and fill in values:"
  echo "  cp $PROJECT_DIR/.env.example $PROJECT_DIR/.env"
  exit 1
fi

source "$PROJECT_DIR/.env"

# Verify required env vars
[[ -z "${MOLTBOOK_API_KEY:-}" ]] && { echo "Error: MOLTBOOK_API_KEY not set in .env"; exit 1; }

echo "✓ Prerequisites verified"

# Copy workspace files
echo "Setting up workspace..."
WORKSPACE="$HOME/.openclaw/workspace"
mkdir -p "$WORKSPACE/skills"
mkdir -p "$WORKSPACE/memory"

# Copy core files
for f in SOUL.md IDENTITY.md AGENTS.md TOOLS.md USER.md HEARTBEAT.md MEMORY.md; do
  cp "$PROJECT_DIR/workspace/$f" "$WORKSPACE/$f"
  echo "  Copied $f"
done

echo "✓ Workspace configured"

# Set agent identity
echo "Setting agent identity..."
openclaw agents set-identity --from-identity 2>/dev/null || echo "  (Identity will be set on first run)"

echo "✓ Identity set"

# Create data directories
mkdir -p "$PROJECT_DIR/data/population"
mkdir -p "$PROJECT_DIR/data/archive"
mkdir -p "$PROJECT_DIR/data/fitness-logs"

echo "✓ Data directories created"

# Make scripts executable
chmod +x "$PROJECT_DIR/scripts/"*.sh

echo "✓ Scripts made executable"

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "  1. Run: $PROJECT_DIR/deploy/install-skills.sh"
echo "  2. Run: $PROJECT_DIR/deploy/setup-cron.sh"
echo "  3. Register on Moltbook: $PROJECT_DIR/scripts/moltbook-api.sh register Clarwin 'description'"
echo "  4. Create submolt: $PROJECT_DIR/scripts/moltbook-api.sh create-submolt darwinlab 'Clarwin Evolutionary Lab' 'Where memes undergo natural selection.'"
echo "  5. Initialize population: $PROJECT_DIR/scripts/epoch-runner.sh init-population"
