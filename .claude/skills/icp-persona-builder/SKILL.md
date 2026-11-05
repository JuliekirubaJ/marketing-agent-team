---
name: icp-persona-builder
description: "Builds or refreshes the ideal customer profile and buyer personas from customer data, interviews and community research. Use when targeting is vague, when a new segment or product needs personas, or when brand/audiences.md is thin or out of date."
---

# ICP and persona builder

## When to use
- `brand/audiences.md` is empty, generic or older than a few months
- A new product, segment or region needs its own targeting
- Campaign results suggest the team is reaching the wrong people
- Sales and marketing disagree about who the buyer is

## Inputs
Ask the user for:
- Best-fit customers (10-20 if possible): industry, size, region, how they found us, time to close, expansion since
- Lost or churned accounts, if available
- Any interview notes, call transcripts or survey answers

Read: `brand/audiences.md`, `brand/company.md`, `brand/positioning.md`, `brand/competitors.md`, and any relevant files in `brand/sources/`. Use community research from `reddit-strategist` or `linkedin-strategist` for language, not for firmographics.

## Steps
1. **Separate the ICP from personas.** The ICP describes the company that buys. Personas describe the people inside it.
2. **Find the ICP pattern.** From best-fit customers, list the shared firmographics (industry, size band, region), technographics (systems already in place) and trigger events (new leader, failed project, platform migration, audit, growth spurt).
3. **Write disqualifiers.** Which companies look like a fit but are not, and why. These are as useful as the fit criteria.
4. **Identify the buying group.** Usually an economic buyer, a champion, technical evaluators and end users. Name each by role and typical job titles.
5. **Build each persona** with the template below. Every pain must trace to a source: an interview, a review, a community thread, a sales note. Quote real phrasing where you have it.
6. **Map content to stage.** For each persona, what they need to read or see when they become aware, when they evaluate and when they decide.
7. **Propose the edit** to `brand/audiences.md` as a diff for the owner to approve. Do not overwrite it.

## Output template
```
# ICP: <segment>
- Firmographics: industry, size band, region
- Technographics: systems they already run
- Trigger events
- Disqualifiers
- Evidence: <n> customers analysed, sources

# Persona: <role name>
- Typical titles
- Role in the buying group (economic buyer / champion / evaluator / user)
- What they are measured on
- Top 3 pains (each with source and a real quote if available)
- What they have tried before, and why it fell short
- Objections they raise
- Where they research and whom they trust
- Message that lands (one sentence, tied to a pillar in brand/positioning.md)
- Content by stage: awareness / evaluation / decision
```

## Quality checks
- Every pain and quote has a source. No invented quotes, no invented statistics.
- Job titles are real titles people use, not marketing labels.
- Terms match `brand/glossary.md`.
- Personas are distinct: if two personas share the same pains and messages, merge them.
- Plain prose. A persona is a working tool, not a character sketch with a stock-photo name.
