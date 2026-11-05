---
name: abm-account-plan
description: "Writes an account-based marketing plan for one target account (Tier 1) or a cluster of similar accounts (Tier 2): fit and intent evidence, buying committee by role, triggers, messages per role, a channel and content sequence, sales actions and account-level metrics. Use when sales and marketing need a shared play for a named account or segment."
---

# ABM account plan

## When to use

- A Tier 1 account needs a one-to-one plan.
- A Tier 2 cluster (same industry, size or use case) needs a one-to-few play.
- Sales asks marketing to help open or expand a specific account.

## Inputs

Ask for:
- Account name or cluster definition, tier, and the sales owner.
- The goal: new logo, expansion, renewal risk, or competitive displacement.
- What we already know: CRM history, open opportunities, past engagement, current tools.

Read `brand/audiences.md` (ICP, buying committee roles, pain points), `brand/positioning.md`, `brand/competitors.md`, `brand/claims-and-proof.md`, `brand/company.md` (which customers may be named as proof) and `brand/channels.md`.

Use public business information only (annual reports, press releases, job posts, company news). Do not compile personal profiles of individuals; describe roles, not private details.

## Steps

1. **Fit.** Why this account matches the ICP: industry, size, region, tech stack, team structure. Cite source and date for each fact.
2. **Intent and triggers.** Recent signals (hiring for relevant roles, system changes, leadership changes, funding, public initiatives, engagement with our content or webinars). Rate each signal strong, medium or weak and say why.
3. **Buying committee.** By role: economic buyer, champion, technical evaluator, users, blockers. For each: what they care about, likely objections, and what proof moves them. Mark unknown roles as gaps for sales to fill.
4. **Core message.** One sentence on the problem this account likely has and what changes for them. Then one line per role.
5. **Play sequence** over 6-12 weeks: week, role, channel (only channels in `brand/channels.md`), asset, CTA, owner. Mix paid (matched audiences), email, webinar invites, tailored content and sales touches. Reuse assets where possible (see `content-repurposing`).
6. **Sales actions.** What sales does when the account engages: who reaches out, how fast, with which talk track.
7. **Metrics.** Account-level: roles engaged, pages and sessions from the account, webinar attendees, meetings, opportunity created, pipeline value. Set a review date.
8. **Risks and gaps.** Missing contacts, weak signals, facts to verify.

## Output template

```
## Account plan: <account or cluster> (Tier <n>) - <date>
Goal: ...   Sales owner: ...   Marketing owner: ...   Review: <date>

### Why this account (fit)        - fact (source, date)
### Signals and triggers          | Signal | Strength | Source | Date |
### Buying committee              | Role | Cares about | Objections | Proof | Known? |
### Core message + per-role lines
### Play sequence                 | Week | Role | Channel | Asset | CTA | Owner |
### Sales actions on engagement
### Metrics and targets
### Risks and open questions
```

## Quality checks

- Every account fact has a source and date; nothing guessed is stated as fact.
- Product claims come from `brand/claims-and-proof.md` with caveats; named customers only if `brand/company.md` allows.
- Channels used are all in `brand/channels.md`.
- Plain, specific language; no "synergy" or "unlock" filler.
