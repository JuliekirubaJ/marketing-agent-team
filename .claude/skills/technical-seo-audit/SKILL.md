---
name: technical-seo-audit
description: "Runs a technical SEO audit for one site from the pipeline's crawl, URL Inspection and PageSpeed outputs and turns findings into prioritized fix tickets. Use for a routine technical audit, an indexation or crawl problem, a Core Web Vitals regression, or before and after a release that changes templates or URLs."
---

# Technical SEO audit

## When to use

- Quarterly technical audit, or when the monthly report shows an indexing, crawl or speed anomaly.
- A page or section that should be indexed isn't.
- After a release that changed templates, navigation, URLs or the CMS.

## Inputs

- Site key and `notes` from `config/sites.csv`.
- Latest exports in `<root>\seo\_exports\YYYY-MM\<site-key>\`:
  - `sf\internal_all.csv`, `sf\redirect_chains.csv`, `sf\crawl-summary.json` (`crawl-site.ps1`)
  - `gsc\url-inspection.csv`, `gsc\index-summary.json` (`fetch-index.ps1`)
  - `auto-metrics.json` (`fetch-auto.ps1`: PageSpeed and CrUX)
  - `aeo-health.json` (`aeo-checks.ps1`: robots.txt and AI-crawler rules)
- The open fix list, so existing tickets aren't duplicated.
- If an input is missing or older than 30 days, run the script (see `pipelines/seo-reporting/README.md`) or report it as missing.

## Steps

1. **Robots and access:** read robots.txt. Check nothing important is disallowed, CSS and JS aren't blocked, the sitemap is declared, and AI crawlers are treated as intended.
2. **Sitemaps:** compare sitemap URLs with the crawl. Flag sitemap URLs that redirect, error, are noindexed or canonicalize elsewhere, and indexable pages missing from the sitemap.
3. **Indexation:** group `url-inspection.csv` rows by coverage state. For each non-indexed group, find the shared pattern (template, folder, parameter, thin content).
4. **Status codes:** 4xx and 5xx pages and who links to them; soft 404s.
5. **Redirects:** chains and loops from `redirect_chains.csv`; 302s used for permanent moves; internal links pointing at redirects.
6. **Canonicals:** missing, non-self-referencing on indexable pages, pointing at redirects or noindexed pages, conflicting with hreflang or the sitemap.
7. **Duplicates:** duplicate titles and descriptions from `crawl-summary.json`; http/https, www/apex, trailing-slash and parameter variants that resolve with 200.
8. **Hreflang** (multi-language sites only): return links, self-reference, valid codes, `x-default`.
9. **Structured data:** parse JSON-LD from raw HTML; check required properties and rich-result errors in URL Inspection (see `schema-markup`).
10. **Rendering:** for key templates, compare curl HTML with the rendered page. Flag main content, links, canonicals or schema that appear only after JavaScript.
11. **Performance:** CrUX field data for LCP, INP and CLS (verdict), PageSpeed lab data (diagnosis). Name the cause on the worst templates.
12. **Security and hygiene:** HTTPS everywhere, insecure resources, mixed content.
13. Group findings by root cause, spot-check two live URLs per ticket, then score impact and effort.

## Output template

```
## Technical SEO audit: <site-key>, <date>
Inputs: <file - date> | Missing: <...>

### Summary (3-5 sentences)

### Fix tickets
| # | Priority (P1/P2/P3) | Issue | Affected (count, 2-3 example URLs) | Evidence (file: figure) | Exact fix | Owner | Effort (S/M/L) |

### Watch items
### Verified fixed since last audit
```

P1 blocks indexing or ranking of important pages. P2 wastes crawl budget or splits signals at scale. P3 is hygiene.

## Quality checks

- Every count names its source file. Missing data is "awaiting data", never an estimate.
- Head elements and JSON-LD come from raw HTML, never a markdown conversion.
- One ticket per root cause, with the exact change (redirect map, canonical value, robots line, template field).
- PageSpeed lab scores are noisy; base regressions on field data or repeated runs.
