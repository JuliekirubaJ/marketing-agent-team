---
name: content-refresh
description: "Diagnoses why an existing page is losing search traffic or AI citations and writes a page-specific refresh plan with exact changes. Use when a page shows sustained declines in clicks, impressions or position, when its facts are out of date, or when a page needs to become more quotable for AI answers."
---

# Content refresh

## When to use

- A page has lost clicks or position over a sustained period (not one bad week).
- Product facts, screenshots or claims on the page are out of date.
- A page should be cited in AI answers for its topic and isn't.

## Inputs

- The URL, site key and the page's target keyword (tracked keywords list).
- Search Console page and query x page data for two comparable periods (at least 3 months each; year on year for seasonal topics).
- `content-updates.csv` (past edits to this page) and `<site-key>-rankings-history.csv`.
- `brand/claims-and-proof.md`, `brand/glossary.md`, `brand/positioning.md`, `brand/voice-and-tone.md`.

## Steps

1. Quantify the decline: clicks, impressions, CTR and average position, both periods, with the source file.
2. Read the cause from the pattern:
   - Impressions steady, CTR down: SERP features or AI Overviews absorbing clicks, or a weaker title.
   - Impressions and position down: competitors overtook us, intent shifted, or links were lost.
   - Queries moving to another of our URLs: cannibalization.
   - Drop right after an edit or a site change: check the content log and the technical side.
3. Read the current top results for the main query and list what they offer that we don't.
4. Audit the page itself: stale facts and dates, outdated product names (check `brand/glossary.md`), missing answer block, missing sections, broken links, thin examples.
5. Decide the scope: light (title, meta, intro, facts), medium (new sections, restructure) or rewrite. If another of our pages covers the same ground, consider merging instead.
6. Write the changes: new title and meta, a 40-60 word answer block for the main question, sections to add or cut, facts to update with their source, links to add.
7. Record the plan date so the result can be read later, and ask the owner to log the publish date in `content-updates.csv`.

## Output template

```
## Refresh plan: <URL>
Target keyword: <...> | Periods compared: <...> vs <...> | Source: <files>

| Metric | Before | After | Change |
Likely cause: <one paragraph, with evidence>
Scope: light / medium / rewrite / merge into <URL>

### Changes
- Title: <exact> | Meta: <exact>
- Answer block: <40-60 words>
- Add: <sections> | Remove or update: <...>
- Facts to update: <old -> new, source file>
- Internal links: <from/to, anchor>
- Schema: <changes>

### How we'll know it worked
<metric, check date 4-8 weeks after publishing>
```

## Quality checks

- Every number in the before/after table comes from a named export.
- Updated facts trace to `brand/claims-and-proof.md`; anything without a source is flagged.
- Change the visible "updated" date only for substantive changes.
- Copy reads as plain, natural prose, consistent with `brand/voice-and-tone.md`.
