#!/usr/bin/env bash
# Shared helpers for the curl repro scripts. Target: local RealWorld API only.
set -euo pipefail
API="${API:-http://localhost:3000/api}"
EVIDENCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../evidence" && pwd)"
RUN_ID="$(date +%s)$RANDOM"

# req METHOD PATH [JSON] [TOKEN] -> prints the exact request and the response (status + body)
req() {
  local method=$1 path=$2 body=${3:-} token=${4:-}
  local args=(-s -X "$method" "$API$path" -H 'Content-Type: application/json' -w '\nHTTP %{http_code} in %{time_total}s\n')
  [[ -n $token ]] && args+=(-H "Authorization: Token $token")
  [[ -n $body ]] && args+=(-d "$body")
  echo "> $method $API$path${token:+  (Authorization: Token <jwt>)}"
  [[ -n $body ]] && echo "> body: ${body:0:300}"
  curl "${args[@]}" | sed -E 's/"token":"[^"]+"/"token":"<jwt redacted>"/g'
  echo
}

# register NAME -> echoes a JWT for a fresh user NAME_<run id>
register() {
  local u="${1}_$RUN_ID"
  curl -s -X POST "$API/users" -H 'Content-Type: application/json' \
    -d "{\"user\":{\"username\":\"$u\",\"email\":\"$u@qa.localhost\",\"password\":\"Passw0rd!123\"}}" |
    sed -E 's/.*"token":"([^"]+)".*/\1/'
}

# evidence FILE -> tee all further output of the calling script into evidence/FILE
evidence() { exec > >(tee "$EVIDENCE_DIR/$1") 2>&1; echo "# $(date -u +%FT%TZ)  run $RUN_ID"; }
