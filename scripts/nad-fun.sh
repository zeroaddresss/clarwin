#!/usr/bin/env bash
set -euo pipefail

# Clarwin — nad.fun Token Interactions
# Requires: cast (Foundry), curl, jq, MONAD_PRIVATE_KEY

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
[[ -f "$ENV_FILE" ]] && set -a && source "$ENV_FILE" && set +a

# Network configuration
NETWORK="${MONAD_NETWORK:-mainnet}"

case "$NETWORK" in
  mainnet)
    RPC_URL="${MONAD_RPC_URL:-https://rpc.monad.xyz}"
    API_URL="https://api.nadapp.net"
    ROUTER="0x6F6B8F1a20703309951a5127c45B49b1CD981A22"
    CURVE="0xA7283d07812a02AFB7C09B60f8896bCEA3F90aCE"
    LENS="0x7e78A8DE94f21804F7a17F4E8BF9EC2c872187ea"
    CHAIN_ID=143
    ;;
  testnet)
    RPC_URL="${MONAD_RPC_URL:-https://testnet-rpc.monad.xyz}"
    API_URL="https://dev-api.nad.fun"
    ROUTER="0x865054F0F6A288adaAc30261731361EA7E908003"
    CURVE="0x1228b0dc9481C11D3071E7A924B794CfB038994e"
    LENS="0xB056d79CA5257589692699a46623F901a3BB76f1"
    CHAIN_ID=10143
    ;;
  *)
    echo "Error: MONAD_NETWORK must be 'mainnet' or 'testnet' (got: $NETWORK)" >&2
    exit 1
    ;;
esac

PRIVATE_KEY="${MONAD_PRIVATE_KEY:?Error: MONAD_PRIVATE_KEY not set}"
DARWIN_TOKEN="${DARWIN_TOKEN_ADDRESS:-}"
SLIPPAGE_BPS="${SLIPPAGE_BPS:-100}"
NAD_API_KEY="${NAD_API_KEY:-}"

# API headers
api_headers() {
  local headers=(-H "Content-Type: application/json")
  [[ -n "$NAD_API_KEY" ]] && headers+=(-H "X-API-Key: $NAD_API_KEY")
  echo "${headers[@]}"
}

require_token() {
  [[ -z "$DARWIN_TOKEN" ]] && { echo "Error: DARWIN_TOKEN_ADDRESS not set" >&2; exit 1; }
}

get_wallet() {
  cast wallet address --private-key "$PRIVATE_KEY"
}

calc_slippage() {
  local amount="$1"
  # min = amount * (10000 - slippage_bps) / 10000
  echo "$(( amount * (10000 - SLIPPAGE_BPS) / 10000 ))"
}

get_deadline() {
  echo "$(( $(date +%s) + 300 ))"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args...]

Commands:
  deploy <name> <symbol> <image_path> [description]   Deploy token on nad.fun (4-step flow)
  buy <amount_mon>                                     Buy \$CRWN tokens with MON
  sell [amount_tokens|all]                             Sell \$CRWN tokens for MON
  balance [address]                                    Check token balance
  token-info                                           Get token info (REST API)
  market                                               Get market data (REST API)
  quote-buy <amount_mon>                               Get buy quote
  quote-sell <amount_tokens>                           Get sell quote
  wallet                                               Show wallet address
  fee                                                  Show deploy fee

Network: $NETWORK (chain $CHAIN_ID)
API: $API_URL
EOF
  exit 1
}

cmd_deploy() {
  local name="$1" symbol="$2" image_path="$3" description="${4:-$name token}"
  local wallet
  wallet=$(get_wallet)

  echo "=== Deploying $name ($symbol) on nad.fun ($NETWORK) ==="

  # Step 1: Upload image
  echo "[1/4] Uploading image..."
  local img_content_type="image/png"
  case "$image_path" in
    *.jpg|*.jpeg) img_content_type="image/jpeg" ;;
    *.webp) img_content_type="image/webp" ;;
    *.svg) img_content_type="image/svg+xml" ;;
    *.gif) img_content_type="image/gif" ;;
  esac

  local img_response
  img_response=$(curl -s -X POST "$API_URL/agent/token/image" \
    -H "Content-Type: $img_content_type" \
    ${NAD_API_KEY:+-H "X-API-Key: $NAD_API_KEY"} \
    --data-binary "@$image_path")

  local image_uri
  image_uri=$(echo "$img_response" | jq -r '.image_uri // empty')
  [[ -z "$image_uri" ]] && { echo "Error uploading image: $img_response" >&2; exit 1; }
  echo "  image_uri: $image_uri"

  # Step 2: Upload metadata
  echo "[2/4] Uploading metadata..."
  local meta_response
  meta_response=$(curl -s -X POST "$API_URL/agent/token/metadata" \
    -H "Content-Type: application/json" \
    ${NAD_API_KEY:+-H "X-API-Key: $NAD_API_KEY"} \
    -d "$(jq -n \
      --arg img "$image_uri" --arg n "$name" --arg s "$symbol" --arg d "$description" \
      '{image_uri: $img, name: $n, symbol: $s, description: $d}')")

  local metadata_uri
  metadata_uri=$(echo "$meta_response" | jq -r '.metadata_uri // empty')
  [[ -z "$metadata_uri" ]] && { echo "Error uploading metadata: $meta_response" >&2; exit 1; }
  echo "  metadata_uri: $metadata_uri"

  # Step 3: Mine salt
  echo "[3/4] Mining salt..."
  local salt_response
  salt_response=$(curl -s -X POST "$API_URL/agent/salt" \
    -H "Content-Type: application/json" \
    ${NAD_API_KEY:+-H "X-API-Key: $NAD_API_KEY"} \
    -d "$(jq -n \
      --arg c "$wallet" --arg n "$name" --arg s "$symbol" --arg m "$metadata_uri" \
      '{creator: $c, name: $n, symbol: $s, metadata_uri: $m}')")

  local salt predicted_address
  salt=$(echo "$salt_response" | jq -r '.salt // empty')
  predicted_address=$(echo "$salt_response" | jq -r '.address // empty')
  [[ -z "$salt" ]] && { echo "Error mining salt: $salt_response" >&2; exit 1; }
  echo "  salt: $salt"
  echo "  predicted address: $predicted_address"

  # Step 4: Create on-chain
  echo "[4/4] Creating token on-chain..."

  # Get deploy fee from Curve contract
  local fee_hex
  fee_hex=$(cast call "$CURVE" "feeConfig()(uint256,uint256,uint256)" --rpc-url "$RPC_URL" | head -1)
  local deploy_fee
  deploy_fee=$(echo "$fee_hex" | sed 's/\[.*\]//' | tr -d ' ')
  echo "  deploy fee: $deploy_fee wei ($(cast to-unit "$deploy_fee" ether) MON)"

  # Estimate gas
  local gas
  gas=$(cast estimate "$ROUTER" \
    "create((string,string,string,uint256,bytes32,uint256))" \
    "($name,$symbol,$metadata_uri,0,$salt,1)" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --value "$deploy_fee") || { echo "Gas estimation failed" >&2; exit 1; }
  # Add 10% buffer
  gas=$(( gas + gas / 10 ))

  local tx_hash
  tx_hash=$(cast send "$ROUTER" \
    "create((string,string,string,uint256,bytes32,uint256))" \
    "($name,$symbol,$metadata_uri,0,$salt,1)" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --chain "$CHAIN_ID" \
    --value "$deploy_fee" \
    --gas-limit "$gas" \
    --json | jq -r '.transactionHash')

  echo "  tx: $tx_hash"

  # Get receipt and parse token address from logs
  local receipt
  receipt=$(cast receipt "$tx_hash" --rpc-url "$RPC_URL" --json)
  local token_address
  token_address=$(echo "$receipt" | jq -r '.logs[0].topics[1] // empty' | sed 's/0x000000000000000000000000/0x/')

  echo ""
  echo "=== Token Deployed ==="
  echo "Token: ${token_address:-$predicted_address}"
  echo "TX: $tx_hash"
  echo ""
  echo "Add to .env: DARWIN_TOKEN_ADDRESS=${token_address:-$predicted_address}"
}

cmd_buy() {
  require_token
  local amount_mon="$1"
  local wallet
  wallet=$(get_wallet)
  local amount_wei
  amount_wei=$(cast to-wei "$amount_mon")

  echo "Getting buy quote for $amount_mon MON..."

  # Get quote: getAmountOut(token, amount, isBuy=true)
  local quote_result
  quote_result=$(cast call "$LENS" \
    "getAmountOut(address,uint256,bool)(address,uint256)" \
    "$DARWIN_TOKEN" "$amount_wei" true \
    --rpc-url "$RPC_URL")

  local router_addr amount_out
  router_addr=$(echo "$quote_result" | head -1 | tr -d ' ')
  amount_out=$(echo "$quote_result" | tail -1 | tr -d ' ')

  local amount_out_min
  amount_out_min=$(calc_slippage "$amount_out")
  local deadline
  deadline=$(get_deadline)

  echo "  Expected tokens: $amount_out"
  echo "  Min tokens (${SLIPPAGE_BPS}bps slippage): $amount_out_min"
  echo "  Router: $router_addr"
  echo "  Executing buy..."

  local gas
  gas=$(cast estimate "$router_addr" \
    "buy((uint256,address,address,uint256))" \
    "($amount_out_min,$DARWIN_TOKEN,$wallet,$deadline)" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --value "$amount_wei") || { echo "Gas estimation failed" >&2; exit 1; }
  gas=$(( gas + gas / 10 ))

  local tx_hash
  tx_hash=$(cast send "$router_addr" \
    "buy((uint256,address,address,uint256))" \
    "($amount_out_min,$DARWIN_TOKEN,$wallet,$deadline)" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --chain "$CHAIN_ID" \
    --value "$amount_wei" \
    --gas-limit "$gas" \
    --json | jq -r '.transactionHash')

  echo "  Buy TX: $tx_hash"
}

cmd_sell() {
  require_token
  local wallet
  wallet=$(get_wallet)

  # Get balance
  local balance
  balance=$(cast call "$DARWIN_TOKEN" "balanceOf(address)(uint256)" "$wallet" --rpc-url "$RPC_URL" | tr -d ' ')

  local amount
  if [[ "${1:-all}" == "all" ]]; then
    amount="$balance"
  else
    amount=$(cast to-wei "$1")
  fi

  [[ "$amount" == "0" ]] && { echo "Nothing to sell."; exit 0; }

  echo "Selling $amount tokens..."

  # Get quote: getAmountOut(token, amount, isBuy=false)
  local quote_result
  quote_result=$(cast call "$LENS" \
    "getAmountOut(address,uint256,bool)(address,uint256)" \
    "$DARWIN_TOKEN" "$amount" false \
    --rpc-url "$RPC_URL")

  local router_addr amount_out
  router_addr=$(echo "$quote_result" | head -1 | tr -d ' ')
  amount_out=$(echo "$quote_result" | tail -1 | tr -d ' ')

  local amount_out_min
  amount_out_min=$(calc_slippage "$amount_out")
  local deadline
  deadline=$(get_deadline)

  echo "  Expected MON: $(cast from-wei "$amount_out")"
  echo "  Min MON (${SLIPPAGE_BPS}bps slippage): $(cast from-wei "$amount_out_min")"

  # Approve
  echo "  Approving router..."
  cast send "$DARWIN_TOKEN" "approve(address,uint256)" "$router_addr" "$amount" \
    --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" --chain "$CHAIN_ID" --json > /dev/null

  # Sell
  echo "  Executing sell..."
  local gas
  gas=$(cast estimate "$router_addr" \
    "sell((uint256,uint256,address,address,uint256))" \
    "($amount,$amount_out_min,$DARWIN_TOKEN,$wallet,$deadline)" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY") || { echo "Gas estimation failed" >&2; exit 1; }
  gas=$(( gas + gas / 10 ))

  local tx_hash
  tx_hash=$(cast send "$router_addr" \
    "sell((uint256,uint256,address,address,uint256))" \
    "($amount,$amount_out_min,$DARWIN_TOKEN,$wallet,$deadline)" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --chain "$CHAIN_ID" \
    --gas-limit "$gas" \
    --json | jq -r '.transactionHash')

  echo "  Sell TX: $tx_hash"
}

cmd_balance() {
  require_token
  local address="${1:-$(get_wallet)}"
  local balance
  balance=$(cast call "$DARWIN_TOKEN" "balanceOf(address)(uint256)" "$address" --rpc-url "$RPC_URL" | tr -d ' ')
  echo "Balance: $balance ($(cast from-wei "$balance") tokens)"
}

cmd_token_info() {
  require_token
  local response
  response=$(curl -s "$API_URL/agent/token/$DARWIN_TOKEN" \
    ${NAD_API_KEY:+-H "X-API-Key: $NAD_API_KEY"})
  echo "$response" | jq '.token_info | {name, symbol, description, image_uri, is_graduated, creator}'
}

cmd_market() {
  require_token
  local response
  response=$(curl -s "$API_URL/agent/market/$DARWIN_TOKEN" \
    ${NAD_API_KEY:+-H "X-API-Key: $NAD_API_KEY"})
  echo "$response" | jq '.market_info | {market_type, price_usd, holder_count, volume, ath_price}'
}

cmd_quote_buy() {
  require_token
  local amount_wei
  amount_wei=$(cast to-wei "$1")
  local result
  result=$(cast call "$LENS" \
    "getAmountOut(address,uint256,bool)(address,uint256)" \
    "$DARWIN_TOKEN" "$amount_wei" true \
    --rpc-url "$RPC_URL")
  local amount_out
  amount_out=$(echo "$result" | tail -1 | tr -d ' ')
  echo "Buy $1 MON → ~$(cast from-wei "$amount_out") tokens (before slippage)"
}

cmd_quote_sell() {
  require_token
  local amount_wei
  amount_wei=$(cast to-wei "$1")
  local result
  result=$(cast call "$LENS" \
    "getAmountOut(address,uint256,bool)(address,uint256)" \
    "$DARWIN_TOKEN" "$amount_wei" false \
    --rpc-url "$RPC_URL")
  local amount_out
  amount_out=$(echo "$result" | tail -1 | tr -d ' ')
  echo "Sell $1 tokens → ~$(cast from-wei "$amount_out") MON (before slippage)"
}

cmd_wallet() {
  get_wallet
}

cmd_fee() {
  local fee_result
  fee_result=$(cast call "$CURVE" "feeConfig()(uint256,uint256,uint256)" --rpc-url "$RPC_URL")
  local deploy_fee
  deploy_fee=$(echo "$fee_result" | head -1 | tr -d ' ')
  echo "Deploy fee: $deploy_fee wei ($(cast to-unit "$deploy_fee" ether) MON)"
}

[[ $# -lt 1 ]] && usage

case "$1" in
  deploy)     shift; cmd_deploy "$@" ;;
  buy)        shift; cmd_buy "$@" ;;
  sell)       shift; cmd_sell "${@:-all}" ;;
  balance)    shift; cmd_balance "${@:-}" ;;
  token-info) cmd_token_info ;;
  market)     cmd_market ;;
  quote-buy)  shift; cmd_quote_buy "$@" ;;
  quote-sell) shift; cmd_quote_sell "$@" ;;
  wallet)     cmd_wallet ;;
  fee)        cmd_fee ;;
  *)          echo "Unknown command: $1"; usage ;;
esac
