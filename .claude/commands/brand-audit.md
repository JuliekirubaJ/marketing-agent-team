---
description: Audit the brand context for staleness and inconsistency
---

# /brand-audit

Scan the canonical brand context for staleness and inconsistency. Read-only — produces a report, never writes.

## What to check

### 1. Staleness
- Every canonical file should have a `last_reviewed` frontmatter date.
- Flag any file where `last_reviewed` is older than 60 days.
- Flag any file missing `last_reviewed` entirely.

### 2. Deprecated terms in canonical content
- Parse `brand/glossary.md` for all deprecated terms.
- Grep every canonical file in `brand/` (excluding `sources/`) for deprecated term occurrences.
- Report each hit with file path, line number, and the canonical replacement from the glossary.

### 3. Contradiction scan
- For topic areas where the brand context has multiple files, scan for claims about the same fact (pricing, features, audiences, partnership terms, customer counts).
- Flag any pairs where the claims disagree (different numbers, different wording that implies different meaning, different dates).
- This is heuristic — err toward flagging for human review rather than silently filtering.

### 4. Orphaned references
- Any canonical file that references another file (e.g., "see pricing.md") — verify the target exists.
- Report broken pointers.

### 5. Index coverage
- Every canonical file in `brand/` (outside `sources/`) should appear in `brand/INDEX.md`.
- Report files present in the brand context but missing from the index, and index entries pointing to files that don't exist.

### 6. Sources without canonical integration
- List files in `brand/sources/` that have no corresponding canonical content yet.
- Informational — sources can legitimately sit in the archive without being distilled, but it flags opportunities for curation.

## Output format

Produce a structured report, for example:

```
BRAND CONTEXT AUDIT — 2026-04-21

STALE FILES (last_reviewed > 60 days)
  brand/competitors.md — last_reviewed 2026-01-15 (96 days)

DEPRECATED TERMS IN CANONICAL CONTENT
  brand/positioning.md:34 — "seat-based pricing" → use "usage-based pricing"

CONTRADICTIONS (review needed)
  Customer count:
    brand/company.md:12 — "5,000+ customers"
    brand/messaging-pillars.md:8 — "4,000+ customers"

ORPHANED REFERENCES
  brand/competitor-x-comparison.md:45 — references roadmap.md (not found)

INDEX COVERAGE
  Missing from INDEX.md:
    brand/usage-metering.md
  Stale index entries:
    INDEX.md references brand/old-file.md (not found)

UNINTEGRATED SOURCES
  brand/sources/2026-03-conference-webinar.md — not yet distilled into canonical content
```

## Follow-up

After presenting the report, offer to:
- Run `/brand-refresh` if the user wants to rebuild stale content from new sources
- Do targeted terminology sweeps for specific deprecated terms
- Update `last_reviewed` on files the user confirms are still current

## Guardrails

- Read-only. This command never writes.
- Report everything — do not filter "small" issues. Trust the user to triage.
- If the brand context is nearly empty (no canonical files yet), report that and suggest starting with `/brand-refresh` after seeding the inbox.
