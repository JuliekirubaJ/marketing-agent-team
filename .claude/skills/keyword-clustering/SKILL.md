---
name: keyword-clustering
description: "Groups a keyword list into intent-based clusters and maps each cluster to one existing or planned page, flagging cannibalization and gaps. Use when someone has a list of keywords to organize, wants a topic-cluster or pillar plan, or asks which page should target which keyword."
---

# Keyword clustering

## When to use

- A raw keyword list (from Search Console, a keyword tool, sales calls or community research) needs structure.
- Planning a topic cluster or pillar page.
- Checking whether two pages target the same thing.

## Inputs

- The keyword list, with volume, difficulty or impressions if available. Ask where the numbers came from.
- The site key from `config/sites.csv`.
- The tracked keywords list: `<root>\seo\rankings\keywords.csv` (fallback `pipelines/seo-reporting/templates/keywords.csv`).
- Search Console query x page data from the latest export, if there is one.
- `brand/positioning.md`, `brand/audiences.md`, `brand/competitors.md`, `brand/glossary.md`.

## Steps

1. Clean the list: lowercase, merge exact duplicates and plurals, drop terms with no plausible link to what we sell (check `brand/positioning.md`).
2. Tag each keyword with intent: informational, commercial investigation, transactional or navigational.
3. Group by SERP overlap, not by shared words. Two keywords belong together when the same pages rank for both. Spot-check the top results with WebSearch for borderline pairs.
4. Never put different intents in the same cluster, even when the words are similar ("what is X" and "X software" usually need different pages).
5. Name each cluster after its head term (the keyword with the broadest demand that still matches the intent).
6. Map each cluster to one URL: an existing page that already ranks or gets impressions for it, or a new page. Use query x page data to see which URL Google already associates with it.
7. Flag cannibalization: a cluster where two or more of our URLs earn impressions.
8. Arrange clusters into pillars: one broad pillar page per theme, with cluster pages linking up to it and across to siblings.
9. Mark priority: business fit (close to what we sell), demand and current position (positions 5-20 are the quickest wins).

## Output template

```
## Keyword clusters: <site-key>, <date>
Source of volumes: <tool and date, or "not available">

| Pillar | Cluster (head term) | Intent | Keywords | Demand | Target URL (existing/new) | Current best position | Priority | Notes |

### Cannibalization flags
| Cluster | Competing URLs | Suggested owner URL |

### Gaps (clusters with no page)
### Keywords dropped and why
```

## Quality checks

- No invented volumes. If there's no data, write "unknown" and rank by fit and position.
- Product and feature names follow `brand/glossary.md`; deprecated terms only appear as keywords if buyers really search them, and are marked as such.
- Each cluster maps to exactly one URL.
- Competitor keywords come from `brand/competitors.md`, not guesses.
