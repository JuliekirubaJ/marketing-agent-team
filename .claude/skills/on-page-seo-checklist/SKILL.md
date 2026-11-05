---
name: on-page-seo-checklist
description: "Runs a page-level SEO and answer-readiness check on one URL or draft and returns exact replacement text for anything that fails. Use when optimizing an existing page, reviewing a draft before it goes live, or when someone asks why a specific page isn't ranking."
---

# On-page SEO checklist

## When to use

- Reviewing a draft before publishing.
- Optimizing a live page for a target keyword.
- A template-level check across several pages of the same type.

## Inputs

- The URL or draft, the site key, and the target keyword (from the tracked keywords list if it's there).
- `brand/glossary.md` (deprecated terms on a live page are an issue) and `brand/claims-and-proof.md`.
- For a live page, read the raw HTML with curl or the crawler output (`sf\internal_all.csv`). Don't rely on a markdown conversion: it drops the `<head>`.

## Steps

Check each item and mark Pass, Fail or N/A:

1. **Title tag:** present, unique, 60 characters or less, target keyword near the front, reads like something a person would click.
2. **Meta description:** 155 characters or less, includes the keyword, gives a concrete reason to click.
3. **H1:** exactly one, close to the title, contains the keyword or a close variant.
4. **Headings:** logical H2/H3 order, secondary terms used naturally, question-phrased where the query is a question.
5. **Opening:** the first 100 words say what the page is about and include the keyword once. Question pages lead with a 40-60 word direct answer.
6. **Content fit:** matches the intent of the current top results; covers what they cover; adds something they don't.
7. **Facts and freshness:** numbers and claims match `brand/claims-and-proof.md`; dates and version references are current.
8. **Terminology:** no deprecated terms from `brand/glossary.md`.
9. **Images:** descriptive alt text, sensible file names, compressed, width and height set.
10. **Internal links:** 2-5 contextual links out with descriptive anchors; at least two relevant pages link in.
11. **External links:** cite sources for third-party facts; no broken links.
12. **URL:** short, readable, lowercase, hyphenated, keyword-bearing.
13. **Canonical and robots:** self-referencing canonical; no stray noindex.
14. **Schema:** right type for the page, valid, matches visible content (see `schema-markup`).
15. **CTA:** one clear next step, visible without scrolling and at the end.
16. **Mobile and speed:** no layout shift from late-loading elements; heavy embeds deferred.

## Output template

```
## On-page check: <URL or draft name>
Target keyword: <...> | Checked: <date> | Source: <raw HTML / crawler / draft>

| # | Check | Result | Current | Recommended (exact text) |

### Top 3 changes by impact
```

## Quality checks

- Recommendations give exact replacement text with character counts, not "improve the title".
- Copy uses `brand/glossary.md` terms and `brand/voice-and-tone.md`; no keyword stuffing.
- Don't invent claims to make a meta description more exciting.
