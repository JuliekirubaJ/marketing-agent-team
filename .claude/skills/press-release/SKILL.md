---
name: press-release
description: "Writes a news release in standard format: headline, subhead, dateline lead, body, quotes, availability, boilerplate and media contact, with every claim checked. Use for launches, partnerships, customer wins, funding, awards or milestones that are news to people outside the company."
---

# Press release

## When to use
- The news passes the test: would a journalist or a customer outside the company care?
- Typically for Tier 1 launches (see `launch-checklist`), partnerships, funding, major customer wins and notable awards
- If the news fails the test, write a blog post instead and say why

## Inputs
Ask the user for: the news in one sentence, the date and any embargo, availability, the quote-givers (name and title), any partner or customer involved, and the media contact.

Read: `brand/company.md` (company description, products, partnerships and their exact wording), `brand/claims-and-proof.md`, `brand/glossary.md`, `brand/voice-and-tone.md`, `brand/positioning.md`. If `brand/company.md` holds a press boilerplate, use it word for word.

## Steps
1. **Headline.** The news, in plain words, under about 12 words. Company name plus what happened. No adjectives that need proof.
2. **Subhead.** One sentence on why it matters to the reader.
3. **Lead paragraph.** Dateline (city, date), then who, what, when, where and why in two or three sentences.
4. **Second paragraph.** The problem this addresses, in the customer's terms.
5. **Detail.** What is new, who it is for, how it works at a high level. Two to three short paragraphs or a short bullet list.
6. **Quotes.** One from the company spokesperson, one from a partner or customer if available. Each quote adds a view or reason, not a repeat of the facts. Draft quotes are marked **[DRAFT QUOTE: needs approval from <name>]**.
7. **Availability.** Status (GA, preview), where to get it, pricing only if public and approved.
8. **Boilerplate** for the company, and for any partner (their approved text).
9. **Media contact.** Placeholder until filled: `<MEDIA CONTACT NAME, EMAIL>`.

## Output template
```
FOR IMMEDIATE RELEASE | or EMBARGOED UNTIL <date, time, timezone>

# <Headline>
## <Subhead>

<CITY>, <Date> -- <Lead paragraph>

<Problem paragraph>

<Detail paragraphs or bullets>

"<Quote>," said <Name>, <Title>, <Company>.

"<Partner / customer quote>," said <Name>, <Title>, <Organisation>.

**Availability**
<...>

**About <Company>**
<Boilerplate from brand/company.md>

**Media contact**
<MEDIA CONTACT NAME, EMAIL>

---
Claim check: (each claim -> source file -> caveat included? Y/N)
Approvals needed: (quote-givers, partner, owner)
```

## Quality checks
- 400-600 words for the body.
- Every number and superlative is in `brand/claims-and-proof.md`, with its caveat. If not, remove it.
- Partner relationship wording matches `brand/company.md` exactly.
- Availability is accurate; no roadmap items stated as available.
- Canonical terms from `brand/glossary.md`. No jargon a general business reporter would have to look up without a short explanation.
