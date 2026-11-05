---
name: seo-monthly-report
description: Last day of each month - build the monthly SEO report workbook for every site in config/sites.csv
---

<!--
Suggested schedule: cron "0 10 28-31 * *" (10:00 on days 28-31). The task fires on every one of
those days; STEP 0 stops it unless tomorrow is the 1st, so it runs once, on the last day of the month.
Run it from the repo root (or with MARKETING_ROOT set). Pre-approve PowerShell for the
pipelines/seo-reporting scripts, or the run stalls on a permission prompt and produces nothing.
-->

Month-end SEO report for the owner (see `config/team.md`).

STEP 0 - Guard: check whether TOMORROW is the 1st of a month (PowerShell: `(Get-Date).AddDays(1).Day -eq 1`). If not, stop immediately and output only "Not the last day of the month - skipped."

STEP 1 - Workspace: the repo root (or `%MARKETING_ROOT%` if set). The report month is the current month (YYYY-MM). Sites: every row in `config/sites.csv`.

STEP 2 - For each site's homepage (`https://<domain>/`), measure the Google DevTools page load time and page size with the built-in browser tools. Navigate to the page, then use JavaScript to read `performance.getEntriesByType('navigation')[0].loadEventEnd / 1000` (seconds), plus the sum of `transferSize` over the navigation entry and all resource entries, divided by 1048576 (MB). Skip this step if no browser is available.

STEP 3 - Run the `website-seo-specialist` agent: "Month-end SEO report for sites <keys>, month YYYY-MM, today <date>. DevTools measurements: <values>." If that agent type is not available, read its definition in `.claude/agents/` and follow it yourself. Either way, the spec is `pipelines/seo-reporting/PLAYBOOK.md`.

Rules: never estimate a missing metric (it stays "Awaiting data"), never print API keys, and never edit live websites. This run only reads data and writes report files under `seo/`. If Google returns `invalid_grant`, report that the owner must run `pipelines/seo-reporting/google-auth.ps1 -Action Login`, and still build what the other sources allow.

STEP 4 - Output a crisp summary: the workbook paths written, the top 3 improvements per site, and a checklist of optional manual inputs still missing per site (so the owner can add them to `seo/_exports/YYYY-MM/<site>/manual-inputs.csv` and rerun `/seo monthly report`).
