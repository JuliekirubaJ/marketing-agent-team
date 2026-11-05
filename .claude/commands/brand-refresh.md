---
description: Process inbox/ and update the brand context in brand/
---

# /brand-refresh

Process every file in the top-level `inbox/` directory, reconcile against the existing canonical brand context, update what needs updating, and preserve provenance by moving sources into `brand/sources/`.

## Inputs

The command accepts three input modes, in any combination:

1. **Files already in `inbox/`** (excluding `README.md`) — the original pattern.
2. **URLs** — a URL provided as a command argument or pasted in the same chat turn (blog post, public LinkedIn post, webinar page, YouTube video).
3. **Pasted text** — raw content pasted directly in the chat turn (e.g., the text of a LinkedIn post, an email excerpt, a short note).

Modes 2 and 3 are materialized into `inbox/` before reconcile begins, so the rest of the workflow is identical regardless of how material arrived. See step 0.

The command also reads: `brand/glossary.md`, `brand/INDEX.md`, and all canonical files in `brand/` (outside `sources/`).

## Workflow

### 0. Materialize non-file inputs into `inbox/`

Before surveying the inbox, convert any URL or pasted-text input into an inbox file.

**For URLs:**
- Fetch the page content with the web-fetch tool. Extract readable text (strip nav, footer, ads).
- For YouTube URLs, use `yt-dlp --write-auto-sub --skip-download --sub-format vtt <url>` in the sandbox to pull auto-captions; parse VTT into plain markdown; include video title, channel, and duration in frontmatter.
- Write to `inbox/YYYY-MM-<slug>.md` with provenance frontmatter:
  ```
  ---
  source_type: blog | linkedin | webinar | youtube | ...
  source_url: https://...
  source_date: YYYY-MM-DD        # published / posted; ask user if unclear
  fetch_date: YYYY-MM-DD         # today
  ---
  ```
- If the fetch returns thin content (auth wall, paywall, JS-only render), STOP and tell the user. Offer the chat-paste fallback.

**For pasted text:**
- Ask the user for the minimum provenance that cannot be inferred: source type, author/poster, source date, source URL (optional). Record `source_url: unknown` if unavailable.
- Write to `inbox/YYYY-MM-<slug>.md` with the same frontmatter shape. Pick the slug from content (author handle + topic); confirm with the user if ambiguous.
- If the pasted text is very long (more than roughly 2,000 words — a full transcript or multi-page article), note to the user that dropping a file would have been cleaner, but proceed.

After materialization, the non-file inputs are indistinguishable from inbox drops. Continue to step 1.

### 1. Survey the inbox

List all inbox files. For each, read it and identify:
- Source type (blog, linkedin, webinar, youtube, deck, announcement, social post, documentation, internal note) — use frontmatter if present, else ask the user
- Source date — frontmatter, filename date prefix, or ask
- Key claims: facts, figures, terminology, positioning statements, feature descriptions, pricing, customer references

If any inbox file lacks frontmatter and its source type or date is not obvious, ask the user before proceeding. Do not guess provenance.

### 2. Load the current canonical state

- Read `brand/glossary.md` in full — know which terms are current vs. deprecated
- Read `brand/INDEX.md` to know what canonical files exist
- Read the canonical files relevant to the topics each inbox file touches

### 3. Reconcile

For each claim in each inbox file, classify it as one of:

- **New fact** — not present in the brand context at all. Propose the canonical file where it should land (existing or new). File naming is flat inside `brand/`: `brand/<topic>.md`. No forced topic-folder taxonomy — organize by what's earned, not prescribed.
- **Confirming fact** — matches existing canonical content. Note it as a supporting source; no canonical change needed.
- **Refining fact** — adds detail to existing canonical content. Propose a specific edit.
- **Contradicting fact** — disagrees with existing canonical content. STOP and flag to user: show the old claim, the new claim, the sources of each, and ask which is current. Never silently overwrite.
- **Terminology shift** — uses a different word for an existing concept. Propose a glossary update (add the new canonical term, mark the old as deprecated) before touching any other file.

### 4. Propose changes to the user

Present a structured diff before writing anything. Example shape:

```
GLOSSARY UPDATES
  - Add: "usage-based pricing" (canonical, as of 2026-04) deprecates "seat-based pricing"

CANONICAL FILE UPDATES
  brand/company.md
    - Replace section "Pricing model" based on 2026-04 announcement
    - Rename references: seat-based → usage-based

NEW CANONICAL FILES
  brand/usage-metering.md — new detail from announcement

CONTRADICTIONS REQUIRING DECISION
  - Existing: brand/company.md says "usage billed hourly"
    New: announcement says "usage billed by usage unit"
    Question: is hourly billing being retired, or is usage unit a new dimension alongside it?

SOURCES TO FILE
  - inbox/2026-04-pricing-change-announcement.md → brand/sources/2026-04-pricing-change-announcement.md
```

Wait for user approval (or per-item selection) before writing.

### 5. Apply approved changes

For each approved change:
- Update the canonical file. Update its `last_reviewed` frontmatter to today's date.
- Update `brand/glossary.md` if terminology shifted.
- Update `brand/INDEX.md` if new canonical files were added.
- Move processed files from `inbox/` to `brand/sources/`, prefixing with `YYYY-MM-` if not already.
- Append one line per material change to `brand/CHANGELOG.md` under today's date.

### 6. Report

Summarize what changed: files touched, glossary shifts, contradictions resolved, items still pending user decision.

## Guardrails

- Never edit files in `brand/sources/` — it is append-only provenance.
- Never change a canonical fact without explicit user approval.
- Never invent dates. If a source date is unknown, ask.
- Never create a new topic folder inside `brand/` unless a file would be genuinely ambiguous at top level. Err toward flat.
- If the inbox is empty, say so and exit.
