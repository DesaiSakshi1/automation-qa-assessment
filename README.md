# Automation & QA Developer – Take-home (Sakshi Desai)

| Task | Deliverable | One-line result |
|---|---|---|
| **1. Web app QA** | [Task1_QA_Report_SakshiDesai.pdf](task1-qa-report/Task1_QA_Report_SakshiDesai.pdf) | RealWorld "Conduit" is **not production-ready**: 10 reproduced issues (1 Critical, 3 High, 4 Medium, 2 Low) + root-cause analysis. The worst: users can't see each other's articles or comments. |
| **2. n8n workflow** | [Task2_Workflow_SakshiDesai.json](task2-n8n-workflow/Task2_Workflow_SakshiDesai.json) · [README](task2-n8n-workflow/README.md) · [screenshots](task2-n8n-workflow/screenshots/) | Hourly "Morning Brief": new GitHub `llm` repos → top 5 → README summaries → IF ≥ 1000 ⭐ → Discord. Retries, error-output alert, graceful degradation, and an [Error Trigger workflow](task2-n8n-workflow/Task2_ErrorHandler_SakshiDesai.json). |
| **Bonus. Uptime monitor** | [Bonus_UptimeMonitor_SakshiDesai.json](bonus-uptime-monitor/Bonus_UptimeMonitor_SakshiDesai.json) · [README](bonus-uptime-monitor/README.md) | Checks the Task 1 app every 5 min; alerts after 2 failures in a row, posts "recovered", plus a daily uptime / avg / p95 / incident summary. |

How I worked: [PLAN.md](PLAN.md) · every choice with alternatives: [DECISIONS.md](DECISIONS.md)

## Run everything (≈10 min, needs Docker, Node 20+, bash)
```bash
cp .env.example .env              # fill DISCORD_WEBHOOK_URL and any local passwords
docker compose up -d --build      # app http://localhost:8080 · API :3000 · n8n http://localhost:5678
bash n8n-setup.sh                 # webhook → n8n Credentials; import + publish the 3 workflows
```
Create the n8n owner account at http://localhost:5678 on first visit.

## Re-check the findings and the error paths
```bash
npm ci && npx playwright install chromium
bash task1-qa-report/scripts/bug-hidden-content.sh      # each bug-*.sh writes its log to task1-qa-report/evidence/
node task1-qa-report/scripts/ui-flows.mjs               # UI flows, double-submit, API-down, axe-core
npm run pdf                                             # rebuild the report from report-source/report.html
bash task2-n8n-workflow/test-webhook.sh                 # happy path → PASS
bash task2-n8n-workflow/test-failures.sh                # degraded alert, README fallback, crash alert
```

## Repo map
```
task1-qa-report/     report PDF, HTML source, repro scripts (curl + Playwright), evidence per bug
task2-n8n-workflow/  workflow + error-handler JSON, README, screenshots, test scripts
bonus-uptime-monitor/ workflow JSON, README, screenshot
docker-compose.yml   RealWorld (pinned commits) + Postgres + n8n 2.46.7
n8n-setup.sh / n8n-export.sh   load credentials + import / export + secret-scan
```
**Secrets:** only in `.env` (gitignored) and n8n's encrypted Credentials store. No webhook URL, token or password is in any committed file; `n8n-export.sh` fails if one appears in an exported workflow.
