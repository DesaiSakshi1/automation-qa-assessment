#!/usr/bin/env bash
# Proves the 3 error paths by importing [TEST] copies of the Morning Brief, each with one fault:
#   search-fail : GitHub search URL is wrong (404)      -> "⚠️ Morning brief degraded" alert
#   readme-fail : README URL is wrong (404 for all 5)    -> digest still sent, with a ⚠️ footer
#   crash       : search returns 0 repos, Code node throws -> Error Trigger workflow posts "🚨 crashed"
# Copies have no schedule trigger, only a webhook. The real workflow is not modified.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
TMP=task2-n8n-workflow/.tmp-variants; mkdir -p "$TMP"
node - "$TMP" <<'JS'
const fs = require('fs'); const dir = process.argv[2];
const base = JSON.parse(fs.readFileSync('task2-n8n-workflow/Task2_Workflow_SakshiDesai.json', 'utf8'));
const variants = {
  'search-fail': (w) => { node(w, 'GitHub: search new LLM repos').parameters.url = 'https://api.github.com/search/repositoriesX'; },
  'readme-fail': (w) => { node(w, 'GitHub: fetch README').parameters.url = '=https://api.github.com/repos/{{ $json.name }}/readmeX'; },
  'crash':       (w) => { node(w, 'GitHub: search new LLM repos').parameters.queryParameters.parameters[0].value = 'topic:no-such-topic-qa-test-xyz'; },
};
function node(w, name) { return w.nodes.find((n) => n.name === name); }
Object.entries(variants).forEach(([key, mutate], i) => {
  const w = structuredClone(base);
  w.id = `mbTestVariant0${i + 1}`; w.name = `[TEST] Morning Brief – ${key}`;
  w.nodes = w.nodes.filter((n) => n.name !== 'Every hour'); delete w.connections['Every hour'];
  const hook = node(w, 'Webhook (curl test)');
  hook.parameters.path = `morning-brief-test-${key}`; hook.webhookId = `00000000-0000-4000-8000-00000000000${i + 1}`;
  mutate(w);
  fs.writeFileSync(`${dir}/${key}.json`, JSON.stringify(w));
});
JS
for key in search-fail readme-fail crash; do
  docker compose cp "$TMP/$key.json" n8n:/tmp/wf.json >/dev/null
  docker compose exec -T n8n n8n import:workflow --input=/tmp/wf.json 2>&1 | grep -i 'success' || true
done
for i in 1 2 3; do docker compose exec -T n8n n8n publish:workflow --id=mbTestVariant0$i 2>&1 | grep -i publishing || true; done
docker compose restart n8n >/dev/null
until curl -sf http://localhost:5678/healthz/readiness >/dev/null; do sleep 2; done; sleep 3
for key in search-fail readme-fail crash; do
  echo "== $key"; curl -s -X POST "http://localhost:5678/webhook/morning-brief-test-$key" --max-time 120 -w '\nHTTP %{http_code}\n' || true
done
rm -rf "$TMP"
echo "Now check the Discord channel (and the Executions list in n8n) for the 3 messages."
