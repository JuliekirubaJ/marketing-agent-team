---
name: marketplace-listing-optimizer
description: "Audits and rewrites a product listing on a cloud marketplace or platform app store: title, short and long description, keywords, categories, media, offer and reviews. Use when creating a new listing, when a listing gets views but few trials or contacts, or when a marketplace changes its listing format."
---

# Marketplace listing optimizer

## When to use
- Publishing a new listing on a cloud marketplace such as AWS Marketplace, Azure Marketplace or Google Cloud Marketplace, or on a platform's own app store
- An existing listing has traffic but low conversion
- The product, pricing or positioning has changed since the listing was written

## Inputs
Ask the user for: the listing URL (or the marketplace, if new), listing analytics if available (views, clicks to trial or contact, conversions), the offer type (free trial, private offer, transactable plan, contact me), and any marketplace guidelines document.

Read: `brand/company.md` (products, availability, partner wording), `brand/positioning.md`, `brand/audiences.md`, `brand/claims-and-proof.md`, `brand/glossary.md`, `brand/competitors.md`.

## Steps
1. **Read the marketplace's current rules.** Character limits, required fields, banned claims, image sizes, category options. Fetch them; they change.
2. **Look at the search results** for the main terms buyers use on that marketplace. Note which listings rank, how they title themselves, and what their first lines say.
3. **Audit the current listing** field by field against the rules and against the top listings: clarity, keywords, proof, media, call to action.
4. **Rewrite the title.** Product name as in `brand/glossary.md`, plus what it does, within the limit. No keyword stuffing.
5. **Rewrite the short description** (the text shown in search results). Lead with the outcome for the main persona.
6. **Rewrite the long description:** the problem, what the product does, key capabilities as scannable bullets, who it is for, proof, how to get started.
7. **Choose keywords and categories.** Terms buyers actually search for on the marketplace, not internal names.
8. **Plan the media:** screenshots that show the product doing the job, a short demo video, an architecture diagram if buyers are technical.
9. **Review the offer and call to action.** Is the next step clear and low effort?
10. **Plan reviews.** Ask satisfied customers to review, following the marketplace's rules on solicitation.

## Output template
```
# Listing: <product> on <marketplace> | Checked: <date>
## Rules that apply (limits, banned claims)
## Audit
| Field | Current | Issue | Fix |
## Rewritten fields (each with character count / limit)
- Title
- Short description
- Long description
- Keywords / search terms
- Categories
## Media plan
## Offer and call to action
## Reviews plan
## Measure (baseline -> target for views, clicks, conversions)
```

## Quality checks
- Every field within the marketplace's current limits, with counts shown.
- Claims approved in `brand/claims-and-proof.md`; partner wording exactly as in `brand/company.md`.
- No competitor names in the listing unless the marketplace allows and `brand/competitors.md` approves comparisons.
- Canonical product names from `brand/glossary.md`.
- Plain, scannable prose written for a buyer comparing several listings quickly.
