#!/usr/bin/env bash
# Load the Discord webhook into n8n's Credentials store and import + publish all workflows.
# Run after `docker compose up -d`.  Usage: bash n8n-setup.sh
# The webhook URL is read from .env and piped into the container; it is never written into a workflow.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash on Windows: don't rewrite container paths like /tmp/...
cd "$(dirname "$0")"
URL="${DISCORD_WEBHOOK_URL:-$(grep -E '^DISCORD_WEBHOOK_URL=' .env | cut -d= -f2-)}"
[[ -n $URL ]] || { echo "DISCORD_WEBHOOK_URL is empty in .env" >&2; exit 1; }
n8n() { docker compose exec -T n8n "$@"; }

printf '[{"id":"mbDiscordWebhook","name":"Discord webhook","type":"discordWebhookApi","data":{"webhookUri":"%s"}}]' "$URL" |
  n8n sh -c 'cat > /tmp/cred.json && n8n import:credentials --input=/tmp/cred.json; rc=$?; rm -f /tmp/cred.json; exit $rc'

for f in task2-n8n-workflow/Task2_ErrorHandler_SakshiDesai.json \
         task2-n8n-workflow/Task2_Workflow_SakshiDesai.json \
         bonus-uptime-monitor/Bonus_UptimeMonitor_SakshiDesai.json; do
  [[ -f $f ]] || continue
  docker compose cp "$f" n8n:/tmp/wf.json
  n8n n8n import:workflow --input=/tmp/wf.json
done

# n8n 2.x only runs an Error Workflow if it is published too.
for id in mbErrorHandler01 mbMorningBrief01 mbUptimeMonitor1; do n8n n8n publish:workflow --id=$id 2>/dev/null || true; done
docker compose restart n8n   # published workflows are picked up on start
echo "Done. Open http://localhost:5678"
