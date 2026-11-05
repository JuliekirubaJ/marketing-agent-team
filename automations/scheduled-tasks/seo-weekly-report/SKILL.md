---
name: seo-weekly-report
description: Monday - weekly SEO workbook per site (Weekly Summary, Keyword Ranking, AEO answers/traffic/health, Content Updates) and the combined Ranking & AEO tracker
---

<!--
Suggested schedule: Mondays at 10:00 (cron "0 10 * * 1").
Run it from the repo root (or with MARKETING_ROOT set). Pre-approve PowerShell for the
pipelines/seo-reporting scripts so the unattended run does not stall on a permission prompt.
-->

Weekly SEO + AEO report for the owner (see `config/team.md`).

Week: the most recent complete Monday-Sunday week, ending yesterday or earlier. Label it with the Monday that follows it (YYYY-MM-DD). Sites: every row in `config/sites.csv`.

The spec is the "Weekly report" section of `pipelines/seo-reporting/PLAYBOOK.md`. Follow it exactly.

Run the `website-seo-specialist` agent: "Weekly report for sites <keys>, week <Mon>-<Sun>, label <date>." If that agent type is not available, read its definition in `.claude/agents/` and follow it yourself.

For each site, write everything to `seo/_exports/weekly/<label>/<site>/` (scripts in `pipelines/seo-reporting/`):
- `seo-report.ps1 -Action Prep -Week <label> -Site <site>`
- `fetch-google.ps1` for the week, with `-OutDir` set to that folder: GSC, plus GA4 including `ga4-ai-sources.csv` and `ga4-ai-landing.csv`. GSC lags about 2 days; note it if the last days look incomplete.
- `fetch-auto.ps1` for the week (`-OutFile <folder>\auto-metrics.json`): PSI, CrUX, Clicky including AI referrals, Ahrefs DR. Never print keys.
- `aeo-checks.ps1 -OutFile <folder>\aeo-health.json`: llms.txt, AI-crawler robots rules, answer-readiness of the target pages.

Keyword Ranking: compare `seo/rankings/keywords.csv` against `gsc\QueryPage.csv`, with Start = last week and End = this week.

AEO - AI Answers: run every prompt in `seo/rankings/aeo-prompts.csv` for the site through WebSearch, and record whether our domains appear, at what position, the URL, and which competitors appear. Label it as a web-search proxy.

Append to `seo/rankings/<site>-rankings-history.csv` and `seo/rankings/aeo-history.csv`. If rows for the same date and site already exist, replace them; don't duplicate.

Build `seo/reports/weekly/<site>-seo-weekly-<label>.xlsx` with `seo-report.ps1 -Action Build` and `"layout": "weekly"`. Sheets: Weekly Summary, Keyword Ranking, AEO - AI Answers, AEO - AI Traffic, AEO - Health, Content Updates. Missing metrics stay "Awaiting data"; never estimate. If fetch-google fails with `invalid_grant`, tell the owner to run `pipelines/seo-reporting/google-auth.ps1 -Action Login`.

After every site is done, update the combined tracker: check `seo/rankings/aeo-focus.csv` (every prompt needs a row with priority High / Medium / Low / Defend, what to focus on, and the page to work on; update rows whose status or position changed this week), then run `ranking-aeo-report.ps1 -Label <label> -From <Mon> -To <Sun>` (add `-ExcludeAiPaths` for any non-buyer paths, such as job pages, that should be reported separately). If Excel returns RPC_E_CALL_REJECTED, close only the hidden Excel instances this run started and retry.

Output, per site:
- 3 bullets on what moved
- ranking movers of 3 positions or more, and URL mismatches (ranking URL is not the target URL)
- AEO: prompts where we appear or don't, changes vs last week, and AI sessions by assistant (with and without any excluded paths)
- inputs still missing.
