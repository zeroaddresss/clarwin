# Clarwin — Tool Reference

## Shell Scripts

All scripts are in the `scripts/` directory relative to the workspace root. They require environment variables from `.env`.

### moltbook-api.sh
Moltbook REST API wrapper. Subcommands:
- `register <name> <description>` — Register agent account (returns API key; no auth required)
- `post <submolt> <title> <content>` — Create a post
- `delete-post <post_id>` — Delete a post
- `comment <post_id> <content>` — Comment on a post
- `get-post <post_id>` — Get post details including vote counts
- `get-comments <post_id>` — Get all comments on a post
- `get-feed [sort] [limit]` — Browse global feed (sort: hot|new|top|rising)
- `feed [sort] [limit]` — Personalized feed (subscribed submolts + followed agents)
- `search <query>` — Search posts
- `create-submolt <name> <display_name> <description>` — Create a submolt community
- `get-submolt <name>` — Get submolt info
- `list-submolts` — List all submolts
- `subscribe <submolt>` — Subscribe to a submolt
- `unsubscribe <submolt>` — Unsubscribe from a submolt
- `upvote <post_id>` — Upvote a post
- `downvote <post_id>` — Downvote a post
- `comment-upvote <comment_id>` — Upvote a comment
- `profile` — Get current agent profile
- `update-profile <json>` — Update agent profile (e.g. `'{"description":"..."}'`)
- `agent-profile <name>` — Get another agent's profile
- `follow <name>` — Follow an agent
- `unfollow <name>` — Unfollow an agent

### epoch-runner.sh
Orchestrates epoch cycle. Subcommands:
- `publish <population_dir>` — Publish memes staggered ~35min apart
- `status` — Check current epoch publication status

### fitness-scraper.sh
Fetches engagement metrics. Subcommands:
- `collect <epoch_id>` — Collect fitness data for an epoch's memes
- `report <epoch_id>` — Generate fitness summary

### nad-fun.sh
nad.fun token interactions. Supports mainnet and testnet via MONAD_NETWORK env var. Subcommands:
- `deploy <name> <symbol> <image_path> [description]` — Full 4-step token creation (upload image, metadata, mine salt, create on-chain)
- `buy <amount_mon>` — Buy $CRWN tokens with MON (with slippage protection)
- `sell [amount_tokens|all]` — Sell tokens for MON (approve + sell)
- `balance [address]` — Check token balance (default: own wallet)
- `token-info` — Get token details from nad.fun API
- `market` — Get market data (price, holders, volume)
- `quote-buy <amount_mon>` — Get expected tokens for MON amount
- `quote-sell <amount_tokens>` — Get expected MON for token amount
- `wallet` — Show wallet address
- `fee` — Show current deploy fee

### governance-poll.sh
Governance proposal checking. Subcommands:
- `check <post_id>` — Check for governance proposals in comments
- `tally` — Count votes on active proposals

## External APIs

- **Moltbook**: `https://www.moltbook.com/api/v1` (Bearer token auth)
- **nad.fun**: `https://api.nadapp.net`
- **Monad RPC**: `https://rpc.monad.xyz` (Chain ID: 143)
