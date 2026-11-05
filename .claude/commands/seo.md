---
description: SEO / AEO / GEO for the sites in config/sites.csv - monthly report, weekly rankings + AEO, keyword research, improvements
argument-hint: [request, e.g. "monthly report all sites" | "weekly rankings main" | "optimise /pricing/" | "keyword research for <topic>"]
---

Route the request:

- Reports, rankings, AEO checks, technical / on-page / AEO / GEO fixes for any site in `config/sites.csv` -> `website-seo-specialist`. It handles every site; for "all sites" or no site named, give it all site keys in one request.
- Keyword research, keyword clustering, content briefs -> `seo-strategist`.
- A request that needs both (for example "find keywords and fix the page") -> `seo-strategist` first, then `website-seo-specialist` with its output.

Pass along the owner's request verbatim, today's date, the report month (YYYY-MM; for a month-end run, the month that is ending) or week label (the Monday), the site keys in scope, and this session's scratchpad path for temp files:

$ARGUMENTS

If no request was given, treat it as "Monthly report, all sites, for the month ending today."

The spec is `pipelines/seo-reporting/PLAYBOOK.md`; setup and scripts are in `pipelines/seo-reporting/README.md`.

Before delegating a monthly report, the main session measures the homepage **Google DevTools page load time and page size** for each site in scope, using the built-in browser tools if available. Navigate to the homepage, then read `performance.getEntriesByType('navigation')[0].loadEventEnd / 1000` (seconds) and the sum of `transferSize` across the navigation entry and all `performance.getEntriesByType('resource')` entries, divided by 1048576 (MB). Pass the values to the agent as measured inputs, with the date. If the browser is unavailable, leave them as "Awaiting data".

Rules for every run: never estimate a missing metric, never print API keys or tokens, and never edit a live website. If a Google call fails with `invalid_grant`, ask the owner to run `pipelines/seo-reporting/google-auth.ps1 -Action Login`.

When the agent returns, relay the results crisply: files written, the top improvements per site, the inputs still missing, and the decisions needed.
