# SEO reporting pipeline

Monthly SEO reports, weekly rankings + AEO (answer-engine) checks, and a long-running ranking tracker for every website in `config/sites.csv`. Windows, PowerShell 5.1 and Excel (COM). No Node.js, Python or Screaming Frog licence needed.

The spec for what goes in each report is [PLAYBOOK.md](PLAYBOOK.md). The `website-seo-specialist` agent runs it; `/seo <request>` routes to it.

## What it produces

| Output | Where | Built by |
|---|---|---|
| Monthly workbook per site: Summary, Overview, SF Overview, Top Queries, Rankings, Top Pages, GEO Traffic, GSC Screenshots, Improvements | `<root>\seo\reports\YYYY-MM\<site>-seo-report-YYYY-MM.xlsx` (+ `<site>-report-data.json`) | `seo-report.ps1 -Action Build` |
| Weekly workbook per site: Weekly Summary, Keyword Ranking, AEO - AI Answers, AEO - AI Traffic, AEO - Health, Content Updates | `<root>\seo\reports\weekly\<site>-seo-weekly-YYYY-MM-DD.xlsx` | `seo-report.ps1 -Action Build` with `"layout": "weekly"` |
| Ranking & AEO tracker: one keyword row per term, one "Rank <Mon d>" column per week, for all sites | `<root>\seo\reports\ranking-aeo-report.xlsx` | `ranking-aeo-report.ps1` |
| Raw inputs (GSC, GA4, URL Inspection, crawl, PSI/Clicky/CrUX, AEO health) | `<root>\seo\_exports\YYYY-MM\<site-key>\` (monthly), `<root>\seo\_exports\weekly\YYYY-MM-DD\<site-key>\` (weekly) | the fetch scripts |
| History (never overwritten) | `<root>\seo\rankings\<site>-rankings-history.csv`, `aeo-history.csv` | the agent |

`<root>` is `-Root`, else `%MARKETING_ROOT%`, else the repo root. Point `MARKETING_ROOT` at a working folder if you don't want report data inside the repo.

## Files

| File | Does |
|---|---|
| `seo-common.ps1` | Shared helpers: root, sites, secrets folder, list files. Dot-sourced by the others. |
| `google-auth.ps1` | One-time Google sign-in (loopback + PKCE, read-only scopes) and token refresh |
| `fetch-google.ps1` | Search Console (devices, queries, pages, countries, query x page, totals, sitemaps) and GA4 (channels, devices, countries, landing pages, AI Assistant sources/landing) |
| `fetch-index.ps1` | URL Inspection of every sitemap URL: indexed / not indexed, 404, soft 404, 5xx, robots, noindex, rich-result errors |
| `crawl-site.ps1` | curl-based site crawler that replaces Screaming Frog for the crawl rows |
| `fetch-auto.ps1` | PageSpeed Insights, CrUX Core Web Vitals, Clicky, Ahrefs Domain Rating (free endpoint) |
| `aeo-checks.ps1` | llms.txt, AI-crawler rules in robots.txt, robots warnings, answer-readiness of target pages |
| `seo-report.ps1` | `Prep` (folders + manual-inputs.csv) and `Build` (the formatted workbook from a JSON file) |
| `ranking-aeo-report.ps1` | Weekly update of the combined Ranking & AEO tracker |
| `audit-crawl.js` | Optional browser-console crawler for on-page and deprecated-terminology checks against the live DOM |
| `metrics.csv`, `weekly-metrics.csv` | The metric lists for the Overview / Weekly Summary sheets, with the source of each |
| `templates\keywords.csv`, `aeo-prompts.csv`, `aeo-focus.csv`, `content-updates.csv` | Starter copies of the editable lists |

## One-time setup

### 1. Sites

Edit `config/sites.csv`, one row per website:

| Column | Example | Notes |
|---|---|---|
| `key` | `main` | Short id used in folder and file names |
| `domain` | `www.example.com` | Host only, no scheme |
| `ga4_property` | `123456789` | Numeric GA4 property ID (GA4 > Admin > Property details). Leave blank to skip GA4 |
| `gsc_property` | `sc-domain:example.com` or `https://www.example.com/` | Exactly as Search Console lists it. Blank = `https://<domain>/` |
| `clicky_site_id` | `101234567` | Optional. The matching sitekey goes in keys.json |
| `notes` | | Free text |

Property IDs are not secrets, but if your repo is public, keep your real `sites.csv` in `%MARKETING_ROOT%\config\` instead of committing it.

### 2. Editable lists

Create `<root>\seo\rankings\` and copy the four files from `templates\` into it. Edit those copies:
- `keywords.csv`: tracked keywords per site, with target URL. Seed it from 90 days of Search Console queries.
- `aeo-prompts.csv`: the questions buyers ask AI assistants, with `our_domains` and `competitors_to_watch` (semicolon-separated).
- `aeo-focus.csv`: one row per prompt: priority (High / Medium / Low / Defend), what to focus on, page to work on.
- `content-updates.csv`: the content log (header only to start).

Scripts use the template only when the live copy is missing.

### 3. Google Cloud project and OAuth client

1. In Google Cloud Console, create (or pick) a project.
2. **APIs & Services > Library**, enable:
   - Google Search Console API
   - Google Analytics Data API
   - Google Analytics Admin API (optional; only needed for `google-auth.ps1 -Action Test` to list GA4 properties)
   - PageSpeed Insights API
   - Chrome UX Report API (for Core Web Vitals field data)
3. **APIs & Services > OAuth consent screen:** choose **Internal** if your Google Workspace allows it. With **External**, add your account as a test user, and publish the app when you can: while it stays in Testing, the refresh token expires after 7 days and you will see `invalid_grant`.
4. **Credentials > Create credentials > OAuth client ID > Desktop app.** Download the JSON and save it as
   `%USERPROFILE%\.marketing-agent-team\google-client.json`
5. **Credentials > Create credentials > API key.** Restrict it to PageSpeed Insights API and Chrome UX Report API. This is `psi_api_key` below. Enable the CrUX API in the same project as this key.
6. The account you sign in with needs at least read access to each Search Console property and GA4 property.

Then sign in once:

```powershell
.\pipelines\seo-reporting\google-auth.ps1 -Action Login   # opens the browser; also prints the link
.\pipelines\seo-reporting\google-auth.ps1 -Action Test    # lists the GSC sites and GA4 properties you can read
```

The refresh token is saved to `%USERPROFILE%\.marketing-agent-team\google-token.json`.

### 4. keys.json

Create `%USERPROFILE%\.marketing-agent-team\keys.json`. Every field is optional; a missing one makes that source show "Awaiting data".

```json
{
  "psi_api_key": "<GOOGLE_API_KEY>",
  "ahrefs_api_key": "<AHREFS_API_KEY>",
  "clicky": {
    "<site-key>": { "sitekey": "<CLICKY_SITEKEY>" }
  }
}
```

- `psi_api_key`: PageSpeed Insights and CrUX.
- `ahrefs_api_key`: a free-plan key works only on the Domain Rating endpoint, which is all this pipeline calls.
- `clicky.<site-key>.sitekey`: from Clicky > Preferences > Info. The site ID goes in `sites.csv` (`clicky.<site-key>.site_id` in keys.json also works).

Never commit these files, paste them into chat, or copy them into a synced folder. The scripts never print them.

## How to run

The usual way is through Claude Code: `/seo monthly report`, `/seo weekly rankings`, or the scheduled automations in `automations/scheduled-tasks/seo-monthly-report` and `seo-weekly-report`. By hand, from the repo root:

### Monthly (last day of the month)

```powershell
$p = '.\pipelines\seo-reporting'
$site = 'main'; $from = '2026-10-01'; $to = '2026-10-28'      # 28 days ending 2 days before today
& "$p\seo-report.ps1" -Action Prep -Month 2026-10 -Site $site
& "$p\fetch-google.ps1" -Site $site -From $from -To $to
& "$p\fetch-index.ps1"  -Site $site
& "$p\crawl-site.ps1"   -Site $site
& "$p\fetch-auto.ps1"   -Site $site -From $from -To $to
& "$p\aeo-checks.ps1"   -Site $site -OutFile ".\seo\_exports\2026-10\$site\aeo-health.json"
# the agent assembles seo\reports\2026-10\<site>-report-data.json (see PLAYBOOK.md), then:
& "$p\seo-report.ps1" -Action Build -DataFile ".\seo\reports\2026-10\$site-report-data.json" -OutFile ".\seo\reports\2026-10\$site-seo-report-2026-10.xlsx"
```

### Weekly (Monday, previous Mon-Sun)

```powershell
$label = '2026-10-05'; $from = '2026-09-28'; $to = '2026-10-04'
$dir = ".\seo\_exports\weekly\$label\$site"
& "$p\seo-report.ps1"  -Action Prep -Week $label -Site $site
& "$p\fetch-google.ps1" -Site $site -From $from -To $to -OutDir $dir
& "$p\fetch-auto.ps1"   -Site $site -From $from -To $to -OutFile "$dir\auto-metrics.json"
& "$p\aeo-checks.ps1"   -Site $site -OutFile "$dir\aeo-health.json"
# the agent runs the AEO prompts, appends history, builds the weekly workbook, then, once for all sites:
& "$p\ranking-aeo-report.ps1" -Label $label -From $from -To $to   # add -ExcludeAiPaths '/careers/' if useful
```

Run times: URL Inspection is about 1 minute per 70 sitemap URLs; the crawler depends on site size and speed (a few minutes for a few hundred pages).

## Known gotchas

- **`invalid_grant`**: the Google sign-in expired. Rerun `google-auth.ps1 -Action Login`.
- **Domain properties**: page lists are filtered to the site's host, but device/query/country breakdowns are not, because page-filtering makes GSC drop rows.
- **Hosts that drop connections on 404**: the crawler and AEO checks use `curl.exe` (built into Windows 10+) to read the real status.
- **5xx under load**: the crawler retries each 5xx once, alone. If they persist, check one in a browser: some templates return 500 while still rendering.
- **Excel COM**: `RPC_E_CALL_REJECTED` when opening a workbook in a synced folder. The tracker script edits a TEMP copy and copies it back. If it still happens, close only the hidden Excel instances the run started.
- **PSI scores are noisy**: a single run can swing by 30 points. Read trends, not one number.
- **Non-ASCII in .ps1**: PowerShell 5.1 misreads non-ASCII characters in UTF-8 files without a BOM. Keep scripts plain ASCII.
