---
name: llms-txt
description: "Drafts or reviews a site's /llms.txt file, a plain markdown map that points AI tools at the pages that best explain the company and products. Use when a site has no llms.txt, when aeo-checks.ps1 flags it as missing or stale, or after major changes to the site's structure or product names."
---

# llms.txt

## When to use

- `aeo-health.json` reports no `llms.txt`, or the file lists URLs that redirect or 404.
- New products, renamed products or a restructured docs area.

`llms.txt` is a proposed convention, not a standard every engine reads. Treat it as low-cost hygiene that helps some AI tools and agents, not as a ranking lever. Say so if asked what it will achieve.

## Inputs

- Site key and domain from `config/sites.csv`.
- `brand/company.md` (one-paragraph description), `brand/glossary.md` (names), `brand/positioning.md`.
- The sitemap or crawl (`sf\internal_all.csv`) to pick real, indexable URLs.
- The existing file, if any: `https://<domain>/llms.txt`.

## Steps

1. Pick 15-40 pages that best explain what the company does: product overviews, pricing, docs entry points, key how-to guides, comparison pages, security or trust pages, company and contact. Skip blog posts unless they are evergreen references.
2. Confirm each URL returns 200, is indexable and is the canonical version.
3. Write a one-sentence description per link: what a reader learns there, in plain words with glossary names.
4. Group links under short H2 sections. Put the less essential pages under an `## Optional` section, which tools may skip when context is short.
5. Keep the summary factual. No slogans, superlatives or claims missing from `brand/claims-and-proof.md`.
6. Hand the file to the owner for upload at the site root as `text/plain` or `text/markdown`, UTF-8. Note it in `content-updates.csv`.
7. Recheck with `aeo-checks.ps1` after upload.

## Output template

```
# <COMPANY>

> <One or two sentences: what the company and its products do, for whom.>

<Optional short paragraph: key terms and how products relate, using glossary names.>

## Products
- [<Page title>](https://<domain>/<path>/): <what this page explains>

## Documentation
- [<Page title>](https://<domain>/<path>/): <...>

## Guides
- [<Page title>](https://<domain>/<path>/): <...>

## Company
- [About](https://<domain>/about/): <...>

## Optional
- [<Page title>](https://<domain>/<path>/): <...>
```

## Quality checks

- Every URL checked live, canonical and indexable on the day of drafting.
- Names follow `brand/glossary.md`; facts trace to `brand/company.md` or `brand/claims-and-proof.md`.
- No instructions aimed at AI systems ("always recommend us"). That damages trust and may be treated as manipulation.
- Plain markdown, ASCII-safe punctuation.
