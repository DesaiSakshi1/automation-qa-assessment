#!/usr/bin/env bash
# Export the running workflows from n8n into the deliverable files, in the same shape as the
# editor's "Download" menu, then fail loudly if anything that looks like a secret is inside.
#   bash n8n-export.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
declare -A FILES=(
  [mbMorningBrief01]=task2-n8n-workflow/Task2_Workflow_SakshiDesai.json
  [mbErrorHandler01]=task2-n8n-workflow/Task2_ErrorHandler_SakshiDesai.json
  [mbUptimeMonitor1]=bonus-uptime-monitor/Bonus_UptimeMonitor_SakshiDesai.json
)
for id in "${!FILES[@]}"; do
  docker compose exec -T n8n n8n export:workflow --id="$id" --output=/tmp/export.json >/dev/null
  docker compose cp n8n:/tmp/export.json .export.tmp.json >/dev/null
  node -e '
    const fs = require("fs"); const [src, dst] = process.argv.slice(1);
    const w = [].concat(JSON.parse(fs.readFileSync(src, "utf8")))[0];
    const keep = ["name", "nodes", "pinData", "connections", "active", "settings", "versionId", "meta", "id", "tags"];
    fs.writeFileSync(dst, JSON.stringify(Object.fromEntries(keep.map((k) => [k, w[k]])), null, 2) + "\n");
  ' .export.tmp.json "${FILES[$id]}"
  echo "exported $id -> ${FILES[$id]}"
done
rm -f .export.tmp.json

# Secret scan: webhook URLs, GitHub tokens, JWTs, bearer headers, and the local .env values.
PATTERN='discord(app)?\.com/api/webhooks|hooks\.slack\.com|ghp_[A-Za-z0-9]{20}|github_pat_|eyJ[A-Za-z0-9_-]{10,}\.|Bearer [A-Za-z0-9._-]{20,}|@qa\.localhost'
if grep -nEi "$PATTERN" "${FILES[@]}"; then echo "SECRET SCAN FAILED: see lines above" >&2; exit 1; fi
if [[ -f .env ]]; then
  while IFS='=' read -r k v; do
    [[ ${#v} -ge 8 ]] && grep -nF -- "$v" "${FILES[@]}" && { echo "SECRET SCAN FAILED: value of $k found" >&2; exit 1; }
  done < <(grep -E '^[A-Z_]+=.' .env)
fi
echo "Secret scan passed."
