#!/usr/bin/env bash
# Happy-path test: fire the Morning Brief webhook and check it completed.
# Usage: bash task2-n8n-workflow/test-webhook.sh [base-url]
set -euo pipefail
BASE="${1:-http://localhost:5678}"
OUT=$(mktemp)
CODE=$(curl -s -o "$OUT" -w '%{http_code}' -X POST "$BASE/webhook/morning-brief" --max-time 120)
echo "HTTP $CODE"; cat "$OUT"; echo
[[ $CODE == 200 ]] || { echo "FAIL: expected HTTP 200"; exit 1; }
grep -q '"error"' "$OUT" && { echo "FAIL: workflow returned an error"; exit 1; }
echo "PASS: workflow ran end to end (digest posted to Discord)"
