---
name: site-migration-checklist
description: "Step-by-step SEO checklist for site migrations (redesigns, CMS changes, domain or subdomain moves, HTTPS changes and URL restructures) covering benchmarking, the redirect map, pre-launch staging checks, launch-day checks and post-launch monitoring. Use whenever URLs, templates, domains or the CMS are about to change."
---

# Site migration checklist

## When to use

Any change that moves URLs or replaces templates: redesign, CMS switch, merging sites, domain or subdomain move, folder restructure, HTTPS or www changes. Start at least four weeks before launch when possible.

## Inputs

- Site key and `notes` from `config/sites.csv`; the new domain or structure; launch date; staging URL.
- A full crawl of the current site (`crawl-site.ps1`) and URL Inspection (`fetch-index.ps1`), both taken before launch.
- 12 months of Search Console pages data and the tracked keywords list with current positions.
- A list of pages with backlinks (from a backlink tool if available).

## Steps

**Before launch**

1. Benchmark: save the crawl, URL Inspection, top pages by clicks, tracked keyword positions, Core Web Vitals and AI-answer citations. Store them in the month's export folder and note the date.
2. Build the URL inventory: every URL from the crawl, sitemaps, Search Console pages, analytics landing pages and backlinked pages.
3. Write the redirect map: old URL to the closest new equivalent, one hop, 301. Don't send everything to the homepage. Pages with no equivalent get a 410 or a redirect to the nearest parent topic, decided case by case.
4. Carry over on-page elements for top pages: titles, metas, H1s, body content, internal links, schema, hreflang, alt text.
5. Check staging: blocked from indexing (password or noindex), canonicals point at production URLs, no hard-coded staging links, sitemap generated from the new URLs, robots.txt ready for production.
6. Test the redirect map on staging with a script or crawler; zero chains, zero loops, zero 404s for mapped URLs.
7. Confirm analytics and tag tracking on the new templates, and that Search Console access exists for any new property.

**Launch day**

8. Remove staging blocks; confirm production robots.txt and meta robots allow indexing.
9. Run the redirect map against production. Spot-check the top 50 pages by clicks by hand.
10. Submit the new sitemaps; for a domain move, use the Change of Address tool.
11. Check analytics is recording, and that `llms.txt` and schema survived.

**After launch**

12. Days 1-7: daily check of 404s, 5xx and redirect errors in the crawl and Search Console; fix as found.
13. Weeks 1-8: weekly compare of indexed pages, clicks, positions and AI citations against the benchmark. Some fluctuation in the first weeks is normal; a growing gap is not.
14. Ask owners of high-value backlinks to update links to the new URLs.
15. Keep redirects in place for at least a year; longer for pages with backlinks.

## Output template

```
## Migration plan: <site-key>, launch <date>
Type: <redesign / CMS / domain / restructure> | Benchmark saved: <folder, date>

| Phase | Check | Owner | Due | Status | Evidence |

Redirect map: <file path> (<n> URLs mapped, <n> retired)
Risks: <top 3>
Post-launch comparison (filled weekly): | Metric | Benchmark | Week 1 | Week 2 | ... |
```

## Quality checks

- Benchmark figures come from saved exports with dates, never memory.
- Every URL with clicks or backlinks has an explicit mapping.
- Never edit the live site yourself; tickets and maps go to the owner.
- Product names on new templates follow `brand/glossary.md`.
