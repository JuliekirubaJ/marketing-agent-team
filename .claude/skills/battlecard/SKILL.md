---
name: battlecard
description: "Writes a one-page competitive battlecard for sellers: how to win, where we differ, landmines to set, objections and answers, and proof. Use when sales faces a competitor in deals, when a competitor changes pricing or launches something, or when an existing battlecard is more than a quarter old."
---

# Battlecard

## When to use
- A competitor shows up in deals and sellers have nothing current to work from
- A competitor launches, reprices or repositions
- Quarterly refresh of existing cards

## Inputs
Ask the user for: the competitor, the deal stage the card is for, and any recent win/loss notes or call snippets.

Read: `brand/competitors.md` (agreed view and pricing caveats), `brand/positioning.md`, `brand/claims-and-proof.md`, `brand/company.md`, `brand/glossary.md`. Get current facts from `competitive-intel-analyst` or a recent `competitor-teardown`. Use `win-loss-analysis` output for objections if it exists.

## Steps
1. **Confirm the facts are current.** Any competitor fact older than 90 days gets re-checked against the competitor's own pages. Every fact gets a link and date.
2. **Write "how we win" in three bullets:** the situations where we win most often, and the one question that tends to swing the deal.
3. **Write "how we lose" honestly.** Where the competitor is a better fit. Sellers trust a card that admits this, and it saves time on deals that cannot be won.
4. **Build the comparison** on the points buyers actually decide on, not on every feature. Five to eight rows.
5. **Write landmines:** neutral discovery questions that bring our strengths into the conversation without attacking the competitor.
6. **Write objections and answers.** Acknowledge, answer, offer proof. Two or three sentences each.
7. **Add proof:** approved customer stories, numbers with caveats, partner references with the exact wording from `brand/company.md`.
8. **Mark the date and the next review date.**

## Output template
```
# Battlecard: <our product> vs <competitor>
Updated: <date> | Next review: <date> | Sources: <links>

## In one line
## How we win (3 bullets)
## How we lose (2 bullets, honest)
## Where we differ
| Decision point | Us | Them | Source + date |
## Landmine questions (3-5)
## Objections
| They say | We say | Proof |
## Proof to cite (claim + caveat + source file)
## Do not say
```

## Quality checks
- One page. If it runs longer, cut the comparison rows first.
- Every competitor fact is sourced and dated; pricing carries the caveat from `brand/competitors.md`.
- Every claim about us is in `brand/claims-and-proof.md`.
- Nothing disparaging. Assume the card will be forwarded to the competitor.
- Canonical product names from `brand/glossary.md`.
