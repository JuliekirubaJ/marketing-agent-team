---
name: comparison-page
description: "Plans and drafts fair, factual comparison pages, either \"<us> vs <competitor>\" or \"<competitor> alternatives\", that rank for comparison searches and hold up when a buyer or AI engine checks the facts. Use when someone asks for a vs page, an alternatives page, a competitor comparison table, or a refresh of an existing one."
---

# Comparison page (vs / alternatives)

## When to use

- Buyers search "<competitor> alternative" or "<us> vs <competitor>" and we have no page, or a weak one.
- AI answers for comparison prompts cite third-party pages instead of ours.
- An existing comparison page is older than six months or a competitor has changed pricing or packaging.

## Inputs

- Which competitor(s) and which format: head-to-head (vs) or a list (alternatives).
- `brand/competitors.md`: differentiators, pricing comparisons and the caveats they carry.
- `brand/positioning.md`, `brand/claims-and-proof.md`, `brand/glossary.md`, `brand/audiences.md`.
- The competitor's own current public pages (pricing, product, docs), read on the day, for every fact about them.
- Search Console queries containing the competitor's name, if any.

## Steps

1. Confirm intent on the SERP with WebSearch: what do current comparison pages cover, and what are buyers asking?
2. Choose the comparison criteria from what the buyer weighs (see `brand/audiences.md`), not only from where we win. Include at least one area where the competitor is the stronger choice, and say who it suits.
3. Collect facts for both sides. Our facts come from `brand/`. Their facts come from their public pages, with the URL and the date checked. Anything you can't verify goes out or is marked "not published".
4. Draft the page:
   - H1 that matches the query ("<Us> vs <Competitor>" or "<Competitor> alternatives").
   - A 40-60 word summary answer: the main difference and who each option suits.
   - A comparison table with sourced cells.
   - Sections per criterion, plain and specific.
   - "Who should choose <competitor>" and "Who should choose <us>".
   - For alternatives pages: several real options, including ones that aren't us, each with an honest one-line fit.
   - FAQ for the common follow-up questions, with FAQPage schema if shown on the page.
   - A last-reviewed date and a sources list.
5. Add schema (Article, plus FAQPage if used) and internal links to product and pricing pages.
6. Send the draft to `brand-voice-guardian` for claim and tone review before publishing.

## Output template

```
## Comparison page: <title>
Format: vs / alternatives | Target query: <...> | Last facts check: <date>

Title: <...> | Meta: <...> | H1: <...>
Summary answer (40-60 words): <...>

| Criterion | <Us> | <Competitor> | Source |

Sections: <...>
Who should choose each: <...>
FAQ: <Q/A pairs>
Sources: <URL - date checked>
Claims needing approval: <list>
```

## Quality checks

- Every competitor fact has a public source URL and a check date. No hearsay, no leaked material.
- Our claims come from `brand/claims-and-proof.md` with their caveats.
- No disparaging language. Describe differences; let the reader judge.
- Pricing comparisons carry the caveat from `brand/competitors.md` and the date.
- Glossary names for our products; the competitor's own spelling for theirs.
