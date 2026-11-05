---
name: landing-page-cro-audit
description: "Heuristic conversion audit of a landing page or webinar registration page, scored by impact and effort, with quick fixes and test ideas. Use when a page converts poorly, before a new landing page goes live, or when someone asks why visitors are not signing up."
---

# Landing page CRO audit

## When to use

- A landing page, registration page or campaign page converts below its usual rate or below the benchmark.
- A new page is about to launch and needs a pre-flight review.
- Before designing an A/B test, to pick what is worth testing.

For pricing pages use `pricing-page-review`. For a form on its own use `form-optimization`.

## Inputs

Ask for:
- The URL, or screenshots of desktop and mobile.
- The conversion goal (registration, demo request, trial start, download).
- Traffic sources and their share, and the ad, post or email that sends most visitors (for message match).
- Current conversion rate and date range, if known.

Read `brand/positioning.md`, `brand/audiences.md`, `brand/claims-and-proof.md`, `brand/glossary.md` and `brand/voice-and-tone.md`.

## Steps

1. **Measurement check.** Confirm the conversion is counted once per real conversion. If it isn't, stop and flag it; the rest of the audit may be judging bad data.
2. **Five-second test.** From the first screen only, write down: what is offered, who it is for, what to do next. If any of the three is unclear, that is the top finding.
3. **Message match.** Compare the headline with the source ad, post or email. The promise that earned the click should be repeated near the top, in similar words.
4. **Clarity.** One page, one goal. Count competing CTAs and exit links (full navigation, footer links, other offers).
5. **Value.** Does the copy say what the visitor gets, in their terms (from `brand/audiences.md`), with specifics: agenda, outcomes, duration, speaker role, date and time zone for events?
6. **Friction.** Form length, required fields, page speed, pop-ups, cookie banners covering the CTA, date and time zone confusion.
7. **Trust.** Proof near the CTA: customer logos or quotes allowed in `brand/company.md`, approved numbers from `brand/claims-and-proof.md`, privacy note under the form.
8. **Mobile.** Check the CTA is visible without much scrolling, text is readable, the form is usable with a thumb, nothing overflows.
9. **Accessibility basics.** Contrast, labelled form fields, alt text, focus states.
10. **Score** each finding: impact H/M/L, effort H/M/L, and whether it is a fix (clear defect) or a test (a judgement call).

## Output template

```
## <Page name> - CRO audit (<date>)
Goal: <conversion>   Current rate: <x% over dates, or "no data: heuristic only">
Top three issues: 1. ... 2. ... 3. ...

| # | Area | Finding | Evidence | Impact | Effort | Fix or test |
|---|------|---------|----------|--------|--------|-------------|

### Quick fixes (ship now)
### Test ideas (hand to ab-test-design)
- Hypothesis: Because <evidence>, changing <element> to <variant> will raise <metric> for <audience>.
### Suggested copy (headline, subhead, CTA) - draft, for copy-editor
### Open questions
```

## Quality checks

- Every number suggested for the page is in `brand/claims-and-proof.md` with its caveat.
- Terms match `brand/glossary.md`.
- Suggested copy is plain and specific: no hype words, no claims the offer can't back.
- Each finding has evidence (a screenshot note, a metric, a quote from the page), not opinion alone.
- No invented benchmarks. If you cite one, say it is a general rule of thumb.
