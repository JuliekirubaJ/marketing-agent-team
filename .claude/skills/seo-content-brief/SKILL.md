---
name: seo-content-brief
description: "Produces an SEO content brief for one page: target keyword and intent, SERP gap, title and meta, heading outline, answer blocks, internal links, schema and CTA. Use before a writer starts a blog post, landing page or guide, or when a refresh is big enough to need a new brief."
---

# SEO content brief

## When to use

- Before any new piece of search-led content is written.
- When a refresh changes the angle or intent of an existing page.

## Inputs

- Target keyword or cluster (from `keyword-clustering` if one was run), site key, and the funnel stage.
- Who the reader is: `brand/audiences.md`.
- What we can say: `brand/positioning.md`, `brand/claims-and-proof.md`, `brand/glossary.md`, `brand/voice-and-tone.md`.
- The content planner from `config/paths.md`, to avoid duplicating a planned or published piece.
- Search Console data for the keyword, if we already get impressions for it.

## Steps

1. Confirm the intent by reading the current top results with WebSearch. Note the format that wins (guide, list, comparison, tool page, video) and match it.
2. Note what the top pages all cover (table stakes) and what none of them covers well (our angle). The angle should come from something we know that they don't: product experience, customer proof, data.
3. Check whether we already have a page for this. If yes, recommend a refresh instead of a new page.
4. Write the title (60 characters or less, keyword near the front, a reason to click) and meta description (155 or less).
5. Build the outline: one H1, H2s that follow the reader's questions in order, question-phrased where natural. Under each question-type H2, plan a 40-60 word direct answer first, then the detail.
6. List the facts, numbers and examples the piece must include, each with its source in `brand/`.
7. Plan internal links: 3-5 links out to related pages and 2-3 existing pages that should link in, with anchor text.
8. Specify schema (Article plus FAQPage, HowTo or VideoObject only where the content really has that shape) using the `schema-markup` skill.
9. Pick one CTA that fits the funnel stage.

## Output template

```
## Brief: <working title>
Site: <key> | URL: <proposed slug> | Funnel stage: <...> | Format: <...>

Primary keyword: <...> (intent: <...>)
Secondary keywords: <3-5>
Reader: <persona from brand/audiences.md> | Their question: <one sentence>

SERP summary: <what ranks and why> | Our angle: <the gap we fill>

Title: <...> (<n> chars)
Meta description: <...> (<n> chars)
H1: <...>

Outline:
- H2 <question or topic> - direct answer: <one-line gist> - covers: <...>
- ...

Must-include facts (with source file):
Internal links out: <URL - anchor> | Links in from: <URL - anchor>
Schema: <types>
CTA: <...>
Length guide: <range, based on what the SERP needs>
```

## Quality checks

- Every product fact traces to `brand/`. Anything else is marked "verify".
- Terms follow `brand/glossary.md`.
- No invented search volumes or traffic forecasts.
- The angle is something a competitor page couldn't copy by changing the logo.
