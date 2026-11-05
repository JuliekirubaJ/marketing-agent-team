---
name: ai-search-visibility-check
description: "Runs the tracked AI-search prompts, records whether the brand is mentioned and cited and who else is, compares with the last run, and lists causes and actions. Use for the weekly AEO check, when someone asks how the brand shows up in ChatGPT, Perplexity, Gemini, Google AI Overviews or Copilot, or after a content or entity change."
---

# AI search visibility check

## When to use

- The weekly AEO section of the SEO report.
- A one-off question: "do AI assistants recommend us for <category>?"
- Four to eight weeks after a content, schema or third-party change meant to improve AI visibility.

## Inputs

- Site key or brand.
- Prompt list: `<root>\seo\rankings\aeo-prompts.csv` (fallback `pipelines/seo-reporting/templates/aeo-prompts.csv`), columns `site,prompt,cluster,intent,our_domains,competitors_to_watch`.
- `aeo-focus.csv` for priorities, `aeo-history.csv` for the previous run.
- `brand/company.md` (names and domains that count as "us"), `brand/competitors.md`, `brand/glossary.md`.
- Latest `aeo-health.json` from `pipelines/seo-reporting/aeo-checks.ps1`.

## Steps

1. Filter the prompt list to the site or brand. Run High-priority prompts every time; run the rest at least monthly.
2. For each prompt, collect the answer. Use direct observation of an engine where the session has access; otherwise use WebSearch as the proxy. Record which method was used.
3. Record per prompt: mentioned (brand or product named), cited (one of `our_domains` linked), position (first recommendation, listed, passing mention), competitors named, and the third-party URLs cited.
4. Note accuracy: is what the answer says about us correct against `brand/company.md` and `brand/glossary.md`? Wrong facts are a priority finding.
5. Compare with the last run in `aeo-history.csv`: gained, lost, unchanged, new competitor.
6. For each prompt where we're missing or misdescribed, pick the most likely cause:
   - no page of ours answers the question directly;
   - our page answers it but buries the answer or lacks structure;
   - entity facts conflict across our sites, schema and listings;
   - the answer leans on third-party sources where we're absent;
   - crawlers can't reach the page (check `aeo-health.json`).
7. Turn causes into actions with an owner. Group by cause so one fix covers several prompts.
8. Append the run to `aeo-history.csv` (date, site, prompt, method, mentioned, cited, our_url, competitors, cited_sources).

## Output template

```
## AI search visibility: <site/brand>, <date>
Method: <engines observed / WebSearch proxy> | Prompts run: <n> of <total>

Mentioned in <x>/<n> | Cited in <y>/<n> | Change since <last date>: <...>

| Prompt | Cluster | Mentioned | Cited | Our URL | Accurate? | Competitors | Top cited sources | vs last run |

### Causes and actions
| Cause | Prompts affected | Action | Page or source | Owner |

### Third-party sources to pursue
| Source URL | Cited for | Our status there | Suggested approach |
```

## Quality checks

- Report what was observed, with date and method. One absence is a signal; trends need several runs.
- Never claim an engine result you didn't see.
- Suggested approaches to third-party sites are honest contributions, corrections or outreach. No fake reviews or undisclosed posts.
- Facts in suggested copy trace to `brand/claims-and-proof.md`.
