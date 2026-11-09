# Interview prep (for Sakshi)

Everything below matches what's in the repo. If you're asked about something not here, "I didn't test that, here's how I would" is a good answer.

## 15 likely questions, with short answers to say out loud

1. **Why RealWorld, and why run it locally?**
   "The public demo was down when I started: demo.realworld.io returned 404 and its API 530. Running it locally also meant my security probes only touched my own machine. I pinned exact commits in Docker Compose so anyone gets the same build."

2. **Why the Node/Express + Vue pair?**
   "Both are official gothinkster repos, so I'm testing the reference code, not someone's fork. Express plus Prisma is a very common stack for AI-generated apps, and it's TypeScript I can read quickly. The React one is archived and doesn't build on modern Node."

3. **How did you find the bugs, did you just click around?**
   "No. I read the backend first, about 600 lines, and listed risky spots: the error handler, the list queries, the update logic. Then I tried to reproduce each one with curl and Playwright. A bug only went into the report if it reproduced, and every one has a script and saved evidence."

4. **Why is bug 1 Critical?**
   "Because the product's main purpose doesn't work: people can't see each other's posts or comments. A visitor sees an empty home page. That's exactly the 'it feels broken' the brief describes. The only workaround is to follow someone, because 'Your Feed' has no filter, but you can't find anyone to follow when every list is empty, and comments stay hidden either way."

5. **Couldn't the demo filter be intentional?**
   "Probably it was intentional for the public demo server, to only show curated seed content. But in this app it's not configurable and it's on for everyone, so for a real deployment it's a bug. My fix suggestion is to remove it, or make moderation an explicit opt-in flag."

6. **Why is the tag-wipe bug High and not Critical, if it's data loss?**
   "My rubric says data loss for normal users is Critical. But the web UI always sends the tags back, so normal users don't hit it. It hits API clients and integrations, so I rated it one level lower and said why in the report."

7. **What's the security story?**
   "Access control held up: another user can't edit or delete your article, and XSS was sanitized by DOMPurify. The real risks are weaker: 1-character passwords, no login rate limit, 60-day tokens that logout doesn't revoke, and 500 errors that leak internal messages. I listed the `superSecret` fallback separately as a note, because I couldn't exploit it in my setup."

8. **Why the GitHub API for Task 2?**
   "It's free, needs no key, it's relevant to an AI team, and it has a natural second endpoint for enrichment: the README. One search plus five README calls an hour is far under the unauthenticated limits, so I didn't add a token, which would be one more secret to manage."

9. **Why the 1000-star threshold?**
   "I checked real data on 9 November: 3,854 new `llm` repos in a week. The top ones had 1587, 280, 154, 95 stars, then a flat cluster at about 54, which looks like bought stars. 1000 gets crossed about once a week, so 'Breakout' actually means something. 100 would flag several repos every week."

10. **Walk me through the error handling.**
    "Three layers. Both HTTP nodes retry 3 times, 2 seconds apart. If the search still fails, its error output posts a 'degraded' alert, because without search there's no digest. If a README fails, the workflow continues and uses the description, and the message says which README failed. Anything unexpected goes to a separate Error Trigger workflow that posts a crash alert. I proved all three with test copies of the workflow."

11. **Why a separate Error Trigger workflow if you already have error outputs?**
    "Error outputs only cover the nodes I configured. The error workflow catches everything else: a bug in a Code node, zero results, Discord rejecting the post. One thing I learned: in n8n 2.x the error workflow has to be published or it never runs."

12. **How do you keep secrets out of the repo?**
    "The Discord URL lives only in `.env`, which is gitignored, and in n8n's encrypted Credentials store. The setup script pipes it straight into n8n. The export script strips instance data and fails loudly if it finds a webhook URL, token or `.env` value. I also scan the full git history before pushing."

13. **Why only alert after 2 failed uptime checks?**
    "One failed check is often a blip, like a restart or a slow response, and alerting on it trains people to ignore alerts. Two in a row at 5-minute intervals means a real outage is still reported within 5 to 10 minutes. Three would push that to 15."

14. **How would this scale?**
    "For the monitor, move history from workflow static data to a real table and run n8n in queue mode. Static data is fine for one workflow, but overlapping runs can race; I actually saw that when firing checks 4 seconds apart. For the brief, it's 6 API calls an hour, so scaling means adding topics, and then I'd add a GitHub token and maybe cache READMEs."

15. **What would you do with more time?**
    "Turn the bug scripts into a CI test suite, starting with the two-user visibility test. Write the actual fix PR for bug 1. Add a test environment variable so the workflows can be pointed at a fake GitHub for deterministic tests. And send monitor alerts to a second channel, so a Discord outage doesn't hide them."

## Each bug in two sentences

1. **Content invisible (Critical):** Lists only show articles and comments from 'demo' accounts or from yourself, so real users never see each other's content. The cause is one `where` clause in `article.service.ts` that only includes `demo: true` or the current user.
2. **500s leak internals (High):** Normal mistakes, like commenting on a deleted article or using an email that's taken, crash with HTTP 500 and return Prisma's internal error text. The global error handler sends `err.message` for anything it doesn't recognise, and the services don't check inputs first.
3. **Tags wiped on edit (High):** Editing only the body through the API silently deletes all tags. The update always clears tags first, even when the request didn't mention tags.
4. **No brute-force protection (High):** A one-character password is accepted, and 30 wrong logins in a row aren't blocked. There's no rate-limit middleware and no password rules.
5. **Logout doesn't end the session (Medium):** After logout the old token still works for 60 days. Logout only deletes it from the browser; the server never revokes anything.
6. **Misleading errors (Medium):** When the server says "not logged in" or "email taken", the UI tells the user "Unable to connect to the server". The frontend only understands one error format and labels everything else as a network problem.
7. **Non-Latin titles (Medium):** A user can publish only one article with a fully Hindi or Chinese title; the second is rejected as "not unique". The URL slug drops non-Latin characters, so all such titles become the same slug; a title of only spaces is also accepted.
8. **Double-click duplicates (Medium):** Double-clicking "Post Comment" creates two identical comments. The comment button is never disabled while saving, unlike the article editor's.
9. **Endless loading (Low):** If the API is down, the home page shows "Loading articles..." forever with no error or retry. The error is caught and ignored, so the loading flag never turns off.
10. **Broken avatars + accessibility (Low):** Every new user's avatar is a broken image, because the default points to a domain that no longer works. axe also found images without alt text, low-contrast text and unlabeled links.

## 5-minute Loom script

| Time | Show on screen | Say |
|---|---|---|
| 0:00–0:30 | GitHub repo README | "Three parts: a QA report on a RealWorld app, an n8n morning brief, and an uptime monitor. Everything runs with one docker compose command." |
| 0:30–1:45 | PDF page 1 (summary), then the bug table | "Not production-ready. Top three risks…" Point at bug 1, 2 and 3. Mention the severity rubric. |
| 1:45–2:30 | PDF RCA page, then `article.service.ts` lines 13–25 | Explain what → why → fix → test for bug 1. Optionally run `bug-hidden-content.sh` live: Bob sees `articlesCount: 0`. |
| 2:30–3:45 | n8n canvas → run `test-webhook.sh` → Discord message → Executions view | Walk the nodes left to right; explain the 1000 threshold with the data. Then run `test-failures.sh` and show the ⚠️ degraded alert and 🚨 crash alert arriving. |
| 3:45–4:30 | Uptime canvas → `docker compose stop api` → 2× check → 🔴 → start → 🟢 → summary | "Two failures before alerting, so blips don't page anyone." |
| 4:30–5:00 | DECISIONS.md / this file's limitations | "With more time: a CI test suite from the bug scripts, a fix PR for bug 1, and a second alert channel." |

## Limitations and what I'd do next (be upfront about these)
- **Time:** the brief says 2 hours. I went further for the bonus and the evidence. If asked, say so directly and point to the summary table, which takes about 2 minutes to review.
- **One app, one browser:** tested on Chromium only (headless) and one frontend/backend pair. Firefox, Safari and mobile layouts weren't tested.
- **Static data race:** uptime checks fired less than 5 s apart can read stale state (seen in testing). It can't happen on the 5-minute schedule; a database table would remove it.
- **No load testing:** "slow responses" were only checked with network throttling, not with concurrent users (k6 would be next).
- **Discord is a single point of failure for alerts:** if Discord is down, alerts are only visible in n8n's execution list.
- **README summary is a heuristic:** it picks the first real sentence; some READMEs start with taglines or non-English text.
- **The `superSecret` JWT fallback** was found in code but not exploited, because my setup sets `JWT_SECRET`. It's listed as a note, not a bug.
- **Mock Discord during development:** all paths were proven against a local stand-in webhook (`task2-n8n-workflow/evidence/mock-discord-log.txt`), using the same Discord node and payload. Before submitting, run them once against the real channel and add a screenshot of the Discord messages (`task2-n8n-workflow/screenshots/discord-*.png`).
