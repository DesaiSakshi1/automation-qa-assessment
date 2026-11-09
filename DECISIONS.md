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
