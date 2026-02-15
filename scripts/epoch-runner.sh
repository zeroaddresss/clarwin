#!/usr/bin/env bash
set -euo pipefail

# Clarwin — Epoch Runner
# Orchestrates the publication of memes with staggered timing
#
# Data flow:
#   current.json → (meme-generator skill) → phenotypes-epoch-N.json
#   phenotypes-epoch-N.json → (this script: publish) → Moltbook + publish-status-epoch-N.json
#   publish-status-epoch-N.json → (fitness-scraper.sh) → fitness-logs/epoch-N.json
#   fitness-logs/epoch-N.json + current.json → (evolution-engine skill) → new current.json + archive/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Save caller's env vars before .env sourcing (caller overrides .env)
_CALLER_STAGGER="${STAGGER_MINUTES:-}"

# Source .env for standalone execution (OpenClaw sets env vars for cron runs)
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
[[ -f "$ENV_FILE" ]] && set -a && source "$ENV_FILE" && set +a

# Caller's explicit env var takes precedence over .env
[[ -n "$_CALLER_STAGGER" ]] && STAGGER_MINUTES="$_CALLER_STAGGER"

DATA_DIR="$(dirname "$SCRIPT_DIR")/data"
STAGGER_MINUTES="${STAGGER_MINUTES:-35}"
DARWIN_SUBMOLT="${DARWIN_SUBMOLT:-darwinlab}"
BASE_URL="https://www.moltbook.com/api/v1"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args...]

Commands:
  publish <epoch_num>     Publish memes for an epoch with staggered timing
  status                  Check current epoch publication status
  init-population         Generate random initial population (epoch 0)
EOF
  exit 1
}

is_published() {
  local status_file="$1" meme_id="$2"
  [[ -f "$status_file" ]] && jq -e --arg id "$meme_id" \
    '.memes[] | select(.id == $id and .status == "published")' "$status_file" >/dev/null 2>&1
}

verify_post() {
  local response="$1"
  local verify_code verify_challenge

  # Check if verification is required
  verify_code=$(echo "$response" | jq -r '.verification.code // empty')
  [[ -z "$verify_code" ]] && return 0

  verify_challenge=$(echo "$response" | jq -r '.verification.challenge // empty')
  echo "  Verification required. Challenge: ${verify_challenge:0:60}..."

  # Solve with Python helper
  local answer
  answer=$(python3 "$SCRIPT_DIR/solve-verification.py" "$verify_challenge" 2>/dev/null) || {
    echo "  Warning: Auto-solver failed. Challenge: $verify_challenge"
    return 1
  }

  echo "  Solving: $answer"
  local verify_response
  verify_response=$(curl -s -X POST \
    -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
    -H "Content-Type: application/json" \
    "$BASE_URL/verify" \
    -d "$(jq -n --arg code "$verify_code" --arg ans "$answer" \
      '{verification_code: $code, answer: $ans}')")

  local success
  success=$(echo "$verify_response" | jq -r '.success // false')
  if [[ "$success" == "true" ]]; then
    echo "  Verification passed!"
    return 0
  else
    echo "  Verification failed: $(echo "$verify_response" | jq -r '.error // .message // "unknown"')"
    return 1
  fi
}

cmd_publish() {
  local epoch="$1"
  local epoch_padded
  epoch_padded=$(printf '%03d' "$epoch")
  local phenotypes="$DATA_DIR/population/phenotypes-epoch-${epoch_padded}.json"
  local status_file="$DATA_DIR/population/publish-status-epoch-${epoch_padded}.json"

  [[ ! -f "$phenotypes" ]] && { echo "Error: Phenotypes file not found: $phenotypes"; exit 1; }

  local count
  count=$(jq '.memes | length' "$phenotypes")
  echo "Publishing $count memes for epoch $epoch (stagger: ${STAGGER_MINUTES}min)..."

  # Initialize status file only if it doesn't exist or has no memes
  if [[ ! -f "$status_file" ]] || [[ "$(jq '.memes | length' "$status_file" 2>/dev/null)" == "0" ]]; then
    jq -n --arg e "$epoch" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{epoch: ($e|tonumber), started_at: $t, memes: [], completed_at: null}' > "$status_file"
  fi

  local published=0 skipped=0
  for i in $(seq 0 $((count - 1))); do
    local meme
    meme=$(jq ".memes[$i]" "$phenotypes")
    local id title content
    id=$(echo "$meme" | jq -r '.id')
    title=$(echo "$meme" | jq -r '.title')
    content=$(echo "$meme" | jq -r '.content')

    # Skip already-published memes (resume support)
    if is_published "$status_file" "$id"; then
      echo "[$(date -u +%H:%M)] Skipping $id (already published)"
      skipped=$((skipped + 1))
      continue
    fi

    # Stagger: wait before publishing (skip delay for first post in this run)
    if [[ $published -gt 0 ]]; then
      echo "  Waiting ${STAGGER_MINUTES} minutes before next post..."
      sleep $((STAGGER_MINUTES * 60))
    fi

    echo "[$(date -u +%H:%M)] Publishing meme $((i + 1))/$count: $id"

    # Publish to Moltbook
    local response
    response=$("$SCRIPT_DIR/moltbook-api.sh" post "$DARWIN_SUBMOLT" "$title" "$content" 2>&1) || {
      echo "Warning: Failed to publish $id: $response"
      jq --arg id "$id" --arg err "$response" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '.memes += [{"id": $id, "status": "failed", "error": $err, "attempted_at": $t}]' \
        "$status_file" > "${status_file}.tmp" && mv "${status_file}.tmp" "$status_file"
      continue
    }

    # Check for rate limit or other API error
    local is_success
    is_success=$(echo "$response" | jq -r 'if .success == false then "false" else "true" end')
    if [[ "$is_success" == "false" ]]; then
      local err_msg retry_after
      err_msg=$(echo "$response" | jq -r '.error // "unknown"')
      retry_after=$(echo "$response" | jq -r '.retry_after_minutes // empty')
      echo "  Rate limited: $err_msg"
      if [[ -n "$retry_after" ]]; then
        echo "  Retrying in $retry_after minutes..."
        sleep $((retry_after * 60))
        # Retry this meme
        response=$("$SCRIPT_DIR/moltbook-api.sh" post "$DARWIN_SUBMOLT" "$title" "$content" 2>&1) || {
          echo "Warning: Retry failed for $id"
          continue
        }
      else
        continue
      fi
    fi

    local post_id
    post_id=$(echo "$response" | jq -r '.post.id // .id // .post_id // empty')

    # Handle verification
    if ! verify_post "$response"; then
      echo "  Warning: Verification failed for $id, recording as unverified"
      jq --arg id "$id" --arg pid "${post_id:-unknown}" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '.memes += [{"id": $id, "post_id": $pid, "published_at": $t, "status": "unverified"}]' \
        "$status_file" > "${status_file}.tmp" && mv "${status_file}.tmp" "$status_file"
      published=$((published + 1))
      continue
    fi

    # Record success in status
    jq --arg id "$id" --arg pid "${post_id:-unknown}" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '.memes += [{"id": $id, "post_id": $pid, "published_at": $t, "status": "published"}]' \
      "$status_file" > "${status_file}.tmp" && mv "${status_file}.tmp" "$status_file"

    echo "  Published: post_id=$post_id"
    published=$((published + 1))
  done

  # Mark epoch as complete if all memes are published
  local total_published
  total_published=$(jq '[.memes[] | select(.status == "published")] | length' "$status_file")
  if [[ "$total_published" -eq "$count" ]]; then
    jq --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.completed_at = $t' \
      "$status_file" > "${status_file}.tmp" && mv "${status_file}.tmp" "$status_file"
    echo "Epoch $epoch publication complete! ($total_published/$count published)"
  else
    echo "Epoch $epoch: $total_published/$count published, $skipped skipped. Run again to continue."
  fi
}

cmd_status() {
  local latest
  latest=$(ls -t "$DATA_DIR"/population/publish-status-epoch-*.json 2>/dev/null | head -1)
  [[ -z "$latest" ]] && { echo "No publication status found."; exit 0; }
  echo "Latest publication status:"
  jq '.' "$latest"
}

cmd_init_population() {
  local templates=("drake" "distracted-boyfriend" "expanding-brain" "two-buttons" "change-my-mind" "is-this" "galaxy-brain" "stonks" "gru-plan" "one-does-not-simply" "batman-slapping" "exit-ramp")
  local humor_types=("absurdist" "ironic" "observational" "self-deprecating" "surreal" "meta" "sarcastic")
  local topics=("gas-fees" "rug-pulls" "diamond-hands" "degen-life" "ai-agents" "monad" "governance" "yield-farming" "nft-cope" "meme-meta" "darwin-self" "market-cycles")
  local tones=("deadpan" "hype" "nihilist" "academic" "shitpost" "wholesome")
  local formats=("comparison" "escalation" "subversion" "reaction" "label" "dialogue")
  local text_styles=("all-caps" "lowercase" "mixed-case" "leetspeak" "formal" "emoji-heavy")
  local crypto_refs=("subtle" "heavy" "none" "ironic-distance" "technical" "degen-native")

  rand_elem() {
    local arr=("$@")
    echo "${arr[$((RANDOM % ${#arr[@]}))]}"
  }

  rand_float() {
    local max="${1:-100}"
    printf "0.%02d" $((RANDOM % max))
  }

  local pop_file="$DATA_DIR/population/current.json"
  mkdir -p "$DATA_DIR/population"

  local memes="[]"
  for i in $(seq 1 8); do
    local id="meme_000_$(printf '%03d' "$i")"
    local self_ref="false"
    [[ $((RANDOM % 4)) -eq 0 ]] && self_ref="true"

    memes=$(echo "$memes" | jq --arg id "$id" \
      --arg tmpl "$(rand_elem "${templates[@]}")" \
      --arg humor "$(rand_elem "${humor_types[@]}")" \
      --arg topic "$(rand_elem "${topics[@]}")" \
      --arg tone "$(rand_elem "${tones[@]}")" \
      --arg fmt "$(rand_elem "${formats[@]}")" \
      --arg ts "$(rand_elem "${text_styles[@]}")" \
      --arg cr "$(rand_elem "${crypto_refs[@]}")" \
      --argjson sr "$self_ref" \
      --arg verb "$(rand_float 100)" \
      --arg edge "$(rand_float 80)" \
      --arg meta "$(rand_float 100)" \
      --arg time "$(rand_float 100)" \
      '. += [{
        "id": $id,
        "genome": {
          "template": $tmpl,
          "humor_type": $humor,
          "topic": $topic,
          "tone": $tone,
          "format": $fmt,
          "text_style": $ts,
          "crypto_reference": $cr,
          "self_referential": $sr,
          "verbosity": ($verb|tonumber),
          "edginess": ($edge|tonumber),
          "meta_level": ($meta|tonumber),
          "timeliness": ($time|tonumber)
        },
        "parent_a": null,
        "parent_b": null,
        "mutations": [],
        "is_elite": false
      }]')
  done

  jq -n --argjson pop "$memes" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{epoch: 0, generated_at: $t, stagnation_counter: 0, population: $pop}' > "$pop_file"

  echo "Initial population (epoch 0) generated: $pop_file"
  jq '.population[] | "\(.id): \(.genome.template) / \(.genome.humor_type) / \(.genome.topic)"' "$pop_file"
}

[[ $# -lt 1 ]] && usage

case "$1" in
  publish)         shift; cmd_publish "$@" ;;
  status)          cmd_status ;;
  init-population) cmd_init_population ;;
  *)               echo "Unknown command: $1"; usage ;;
esac
