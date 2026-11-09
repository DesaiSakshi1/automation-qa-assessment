# Decisions

Format: **Decision** → alternatives considered → why.

## Task 1
1. **Run RealWorld locally instead of the public demo** → demo.realworld.io / other hosted demos → the public demo is down (checked 2026-11-09: 404 on the site, 530 on `api.realworld.io`). Local also means security probes only hit my own machine.
2. **Backend: Node/Express + Prisma (official gothinkster repo)** → Django, NestJS, Go → most common stack for "AI-built" apps, TypeScript I can read quickly, and an official repo so I'm not testing someone's fork. Postgres runs in the same Compose file.
3. **Frontend: Vue 3 (official gothinkster repo)** → React-Redux (archived, Create-React-App, fails on modern Node), Angular → maintained, builds with Vite in seconds.
4. **Pin exact commits and build from Git URLs in Compose** → vendoring the source, `git submodule` → no third-party code in my repo, and anyone gets exactly the same build.
5. **Severity rubric** (used for every bug):
   Critical = core purpose broken or data loss for normal users, no workaround · High = security weakness with real impact, or data loss/failure in a main flow · Medium = wrong behaviour with a workaround / info leak · Low = cosmetic, a11y polish, hardening.
6. **Read the source first, then reproduce** → pure black-box clicking → reading the ~600-line backend found 5 of the 10 bugs in minutes; every one was then proven at runtime. Nothing that only exists in code review is counted as a bug (the `'superSecret'` fallback is listed as a note).
7. **RCA on bug #1 (hidden content), not a security bug** → tag-wipe (data integrity), 500 leaks (security) → it has the biggest user impact and directly explains the brief's "it feels broken", and the cause is one clear `where` clause I can point to.
8. **Tag-wipe rated High, not Critical** → the rubric says data loss = Critical, but the web UI always resends tags, so only API clients hit it.
9. **curl scripts in bash, edge cases with Unicode in Node** → curl from Windows mangled UTF-8 (a false lead I ruled out), so Unicode tests use Node's `fetch`.
10. **Report: HTML → PDF with Playwright** → Word, Google Docs → source stays in git and diffable; the same Chromium that tested the app prints the report.

## Task 2 – Morning Brief
11. **GitHub Search API, topic `llm`, last 7 days** → HackerNews, CoinGecko, OpenWeather → free with no key, relevant to an AI team, and has a natural second endpoint (README) for enrichment. `topic:llm` is set by repo owners, so it's less noisy than full-text search (14,371 vs 3,854 results).
12. **No GitHub token** → token in n8n Credentials → 6 calls/hour is far below the unauthenticated limits (10/min search, 60/h core). A token is one more secret to manage for no gain. If needed: add a "Header Auth" credential `Authorization: Bearer <token>` to both HTTP nodes.
13. **Threshold `stars ≥ 1000`** → 100 / 500 → based on data from 9 Nov 2026: top 7-day `llm` repos had 1587, 280, 154, 95 stars, then a flat cluster at ~54 (probably bought stars). 1000 is crossed about once a week, so "Breakout" means something. 100 would flag 3+ repos every week.
14. **README for all top 5, not just #1** → #1 only → same node, 5 calls/hour, and every line in the digest gets a summary.
15. **Different error handling per HTTP node.** Search uses *error output → alert*, because without search data there's no digest. README uses *continue on error*, because the digest is still useful without summaries (graceful degradation). Both retry 3 times, 2 s apart.
16. **Separate Error Trigger workflow** → only per-node error outputs → catches everything the error outputs can't (code bugs, 0 results, Discord failure). It must be **published** to run in n8n 2.x (found during testing).
17. **Schedule + Webhook triggers feeding the same nodes** → two copies → one pipeline. The webhook makes it testable with curl, as the brief allows.
18. **IF → two Set nodes → Merge**, rather than computing the section inside a Code node → shows the brief's required IF branch on the canvas; Merge (append) joins the branches back into one digest.
19. **Discord node with a webhook credential** → HTTP Request to the webhook URL → the URL would then sit in the node as plain text. The credential keeps it encrypted in n8n.
20. **Failure tests use `[TEST]` copies** (`test-failures.sh`) → editing the real workflow by hand → reproducible, and the real workflow is never modified.
21. **Workflows written as JSON, imported with the n8n CLI, then exported back** → building by hand in the UI → reviewable in git, and `n8n-export.sh` produces the same shape as the editor's Download menu, then secret-scans it.

## Bonus – Uptime monitor
22. **Alert after 2 consecutive failures** → 1 (noisy) / 3 (15-minute delay) → see bonus README.
23. **Code node with `this.helpers.httpRequest` for pings** → HTTP Request node → the HTTP Request node doesn't expose response time.
24. **Workflow static data for history** → Google Sheet / Postgres table → no extra credential or service. Trade-off: it only persists for production (published) runs, and overlapping runs can race.
25. **Docker service names (`web`, `api`)** → `host.docker.internal` → n8n and the app share a Compose network. Vite needed `__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS=web` (a 403 false positive found in testing).
26. **Mock Discord for development** (a container that logs request bodies) → waiting for the real webhook → let me prove every path early. The final evidence must come from the real channel.
