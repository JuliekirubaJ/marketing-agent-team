---
name: internal-linking-audit
description: "Audits a site's internal links to find orphan pages, under-linked priority pages, broken or redirected links and weak anchor text, then lists specific links to add. Use when priority pages aren't ranking, after publishing a batch of content, during a topic-cluster build, or when the crawl shows orphan or deep pages."
---

# Internal linking audit

## When to use

- Money pages (product, pricing, demo, key landing pages) rank below where they should.
- New content went live without links to or from the rest of the site.
- Building or tidying a topic cluster.

## Inputs

- Site key from `config/sites.csv`.
- The crawl: `sf\internal_all.csv` and `sf\redirect_chains.csv` from `pipelines/seo-reporting/crawl-site.ps1` in `<root>\seo\_exports\YYYY-MM\<site-key>\`. If the crawl doesn't record link sources, re-read the HTML of the pages in scope with curl.
- Search Console pages export (for which pages earn impressions).
- The tracked keywords list (target URLs are the priority pages).
- The cluster map, if `keyword-clustering` has been run.

## Steps

1. List priority pages: target URLs in the keywords list plus anything the owner names.
2. For each HTML page, count unique internal links in (from body content, not navigation or footer) and note crawl depth from the homepage.
3. Flag orphans (in the sitemap or Search Console but no internal links in) and pages deeper than three clicks.
4. Flag internal links that hit a redirect or an error. Fix at source: link straight to the final URL.
5. Review anchor text into priority pages. Flag generic anchors ("click here", "read more") and the same exact-match anchor used everywhere.
6. Check cluster wiring: each cluster page links to its pillar, the pillar links to each cluster page, and siblings link where it helps the reader.
7. Find link sources: pages with impressions or backlinks that are topically related to a priority page but don't link to it. Use site search (`site:<domain> "<topic>"`) or grep the crawl's titles.
8. Write each recommended link as from-URL, to-URL, anchor and the sentence or section where it fits.

## Output template

```
## Internal linking audit: <site-key>, <date>
Crawl used: <file, date, URLs crawled>

### Summary
<orphans: n | deep pages: n | links to redirects/errors: n | priority pages under-linked: n>

### Links to add (priority order)
| From URL | To URL | Anchor text | Where on the page |

### Links to fix
| Page | Current link | Final URL |

### Orphans and deep pages
| URL | Inlinks | Depth | Action |
```

## Quality checks

- Anchors read naturally in the sentence; vary them.
- Every recommended link helps the reader, not just the target page.
- Counts cite the crawl file and date.
- Product names in anchors follow `brand/glossary.md`.
