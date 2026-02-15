#!/usr/bin/env bash
set -euo pipefail

# Clarwin — Governance Poll Checker
# Scans epoch report comments for governance proposals

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Source .env for standalone execution (OpenClaw sets env vars for cron runs)
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
[[ -f "$ENV_FILE" ]] && set -a && source "$ENV_FILE" && set +a

DATA_DIR="$(dirname "$SCRIPT_DIR")/data"

VOTE_THRESHOLD="${GOVERNANCE_VOTE_THRESHOLD:-3}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args...]

Commands:
  check <post_id>    Check for governance proposals in comments
  tally <post_id>    Tally votes on governance proposals
  active             List currently active governance effects
EOF
  exit 1
}

cmd_check() {
  local post_id="$1"
  local comments
  comments=$("$SCRIPT_DIR/moltbook-api.sh" get-comments "$post_id" 2>/dev/null) || {
    echo "Error: Could not fetch comments for post $post_id"
    exit 1
  }

  echo "Scanning for [GOVERNANCE] proposals..."

  local proposals="[]"
  local count
  count=$(echo "$comments" | jq 'if type == "array" then length else 0 end')

  for i in $(seq 0 $((count - 1))); do
    local comment
    comment=$(echo "$comments" | jq ".[$i]")
    local content
    content=$(echo "$comment" | jq -r '.content // ""')

    if echo "$content" | grep -qi '^\[GOVERNANCE\]'; then
      local author upvotes comment_id
      author=$(echo "$comment" | jq -r '.author // .agent_name // "unknown"')
      upvotes=$(echo "$comment" | jq '.upvotes // 0')
      comment_id=$(echo "$comment" | jq -r '.id // "unknown"')

      local proposal_text
      proposal_text=$(echo "$content" | sed 's/^\[GOVERNANCE\]\s*//')

      proposals=$(echo "$proposals" | jq \
        --arg id "$comment_id" --arg author "$author" \
        --argjson votes "$upvotes" --arg text "$proposal_text" \
        --argjson threshold "$VOTE_THRESHOLD" \
        '. += [{"comment_id": $id, "author": $author, "upvotes": $votes, "proposal": $text, "passes": ($votes >= $threshold)}]')
    fi
  done

  local passing
  passing=$(echo "$proposals" | jq '[.[] | select(.passes)] | length')
  local total
  total=$(echo "$proposals" | jq 'length')

  echo "Found $total proposals, $passing passing (threshold: $VOTE_THRESHOLD upvotes)"
  echo "$proposals" | jq '.'
}

cmd_tally() {
  cmd_check "$@"
}

cmd_active() {
  local memory_file
  # Search for MEMORY.md in workspace
  for f in "$DATA_DIR/../workspace/MEMORY.md" "$HOME/.openclaw/workspace/MEMORY.md"; do
    [[ -f "$f" ]] && { memory_file="$f"; break; }
  done

  if [[ -z "${memory_file:-}" ]]; then
    echo "No MEMORY.md found. No active governance."
    exit 0
  fi

  echo "=== Active Governance Effects ==="
  # Extract governance section from MEMORY.md
  sed -n '/## Active Governance/,/## /p' "$memory_file" | head -n -1
}

[[ $# -lt 1 ]] && usage

case "$1" in
  check)  shift; cmd_check "$@" ;;
  tally)  shift; cmd_tally "$@" ;;
  active) cmd_active ;;
  *)      echo "Unknown command: $1"; usage ;;
esac
