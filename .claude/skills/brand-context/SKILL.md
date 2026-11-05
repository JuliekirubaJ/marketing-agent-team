---
name: brand-context
description: Entry point for any substantive marketing work about the company or its products. Loads the glossary and brand index so every other agent and skill grounds in current, approved facts. Use whenever writing, reviewing, comparing or explaining anything about the company, its products, positioning, pricing or competitors, or when terminology compliance matters.
---

# Brand context: entry point

This skill holds no facts on purpose. It tells you where the facts live: `brand/`. Update the facts there without touching this skill.

## Read these first

Before you produce any content about the company or its products, read in this order:

1. `brand/glossary.md`: canonical terms only. Never use a deprecated form in new content.
2. `brand/INDEX.md`: the map of the brand context. Follow it to the files the task needs.
3. `config/team.md`: house rules (tone of reports, writing style, webinar program).

If the brand context is thin on the topic, say so plainly. Don't fill gaps with guesses, because a guess that ends up in published content does damage.

## Source discipline

- **Canonical claims** must trace to a file in `brand/` (outside `sources/`). Numbers must appear in `brand/claims-and-proof.md` with their caveat.
- **Supporting color** (quotes, customer stories, exact wording from a webinar) can come from `brand/sources/`. Cite the file path so the source stays traceable.
- When sources disagree, `brand/source-authority.md` decides which one wins.

## When facts conflict

If two brand files disagree, stop and flag it to the user. Don't pick a winner silently. Propose how to reconcile them, and offer `/brand-audit` to find other places with the same inconsistency.

## When the user contradicts the brand context

Go with the user for the current conversation, flag the contradiction, and offer to update the brand file. Usually that means `/brand-refresh` with the new material dropped into `inbox/`.
