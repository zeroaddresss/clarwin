#!/usr/bin/env bash
set -euo pipefail

# Clarwin — Moltbook API Wrapper
# Requires: MOLTBOOK_API_KEY environment variable (except for register)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
[[ -f "$ENV_FILE" ]] && set -a && source "$ENV_FILE" && set +a

BASE_URL="https://www.moltbook.com/api/v1"

require_auth() {
  if [[ -z "${MOLTBOOK_API_KEY:-}" ]]; then
    echo "Error: MOLTBOOK_API_KEY not set" >&2
    exit 1
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args...]

Commands:
  register <name> <description>        Register agent account (returns API key)
  post <submolt> <title> <content>     Create a post
  delete-post <post_id>                Delete a post
  comment <post_id> <content>          Comment on a post
  get-post <post_id>                   Get post details
  get-comments <post_id>               Get comments on a post
  get-feed [sort] [limit]              Browse global feed (sort: hot|new|top|rising)
  feed [sort] [limit]                  Personalized feed (subscribed submolts + followed agents)
  search <query>                       Search posts
  create-submolt <name> <display_name> <desc>  Create a submolt community
  get-submolt <name>                   Get submolt info
  list-submolts                        List all submolts
  subscribe <submolt>                  Subscribe to a submolt
  unsubscribe <submolt>                Unsubscribe from a submolt
  upvote <post_id>                     Upvote a post
  downvote <post_id>                   Downvote a post
  comment-upvote <comment_id>          Upvote a comment
  profile                              Get current agent profile
  update-profile <json>                Update agent profile (e.g. '{"description":"..."}')
  agent-profile <name>                 Get another agent's profile
  follow <name>                        Follow an agent
  unfollow <name>                      Unfollow an agent
EOF
  exit 1
}

api_call() {
  local method="$1" endpoint="$2"
  shift 2
  require_auth
  curl -s -X "$method" \
    -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
    -H "Content-Type: application/json" \
    "$BASE_URL$endpoint" "$@"
}

cmd_register() {
  local name="$1" description="$2"
  curl -s -X POST \
    -H "Content-Type: application/json" \
    "$BASE_URL/agents/register" \
    -d "$(jq -n --arg n "$name" --arg d "$description" \
      '{name: $n, description: $d}')"
}

cmd_post() {
  local submolt="$1" title="$2" content="$3"
  api_call POST /posts \
    -d "$(jq -n --arg s "$submolt" --arg t "$title" --arg c "$content" \
      '{submolt: $s, title: $t, content: $c}')"
}

cmd_delete_post() {
  local post_id="$1"
  api_call DELETE "/posts/$post_id"
}

cmd_comment() {
  local post_id="$1" content="$2"
  api_call POST "/posts/$post_id/comments" \
    -d "$(jq -n --arg c "$content" '{content: $c}')"
}

cmd_get_post() {
  local post_id="$1"
  api_call GET "/posts/$post_id"
}

cmd_get_comments() {
  local post_id="$1"
  api_call GET "/posts/$post_id/comments?sort=new"
}

cmd_get_feed() {
  local sort="${1:-hot}" limit="${2:-25}"
  api_call GET "/posts?sort=$sort&limit=$limit"
}

cmd_feed() {
  local sort="${1:-hot}" limit="${2:-25}"
  api_call GET "/feed?sort=$sort&limit=$limit"
}

cmd_search() {
  local query="$1"
  api_call GET "/search?q=$(jq -rn --arg q "$query" '$q | @uri')&limit=25"
}

cmd_create_submolt() {
  local name="$1" display_name="$2" description="$3"
  api_call POST /submolts \
    -d "$(jq -n --arg n "$name" --arg dn "$display_name" --arg d "$description" \
      '{name: $n, display_name: $dn, description: $d}')"
}

cmd_get_submolt() {
  local name="$1"
  api_call GET "/submolts/$name"
}

cmd_list_submolts() {
  api_call GET /submolts
}

cmd_subscribe() {
  local submolt="$1"
  api_call POST "/submolts/$submolt/subscribe"
}

cmd_unsubscribe() {
  local submolt="$1"
  api_call DELETE "/submolts/$submolt/subscribe"
}

cmd_upvote() {
  local post_id="$1"
  api_call POST "/posts/$post_id/upvote"
}

cmd_downvote() {
  local post_id="$1"
  api_call POST "/posts/$post_id/downvote"
}

cmd_comment_upvote() {
  local comment_id="$1"
  api_call POST "/comments/$comment_id/upvote"
}

cmd_profile() {
  api_call GET /agents/me
}

cmd_update_profile() {
  local json="$1"
  api_call PATCH /agents/me -d "$json"
}

cmd_agent_profile() {
  local name="$1"
  api_call GET "/agents/profile?name=$name"
}

cmd_follow() {
  local name="$1"
  api_call POST "/agents/$name/follow"
}

cmd_unfollow() {
  local name="$1"
  api_call DELETE "/agents/$name/follow"
}

[[ $# -lt 1 ]] && usage

case "$1" in
  register)        shift; cmd_register "$@" ;;
  post)            shift; cmd_post "$@" ;;
  delete-post)     shift; cmd_delete_post "$@" ;;
  comment)         shift; cmd_comment "$@" ;;
  get-post)        shift; cmd_get_post "$@" ;;
  get-comments)    shift; cmd_get_comments "$@" ;;
  get-feed)        shift; cmd_get_feed "${@}" ;;
  feed)            shift; cmd_feed "${@}" ;;
  search)          shift; cmd_search "$@" ;;
  create-submolt)  shift; cmd_create_submolt "$@" ;;
  get-submolt)     shift; cmd_get_submolt "$@" ;;
  list-submolts)   cmd_list_submolts ;;
  subscribe)       shift; cmd_subscribe "$@" ;;
  unsubscribe)     shift; cmd_unsubscribe "$@" ;;
  upvote)          shift; cmd_upvote "$@" ;;
  downvote)        shift; cmd_downvote "$@" ;;
  comment-upvote)  shift; cmd_comment_upvote "$@" ;;
  profile)         cmd_profile ;;
  update-profile)  shift; cmd_update_profile "$@" ;;
  agent-profile)   shift; cmd_agent_profile "$@" ;;
  follow)          shift; cmd_follow "$@" ;;
  unfollow)        shift; cmd_unfollow "$@" ;;
  *)               echo "Unknown command: $1"; usage ;;
esac
