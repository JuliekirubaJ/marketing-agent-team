# SEO Report Playbook

The `website-seo-specialist` agent follows this playbook for every site in `config/sites.csv`, so every site's report has the same shape. `seo-strategist` handles keyword research and content briefs; it does not run these reports.

Paths below are relative to the data root (`<root>`): `-Root`, else `%MARKETING_ROOT%`, else the repo root. Scripts are in `pipelines/seo-reporting/`.

## Cadence

| Run | When | Output |
|---|---|---|
| **Monthly report** | Last day of every month (automation `seo-monthly-report`) | One workbook per site: `seo\reports\YYYY-MM\<site>-seo-report-YYYY-MM.xlsx`, plus `<site>-report-data.json` next to it |
| **Weekly health check + rankings + AEO** | Every Monday (automation `seo-weekly-report`) | `seo\reports\weekly\<site>-seo-weekly-YYYY-MM-DD.xlsx`: Weekly Summary, Keyword Ranking, AEO - AI Answers, AEO - AI Traffic, AEO - Health, Content Updates. Appends to `seo\rankings\<site>-rankings-history.csv` and `seo\rankings\aeo-history.csv`, then updates `seo\reports\ranking-aeo-report.xlsx` |
| **Improvement work** | On request (`/seo <request>`) | Page-level fixes, AEO/GEO recommendations, briefs |

**Report window:** the last 28 days ending two days before the run date, because Search Console data lags about 2 days. A 28-day window keeps the day-of-week mix the same month to month. State the exact dates on every sheet.

## Inputs, per site, in `seo\_exports\YYYY-MM\<site>\`

Fully automatic. Run these per site, in this order, for the report window. The owner (see `config/team.md`) supplies nothing except the optional manual rows listed below.

1. `seo-report.ps1 -Action Prep -Month YYYY-MM -Site <site>`: creates the folder, the `sf\` and `screenshots\` subfolders, and `manual-inputs.csv` (every metric in `metrics.csv` with a blank `value` column).
2. `fetch-google.ps1`: Search Console performance and GA4, including AI sources and landing pages.
3. `fetch-index.ps1`: URL Inspection of every sitemap URL. This gives Sitemap submitted/indexed, Index Status, 404s, Soft 404s, Server errors, blocked by robots, noindex and structured-data errors. Inspections take about 7 s each server-side and run 8 at a time, so budget about 1 minute per 70 URLs. The quota is 2,000 inspections per property per day.
4. `crawl-site.ps1`: replaces Screaming Frog for all the site-crawl rows and the ">2s response" row. It writes `sf\internal_all.csv`, `sf\redirect_chains.csv` and `sf\crawl-summary.json`. If the owner drops a real Screaming Frog `internal_all.csv` into `sf\`, it wins, so run the crawler only when `sf\` is empty.
5. `fetch-auto.ps1`: PSI, Clicky, Ahrefs DR (optional) and CrUX Core Web Vitals (once the Chrome UX Report API is enabled in the PSI key's Cloud project).
6. `aeo-checks.ps1`: llms.txt, AI-crawler rules, robots.txt warnings and page answer-readiness.
7. DevTools load time and size, measured in the browser by the main session (see `.claude/commands/seo.md`).

**Still manual, all optional:** the 6 backlink rows (free Ahrefs/Semrush plans have no API; read them from Ahrefs Webmaster Tools), GSC Total Backlinks (no API), the Pingdom score (no API), and the site: count (Google blocks automated searches; use "Sitemap indexed" instead). Mobile usability and International Targeting are always "N/A (retired by Google)". Blank rows show "Awaiting data". Never chase the owner for them.

| File | Source | Feeds |
|---|---|---|
| `gsc\Devices.csv, Queries.csv, Pages.csv, Countries.csv, QueryPage.csv, Totals.csv, Sitemaps.csv` | `fetch-google.ps1` | Devices (desktop/mobile), Queries, Pages, Countries, rankings, sitemap cross-check |
| `ga4-totals/channels/devices/countries/landing.csv` | `fetch-google.ps1` (when the site has a `ga4_property`) | Sessions, organic sessions, users, organic social, search + direct, GEO traffic, best pages |
| `ga4-ai-sources.csv`, `ga4-ai-landing.csv` | `fetch-google.ps1` | AI Assistant sessions by source and landing page |
| `gsc\url-inspection.csv`, `gsc\index-summary.json` | `fetch-index.ps1` | All GSC indexing rows |
| `sf\internal_all.csv`, `sf\redirect_chains.csv`, `sf\crawl-summary.json` | `crawl-site.ps1` (or a real SF export) | Status codes, indexability, titles, metas, H1s, canonicals, response time, redirect chains |
| `sf\crawl_overview.csv` | Screaming Frog > Reports > Crawl Overview, if a real SF crawl was done | SF Overview sheet as-is. If absent, build the SF Overview from internal_all |
| `auto-metrics.json` | `fetch-auto.ps1` | PSI scores, LCP and byte weight, Clicky rows including AI referrals, Ahrefs DR, CrUX |
| `aeo-health.json` | `aeo-checks.ps1` | Robots txt warnings, AEO items on the Improvements page |
| `manual-inputs.csv` | The owner types values in (optional rows only) | Backlinks, Pingdom, site: count |
| `screenshots\*.png` | GSC performance chart captures (optional) | GSC Screenshots sheet |

Metric definitions, and where each one comes from, are in `metrics.csv` (monthly) and `weekly-metrics.csv` (weekly). They are the single list for the Overview / Weekly Summary sheets. Use their labels exactly.

**If a real Screaming Frog crawl is wanted:** crawl the root domain unfiltered, with "Crawl outside of start folder" and "Show blocked by robots.txt" on, and JavaScript rendering off unless the site needs it. Crawl each subdomain as its own site. The free version stops at 500 URLs: untick Images, CSS, JavaScript and External links, or switch to List mode over the sitemap. Record which mode was used and whether the crawl hit the cap. A capped crawl undercounts errors, so say so in the Summary.

**Automatic sources.** Keys live in `%USERPROFILE%\.marketing-agent-team\keys.json`, outside the repo and any synced folder. See `README.md` for the fields.
- Google (Search Console + GA4) uses the owner's saved read-only sign-in through `google-auth.ps1`; the token is in `%USERPROFILE%\.marketing-agent-team\google-token.json`.
- If the sign-in fails with `invalid_grant`, it has expired (after 7 days while the consent screen is External + Testing). Ask the owner to rerun `google-auth.ps1 -Action Login`. Don't fall back to guessing.
- **Domain properties** (`sc-domain:` in `gsc_property`): totals, devices, queries and countries are property-level, which matches the GSC UI. Page lists are filtered to the site's own host. Never page-filter the other breakdowns, because GSC then drops rows.
- A site with no Clicky account gets `N/A (no Clicky site)` on its Clicky rows.
- A new GSC property can show 0 clicks and 0 impressions for weeks. Report it as observed, and check that a sitemap is submitted.
- **Ahrefs free plan:** the MCP connector and paid endpoints return "Insufficient plan" or 401, so don't call them. The free `public/domain-rating-free` endpoint works and fills the **Rank** row with Ahrefs DR, labelled "Ahrefs DR".
- **GA4 "AI Assistant" channel:** report it next to Clicky AI referrals as the GEO traffic metrics.

Never print key values in chat or write them into the report.

## Precedence and honesty rules

1. Take each value from its export file, then from `manual-inputs.csv`, then from an automatic source. A value the owner typed in manual-inputs always wins over a computed one.
2. **Never estimate a metric.** If there is no value, pass `null`. The workbook prints "Awaiting data" and the report stays honest.
3. **Previous month:** read last month's `<site>-report-data.json`. The first month has no previous values; show "-", not zero.
4. Retired GSC reports (Mobile usability, International Targeting): record `N/A (retired by Google)`.
5. Don't report a `<head>` finding (title, meta, canonical, schema) from a WebFetch/markdown conversion. Read it from the live DOM, the crawler output or an SF export. Markdown converters drop the head and produce false "missing" findings.
6. Deprecated terminology is checked against `brand/glossary.md`. Re-read it each run; it changes.
7. Before calling 5xx errors "throttling", re-fetch them one at a time. Whole templates can return HTTP 500 while still rendering content.

## The monthly workbook: sheets and columns

Build it with:
`seo-report.ps1 -Action Build -DataFile seo\reports\YYYY-MM\<site>-report-data.json -OutFile seo\reports\YYYY-MM\<site>-seo-report-YYYY-MM.xlsx`

Keep the JSON. Next month's run reads it for the month-over-month comparison.

| # | Sheet | Contents |
|---|---|---|
| 1 | **Summary** | 5 to 8 plain bullets: what moved, what broke, and what to fix first. Numbers, not adjectives. |
| 2 | **Overview** | Every metric in `metrics.csv`, grouped by source (GA, Clicky, Backlinks, GSC, Site crawl, Latency): this month, last month, change, change %, data file, note. Green when the metric improved, red when it got worse. |
| 3 | **SF Overview** | The crawl overview: every section and count, plus the crawl date and the config used. |
| 4 | **Top Queries** | Top 50 GSC queries by clicks: Query, Clicks, Impressions, CTR, Position, and the MoM change in clicks and position. |
| 5 | **Rankings** | Tracked keywords x the last 5 weekly checks: Keyword, Cluster, Target URL, Ranking URL, and the position on each date. Flag rows where the ranking URL is not the target URL (cannibalisation). |
| 6 | **Top Pages** | Top 25 pages by GSC clicks: Page, Clicks, Impressions, CTR, Position. Where the page matches a GA4 landing page, add GA4 Sessions and Engagement rate. |
| 7 | **GEO Traffic** | GA4 and GSC side by side, one row per country (top 15, then "Rest of world"). GA4: Users, New users, Sessions, Engaged sessions, Engagement rate. GSC: Clicks, Impressions, CTR, Position. Keep the primary market (see `brand/audiences.md`) as the first row whatever its rank. |
| 8 | **GSC Screenshots** | PNGs from `screenshots\`. If there are none, the sheet says so. |
| 9 | **Improvements** | The one-page list of errors and improvements for this month (see below). It fits one landscape page when printed. |

## The Improvements page

- Columns: Priority, Area, URL/scope, Issue, Evidence, Fix, Owner, Effort, Status.
- **P1:** indexing or ranking risk, or broken commercial pages, fixed this month. **P2:** fix this month if time allows. **P3:** backlog.
- **Evidence is mandatory.** It names the file and number (for example "crawl-summary.json: 14 missing H1s, up from 9"). Don't list a problem you can't point to.
- **Carry forward:** every open item from last month's JSON stays on the page with Status = Carried. It is marked Fixed only when this month's data shows it fixed. Fixed items appear once more, then drop off.
- Include AEO/GEO items (missing FAQ/HowTo schema on answer pages, an entity missing from AI answers, llms.txt) in the same list, with Area = AEO or GEO.
- Keep it to about 15 rows. If there are more, group them ("37 images missing alt on /videos/") rather than listing every URL.

## Weekly report (Mondays, previous Mon-Sun)

Inputs go in `seo\_exports\weekly\YYYY-MM-DD\<site>\`, where the date is the Monday of the run (`seo-report.ps1 -Action Prep -Week YYYY-MM-DD -Site <site>`):
- `fetch-google.ps1 -OutDir <that folder>` for the week (GSC plus GA4, including `ga4-ai-sources.csv` and `ga4-ai-landing.csv`). If the last days look incomplete, say so: GSC lags about 2 days.
- `fetch-auto.ps1 -OutFile <that folder>\auto-metrics.json` for the week.
- `aeo-checks.ps1 -OutFile <that folder>\aeo-health.json`.
- Optionally, `manual-inputs.csv` with any `weekly-metrics.csv` values the owner has.

Build with `"layout": "weekly"` in the JSON. Output: `seo\reports\weekly\<site>-seo-weekly-YYYY-MM-DD.xlsx`, with these sheets:
1. **Weekly Summary:** the `weekly-metrics.csv` rows (Search performance, Technical SEO health, Core Web Vitals) with This week, Last week, Change and % Change. Last week comes from the previous weekly JSON. Put 3-5 bullets under the table.
2. **Keyword Ranking:** Keyword, Search Volume, Position (Start), Position (End), Change, URL, Action Needed. Start is last week's position and End is this week's; positive Change means the keyword moved up. Search volume comes only from Ahrefs/Semrush; leave it blank otherwise.
3. **AEO - AI Answers:** one row per prompt in `aeo-prompts.csv` for this site.
   - Columns: Prompt, Cluster, Intent, We appear? (Y/N), Our best position, Our URL, Brand named in snippets? (Y/N), Competitors appearing, Top 5 domains, Change vs last week.
   - **Method (free web-search proxy):** run each prompt through WebSearch and read the top 10 results and their snippets. "We appear" means any of the prompt's `our_domains` is in the results. Competitors are matched against `competitors_to_watch` (and `brand/competitors.md`), by name or domain.
   - Caption the sheet "Web-search proxy for AI answers, not captured ChatGPT/Perplexity output". AI assistants draw on these results, but they aren't these results.
   - Append rows to `seo\rankings\aeo-history.csv` (date, site, prompt, appears, position, url, brand_in_snippet, competitors, top_domains). Never overwrite history; if rows for the same date and site exist, replace them rather than duplicate.
4. **AEO - AI Traffic:** GA4 `ga4-ai-sources.csv` (sessions by AI assistant: chatgpt.com, gemini, claude.ai, perplexity, copilot) and `ga4-ai-landing.csv` (where AI visitors land), plus Clicky AI referrals, all with week-over-week change.
   - **Split non-buyer pages out:** job pages (for example `/careers/`) can take most AI-assistant sessions on a company site. Report "AI sessions excluding <paths>" as the buyer-relevant number (`ranking-aeo-report.ps1 -ExcludeAiPaths`).
5. **AEO - Health:** from `aeo-health.json`:
   - llms.txt status and quality (markdown, duplicate H1, broken characters)
   - AI-crawler access per bot in robots.txt, and whether a stray Crawl-delay line is present
   - for each target page: H1 count, meta length, schema types (FAQPage, HowTo, SoftwareApplication present?) and question-style H2s
   - flag anything that changed since last week.
6. **Content Updates:** this site's rows from `seo\rankings\content-updates.csv` (Date, Activity, Type, URL, Target Keyword, Notes) for the last 8 weeks, so ranking and AEO moves can be read against what was published or changed.

After all sites are done, update the combined tracker: `ranking-aeo-report.ps1 -Label <Monday> -From <Mon> -To <Sun>`. Before running it, check `aeo-focus.csv`: every prompt in `aeo-prompts.csv` needs a row with priority (High / Medium / Low / Defend), what to focus on, and the page to work on. Update rows whose shown/not-shown status or position changed this week. If Excel returns RPC_E_CALL_REJECTED, close only the hidden Excel instances this run started and retry.

**Keyword list:** `keywords.csv` (columns: site, keyword, cluster, type, target_url, baseline_impressions_90d, baseline_position_90d, current_top_url). Build it from 90 days of GSC queries plus the strategic terms in `brand/positioning.md`. Type is brand / commercial / content / strategic. "Strategic" keywords are ones we want but don't rank for yet; report them as "not ranking" rather than dropping them. Keywords with no target_url are waiting on the owner's decision.

**Editable lists** (`keywords.csv`, `aeo-prompts.csv`, `aeo-focus.csv`, `content-updates.csv`): the live copy is `seo\rankings\<file>`. Scripts fall back to `pipelines/seo-reporting/templates/<file>` only when the live copy is missing, so copy the templates there on first setup and edit those.

**Content log:** whenever the owner mentions publishing or updating a page ("published the X blog", "updated the pricing page"), append a row to `seo\rankings\content-updates.csv` (date, site, activity, type, url, target_keyword, notes). The monthly Summary names any tracked keyword that moved within 4 weeks of a logged update to its URL.

### Ranking data

Method, in order of preference:
1. **Semrush Position Tracking or Ahrefs Rank Tracker export**, dropped as `seo\rankings\_inbox\<site>-YYYY-MM-DD.csv`. This gives the true Google rank and the ranking URL on that date.
2. **GSC (automatic, the default):** `gsc\QueryPage.csv` for the week. For each tracked keyword, take the row with the most impressions as the ranking URL and its position. Flag other URLs for the same query with 10% or more of its impressions as cannibalisation. Label the source "GSC avg position": it's an average, not a point-in-time rank.

Append to `seo\rankings\<site>-rankings-history.csv` (date, keyword, cluster, target_url, ranking_url, position, clicks, impressions, source). Never overwrite history. If there is no data, write nothing and report "no ranking data this week". Don't guess positions from a web search.

Long-tail keywords often get no searches in a given week. Show them as "No data" (or "Ranks, but no impressions this week" when there is a 28-day position), not as "not ranking".

## AEO / GEO checks (weekly data above; monthly, these feed the Improvements page)

- **Answer-readiness:** pages that target question queries lead with a direct 40 to 60 word answer and use H2s phrased as questions, backed by FAQPage/HowTo schema where the content really is Q&A.
- **Entity clarity:** Organization, Product/SoftwareApplication and BreadcrumbList schema are valid, `sameAs` links point to the company's official profiles and marketplace listings (see `brand/company.md`), and naming stays consistent with `brand/glossary.md`.
- **AI-crawler access:** robots.txt doesn't block GPTBot, ClaudeBot, PerplexityBot or Google-Extended unless that's a deliberate choice, and `llms.txt` presence is recorded.
- **AI answer presence:** run the tracked category questions through WebSearch. Record whether the brand or site is cited and which competitors are. Report only what was observed, with the date.
- **Citations:** third-party pages that AI answers cite for the category (documentation hubs, review sites, community threads) where we are absent become outreach items.
