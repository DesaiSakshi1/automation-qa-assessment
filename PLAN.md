# Plan

Source of truth: the assessment brief (4 pages). Brief's time box is **2 hours total**; this submission goes further on purpose (bonus task, evidence per bug), but every piece is kept small enough to explain in the follow-up call.

## Phase 0 – Scaffold
Repo layout as in README. One `docker-compose.yml` runs the Task 1 app **and** n8n. Secrets live only in `.env` (gitignored) and n8n's Credentials store.

## Phase 1 – Task 1: QA report
- App: `demo.realworld.io` was checked on 2026-11-09 and is down (404; its API returns 530). So RealWorld runs locally:
  - Backend: `gothinkster/node-express-realworld-example-app` @ `30b68e1e881462b2f4164ea09ab4c4f5699c7b0b` (Express + Prisma + Postgres)
  - Frontend: `gothinkster/vue-realworld-example-app` @ `db749e3bb1a45755e0a3f4065abaf7346f004f36` (Vue 3 + Vite)
- Method: read the backend source for risky spots → reproduce each with curl (API) and Playwright (UI) → keep only what reproduced, with evidence.
- Coverage: core flows (sign-up, login, article CRUD, comments, follow/favorite, logout), validation edge cases, auth/session, IDOR with 2 accounts, XSS (harmless payloads, local only), error leakage, rate limiting, double submit, API-down UI, axe-core accessibility.
- Report: HTML → PDF with Playwright; each page rendered to PNG and checked by eye.

## Phase 2 – Task 2: n8n "Morning Brief"
Schedule (1h) + Webhook → GitHub Search (new AI/LLM repos, last 7 days) → Code (top 5, reshape) → GitHub README for #1 → IF stars > threshold → Discord.
Error path: retries on HTTP nodes, error outputs → "degraded" Discord alert, README failure still sends the digest, separate Error Trigger workflow.

## Phase 3 – Bonus: uptime monitor
Every 5 min: GET frontend + API → record status and time → alert after 2 consecutive failures, "recovered" message on the way back → daily summary from workflow static data.

## Phase 4 – Review pass
Checklist against the brief, secret scan of full history, fresh-clone test, exact filenames. Commit locally; push is done by Sakshi.

## Phase 5 – Interview prep
`INTERVIEW_PREP.md`: likely questions, per-bug talking points, Loom script, limitations.

## Assumptions
- Notification channel: Discord webhook (user's choice).
- n8n runs locally in Docker (n8n's own docs list Docker as a supported self-host method).
- Security probes only against the local instance.
