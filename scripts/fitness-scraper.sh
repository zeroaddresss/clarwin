#!/usr/bin/env bash
set -euo pipefail

# Clarwin — Fitness Scraper
# Collects Moltbook engagement metrics for fitness calculation

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Source .env for standalone execution (OpenClaw sets env vars for cron runs)
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
[[ -f "$ENV_FILE" ]] && set -a && source "$ENV_FILE" && set +a

DATA_DIR="$(dirname "$SCRIPT_DIR")/data"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args...]

Commands:
  collect <epoch_num>    Collect fitness data for an epoch's memes
  report <epoch_num>     Print fitness summary for an epoch
EOF
  exit 1
}

word_count() {
  echo "$1" | wc -w | tr -d ' '
}

cmd_collect() {
  local epoch="$1"
  local status_file="$DATA_DIR/population/publish-status-epoch-${epoch}.json"
  local fitness_file="$DATA_DIR/fitness-logs/epoch-${epoch}.json"

  [[ ! -f "$status_file" ]] && { echo "Error: No publish status for epoch $epoch"; exit 1; }

  mkdir -p "$DATA_DIR/fitness-logs"

  local meme_data="[]"
  local max_raw=0

  # First pass: collect raw engagement data
  local meme_count
  meme_count=$(jq '.memes | length' "$status_file")

  for i in $(seq 0 $((meme_count - 1))); do
    local entry
    entry=$(jq ".memes[$i]" "$status_file")
    local meme_id post_id status
    meme_id=$(echo "$entry" | jq -r '.id')
    post_id=$(echo "$entry" | jq -r '.post_id')
    status=$(echo "$entry" | jq -r '.status')

    if [[ "$status" != "published" || "$post_id" == "unknown" ]]; then
      meme_data=$(echo "$meme_data" | jq --arg id "$meme_id" \
        '. += [{"id": $id, "post_id": "none", "upvotes": 0, "downvotes": 0, "comments": 0, "avg_comment_depth": 0, "raw_fitness": 0}]')
      continue
    fi

    # Fetch post data
    local post_data
    post_data=$("$SCRIPT_DIR/moltbook-api.sh" get-post "$post_id" 2>/dev/null) || post_data='{}'

    local upvotes downvotes
    upvotes=$(echo "$post_data" | jq '.upvotes // 0')
    downvotes=$(echo "$post_data" | jq '.downvotes // 0')
    local net_upvotes=$((upvotes > downvotes ? upvotes - downvotes : 0))

    # Fetch comments
    local comments_data
    comments_data=$("$SCRIPT_DIR/moltbook-api.sh" get-comments "$post_id" 2>/dev/null) || comments_data='[]'

    local comment_count
    comment_count=$(echo "$comments_data" | jq 'if type == "array" then length else 0 end')

    # Calculate average comment depth (word count)
    local avg_depth=0
    if [[ "$comment_count" -gt 0 ]]; then
      local total_words=0
      for j in $(seq 0 $((comment_count - 1))); do
        local comment_text
        comment_text=$(echo "$comments_data" | jq -r ".[$j].content // \"\"")
        total_words=$((total_words + $(word_count "$comment_text")))
      done
      avg_depth=$((total_words / comment_count))
    fi

    # Raw fitness: (upvotes x 3) + (comments x 5) + (avg_comment_depth x 2)
    local raw=$((net_upvotes * 3 + comment_count * 5 + avg_depth * 2))
    [[ $raw -gt $max_raw ]] && max_raw=$raw

    meme_data=$(echo "$meme_data" | jq \
      --arg id "$meme_id" --arg pid "$post_id" \
      --argjson up "$net_upvotes" --argjson down "$downvotes" \
      --argjson com "$comment_count" --argjson depth "$avg_depth" \
      --argjson raw "$raw" \
      '. += [{"id": $id, "post_id": $pid, "upvotes": $up, "downvotes": $down, "comments": $com, "avg_comment_depth": $depth, "raw_fitness": $raw}]')
  done

  # Handle zero engagement case
  [[ $max_raw -eq 0 ]] && max_raw=1

  # Compute population centroid for diversity bonus
  local pop_file="$DATA_DIR/population/current.json"
  local categorical_genes=("template" "humor_type" "topic" "tone" "format" "text_style" "crypto_reference")
  local centroid="{}"

  if [[ -f "$pop_file" ]]; then
    for gene in "${categorical_genes[@]}"; do
      # Mode = most common value; ties broken alphabetically (sort | head)
      local mode
      mode=$(jq -r ".population[].genome.$gene" "$pop_file" | sort | uniq -c | sort -rn -k1 -k2 | head -1 | awk '{print $2}')
      centroid=$(echo "$centroid" | jq --arg g "$gene" --arg v "$mode" '. + {($g): $v}')
    done
  fi

  # Second pass: normalize and compute final fitness
  local final_memes="[]"
  for i in $(seq 0 $((meme_count - 1))); do
    local meme
    meme=$(echo "$meme_data" | jq ".[$i]")
    local raw
    raw=$(echo "$meme" | jq '.raw_fitness')
    local meme_id
    meme_id=$(echo "$meme" | jq -r '.id')

    # Normalized fitness (scale 0 to 1)
    local normalized
    normalized=$(echo "scale=4; $raw / $max_raw" | bc)

    # Diversity bonus: 0.1 * (1 - jaccard_similarity_to_centroid)
    local diversity_bonus="0.05"
    if [[ -f "$pop_file" ]]; then
      local matches=0
      local genome
      genome=$(jq -r --arg id "$meme_id" '.population[] | select(.id == $id) | .genome' "$pop_file" 2>/dev/null) || genome=""
      if [[ -n "$genome" ]]; then
        for gene in "${categorical_genes[@]}"; do
          local gene_val centroid_val
          gene_val=$(echo "$genome" | jq -r ".$gene")
          centroid_val=$(echo "$centroid" | jq -r ".$gene")
          [[ "$gene_val" == "$centroid_val" ]] && matches=$((matches + 1))
        done
        local jaccard
        jaccard=$(echo "scale=4; $matches / 7" | bc)
        diversity_bonus=$(echo "scale=4; 0.1 * (1 - $jaccard)" | bc)
      fi
    fi

    local final
    final=$(echo "scale=4; $normalized + $diversity_bonus" | bc)

    final_memes=$(echo "$final_memes" | jq \
      --argjson m "$meme" \
      --arg norm "$normalized" --arg div "$diversity_bonus" --arg fin "$final" \
      '. += [$m + {"normalized_fitness": ($norm|tonumber), "diversity_bonus": ($div|tonumber), "a2a_modifier": 0, "final_fitness": ($fin|tonumber)}]')
  done

  # Compute population stats
  local stats
  stats=$(echo "$final_memes" | jq '{
    mean_fitness: ([.[].final_fitness] | add / length),
    max_fitness: ([.[].final_fitness] | max),
    min_fitness: ([.[].final_fitness] | min),
    best_genome_id: (sort_by(-.final_fitness) | first | .id),
    worst_genome_id: (sort_by(.final_fitness) | first | .id)
  }')

  # Write fitness file
  jq -n \
    --argjson e "$epoch" \
    --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson stats "$stats" \
    --argjson memes "$final_memes" \
    '{epoch: $e, collected_at: $t, population_stats: $stats, memes: $memes}' > "$fitness_file"

  echo "Fitness data collected for epoch $epoch: $fitness_file"
  echo "$stats" | jq '.'
}

cmd_report() {
  local epoch="$1"
  local fitness_file="$DATA_DIR/fitness-logs/epoch-${epoch}.json"
  [[ ! -f "$fitness_file" ]] && { echo "Error: No fitness data for epoch $epoch"; exit 1; }

  echo "=== Epoch $epoch Fitness Report ==="
  jq -r '.population_stats | "Mean: \(.mean_fitness) | Max: \(.max_fitness) | Min: \(.min_fitness)\nBest: \(.best_genome_id) | Worst: \(.worst_genome_id)"' "$fitness_file"
  echo ""
  echo "--- Meme Rankings ---"
  jq -r '.memes | sort_by(-.final_fitness)[] | "\(.id): fitness=\(.final_fitness) (up=\(.upvotes) com=\(.comments))"' "$fitness_file"
}

[[ $# -lt 1 ]] && usage

case "$1" in
  collect) shift; cmd_collect "$@" ;;
  report)  shift; cmd_report "$@" ;;
  *)       echo "Unknown command: $1"; usage ;;
esac
