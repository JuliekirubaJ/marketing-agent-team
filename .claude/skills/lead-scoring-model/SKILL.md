---
name: lead-scoring-model
description: "Designs or tunes a lead-scoring model that combines fit (who they are) and engagement (what they do), with decay, negative signals and a sales-ready threshold agreed with sales. Use when building scoring for the first time, when sales says marketing leads are poor, or when webinar and event leads need tiering."
---

# Lead-scoring model

## When to use

- No scoring exists and leads go to sales unfiltered.
- Sales reports that handed-over leads are not ready.
- A batch of webinar or event leads needs tiering into hot, warm and nurture.

## Inputs

Ask for: the CRM and automation platform in use, the fields available (title, company size, industry, country), the engagement events tracked (webinar registration and attendance, poll answers, Q&A, page visits, email clicks, demo or pricing page views, trial sign-up), and 6-12 months of closed-won and closed-lost leads if available.

Read: `brand/audiences.md` (ICP, personas, job titles), `brand/company.md` (offers, trial).

## Steps

1. **Fit score (0-50).** Points for role match, company size, industry and region in the ICP. Negative points for students, competitors, consultants outside the ICP, personal email domains, and excluded regions.
2. **Engagement score (0-50).** Weight by intent, not volume. Typical order from high to low: demo or contact request, pricing page, trial sign-up, webinar attendance with a question asked, webinar attendance, poll answer, content download, email click, webinar registration without attending, email open (low or zero, since opens are unreliable).
3. **Decay.** Engagement points fade over time, for example halve after 30 days of inactivity and reset after 90.
4. **Threshold.** Set the sales-ready line (for example fit 30+ and engagement 25+) so that sales can handle the weekly volume. Any direct demo request goes to sales regardless of score.
5. **Back-test.** Score past leads. Check that closed-won leads would have crossed the line and that most closed-lost or no-response leads would not. Adjust weights, not the threshold, first.
6. **Agree with sales:** definition of a sales-ready lead, follow-up time, and what sales does with a lead they reject (it returns to nurture with a reason).
7. **Review quarterly.**

## Output template

```
# Lead-scoring model v<n>
## Fit (max 50)
| Attribute | Value | Points |
## Engagement (max 50)
| Action | Points | Decay |
## Negative signals
## Thresholds
Sales-ready: ...   Nurture: ...   Recycle: ...
## Back-test result
## Agreed with sales (SLA, rejection loop)
## Review date
```

## Quality checks

- Email opens carry little or no weight.
- Every weight can be explained in one sentence.
- Back-test results are shown, or the model is labelled untested.
- No conversion rates or benchmarks stated without a source.
