---
name: launch-checklist
description: "Sizes a launch into Tier 1, 2 or 3 and produces the matching checklist of assets, owners and dates, from readiness to post-launch review. Use when a product, feature, integration, pricing change or partnership is about to ship, or when planning which launches go into a quarter."
---

# Launch checklist (tiered)

## When to use
- Anything new is about to ship or be announced
- Quarterly planning, to size the launches in the portfolio
- When a team is unsure how much effort a release deserves

## Inputs
Ask the user for: what is launching, availability (GA, preview, limited), launch date, who it is for, and whether any partner is involved.

Read: `brand/company.md` (status of products and features), `brand/positioning.md`, `brand/claims-and-proof.md`, `brand/channels.md`, `brand/glossary.md`, `config/team.md`.

## Steps
1. **Size the tier.**

| Tier | What qualifies | Effort |
|---|---|---|
| T1 | New product, major platform or partner news, pricing model change, anything that changes how we position | Full campaign: press, analyst briefings, webinar, paid, sales training |
| T2 | Significant feature or integration that a persona will notice and that sales will use | Blog, email to customers and prospects, social, sales note, docs, demo update |
| T3 | Improvement or small feature | Release note, short social post, in-product or newsletter mention |

   When in doubt, choose the lower tier. Over-launching small things trains the audience to ignore launches.
2. **Check availability language.** Preview and GA are said differently. Use the status from `brand/company.md` and the terms in `brand/glossary.md`.
3. **Build the checklist** for the tier (below), working back from launch day (L).
4. **Assign an owner agent** to each item and a date.
5. **Set the success measure** before launch, and book the review.

## Output template
```
# Launch: <name> | Tier <1/2/3> | Launch day (L): <date> | Status: <GA / preview>

## Readiness (all tiers)
- [ ] Facts agreed: what, who, availability, limits (product-marketer)       L-<n>
- [ ] Claims checked against brand/claims-and-proof.md (brand-voice-guardian)
- [ ] Docs / release note ready
- [ ] Success measure set

## T2 and T1
- [ ] Messaging house (product-marketer, messaging-house skill)            L-21
- [ ] Sales note + FAQ + demo update (sales-enablement-specialist)        L-7
- [ ] Blog post (content-writer)                                         L-3
- [ ] Customer + prospect email (email-marketing-specialist)              L
- [ ] Social posts (social-media-expert)                                 L
- [ ] Website page / update (content-writer, seo-strategist)             L

## T1 only
- [ ] Press release + comms plan (pr-comms-manager)                      L-14
- [ ] Analyst and media briefings (pr-comms-manager)                     L-7
- [ ] Partner approvals and co-announcement (partner-marketer)            L-14
- [ ] Launch webinar (webinar-producer)                                  L+7 to L+14
- [ ] Paid campaign (paid-ads-manager), if in plan                       L
- [ ] Sales training session (sales-enablement-specialist)               L-3

## Post-launch
- [ ] Results review at L+14 and L+30 (analytics-reporter)
```

## Quality checks
- Tier choice has a one-line reason.
- Availability wording matches `brand/company.md`. Nothing on the roadmap is described as available.
- Only channels listed as in use in `brand/channels.md`.
- Every item has an owner and a date.
