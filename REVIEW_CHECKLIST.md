# Reviewer checklist (self-review against the brief)

| # | Requirement from the brief | Status | Evidence |
|---|---|---|---|
| **Task 1** ||||
| 1 | Pick a RealWorld / demo app, run it or use the live demo | ✅ | Live demo down (404/530), so run locally at pinned commits: [docker-compose.yml](docker-compose.yml) |
| 2 | Exercise sign-up, login, create, edit, delete, log out | ✅ | [ui-flows-log.json](task1-qa-report/evidence/ui-flows-log.json), [checks-passed.txt](task1-qa-report/evidence/checks-passed.txt) (delete, follow) |
| 3 | At least 5 issues across categories | ✅ | 10: functional, data integrity, security, error handling, validation, UX, resilience, a11y |
| 4 | Each issue in the template table (#, Title, Steps, Expected vs Actual, Severity, Cause) | ✅ | [PDF](task1-qa-report/Task1_QA_Report_SakshiDesai.pdf) section 2 |
| 5 | Severity is Critical / High / Medium / Low | ✅ | Rubric printed above the table |
| 6 | Root-cause analysis for one issue (5–10 sentences) | ✅ | PDF section 3 (what → why with file:line → fix → regression test) |
| 7 | Single PDF named `Task1_QA_Report_[YourName].pdf` | ✅ | `Task1_QA_Report_SakshiDesai.pdf` |
| 8 | Screenshots / recordings (encouraged) | ✅ | PDF appendix + [evidence/](task1-qa-report/evidence/) |
| 9 | Every bug reproduced, no invented findings | ✅ | One script per bug in [scripts/](task1-qa-report/scripts/); re-ran on a fresh clone (bugs 1 and 3 reproduced) |
| **Task 2** ||||
| 10 | Schedule (1 h) or Webhook trigger | ✅ | Both, feeding one pipeline: [canvas.png](task2-n8n-workflow/screenshots/canvas.png) |
| 11 | First HTTP Request to a free public API | ✅ | GitHub Search API |
| 12 | Transformation (Code/expressions): filter, sort, top 5 | ✅ | `Top 5 + reshape` Code node |
| 13 | Second HTTP Request enriching an item | ✅ | `GitHub: fetch README` for each of the top 5 |
| 14 | IF node with a threshold | ✅ | `Stars ≥ 1000?`, justified with real data ([DECISIONS #13](DECISIONS.md)) |
| 15 | Output to Discord / Slack / email / … | ✅ | Discord node via credential; digest + 3 failure messages posted to the real channel on 9 Nov 2026 ([discord-messages.png](task2-n8n-workflow/screenshots/discord-messages.png)). Earlier dev runs: [mock log](task2-n8n-workflow/evidence/mock-discord-log.txt) |
| 16 | Must not crash silently: Continue On Fail / Error Trigger / error branch | ✅ | All three; proven by [test-failures.sh](task2-n8n-workflow/test-failures.sh) |
| 17 | No hard-coded secrets, Credentials store only | ✅ | `discordWebhookApi` credential; `n8n-export.sh` secret scan passes; git history scan clean |
| 18 | Exported JSON `Task2_Workflow_[YourName].json` | ✅ | [Task2_Workflow_SakshiDesai.json](task2-n8n-workflow/Task2_Workflow_SakshiDesai.json), exported from n8n |
| 19 | Screenshot (a) canvas, (b) successful execution with output data | ✅ | [canvas.png](task2-n8n-workflow/screenshots/canvas.png), [successful-execution.png](task2-n8n-workflow/screenshots/successful-execution.png) |
| 20 | README ≤ 1 page: APIs, why, transformation, error path | ✅ | [task2 README](task2-n8n-workflow/README.md) |
| 21 | Happy-path curl test (optional) | ✅ | [test-webhook.sh](task2-n8n-workflow/test-webhook.sh) → PASS (also on the fresh clone) |
| **Bonus** ||||
| 22 | Pings the Task 1 app every 5 min, checks status code | ✅ | [Bonus JSON](bonus-uptime-monitor/Bonus_UptimeMonitor_SakshiDesai.json) |
| 23 | Alert on non-200 to the same channel | ✅ | DOWN → recovered → summary drill run against the real channel |
| 24 | Retry logic, response-time tracking, daily summary | ✅ | 2-in-a-row rule, ms per check, avg/p95/uptime/incidents summary |
| 25 | `Bonus_UptimeMonitor_[YourName].json` + one screenshot | ✅ | [canvas.png](bonus-uptime-monitor/screenshots/canvas.png) |
| **Submission** ||||
| 26 | Public GitHub link | ❌ | Sakshi pushes (commands in the final message) |
| 27 | Brief documentation (< 1 page) | ✅ | [README.md](README.md) |
| 28 | Loom video | ❌ | Sakshi records (script in [INTERVIEW_PREP.md](INTERVIEW_PREP.md)) |
| **Hygiene** ||||
| 29 | Fresh clone + README works | ✅ | Cloned to an empty folder → `docker compose up` (new volumes) → `n8n-setup.sh` → `test-webhook.sh` PASS |
| 30 | Filenames match the brief with `SakshiDesai` | ✅ | All 4 deliverable names checked |
