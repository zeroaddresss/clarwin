#!/usr/bin/env bash
set -euo pipefail

# Clarwin — Skill Installation Script
# Copies skills to OpenClaw workspace

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

echo "=== Installing Clarwin Skills ==="

SKILLS=("evolution-engine" "meme-generator" "fitness-tracker" "epoch-reporter" "darwin-governance")

for skill in "${SKILLS[@]}"; do
  src="$PROJECT_DIR/workspace/skills/$skill"
  dest="$WORKSPACE/skills/$skill"

  if [[ ! -d "$src" ]]; then
    echo "Warning: Skill source not found: $src"
    continue
  fi

  mkdir -p "$dest"
  cp -r "$src/"* "$dest/"
  echo "  ✓ Installed: $skill"
done

echo ""
echo "=== Skills Installed ==="
echo "Installed ${#SKILLS[@]} skills to $WORKSPACE/skills/"
