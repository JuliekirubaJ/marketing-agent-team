---
name: ab-test-design
description: "Designs an A/B test (hypothesis, variants, primary metric, guardrails, sample size, run length, stop rules) and reads out the result with a confidence interval and a ship decision. Use when planning a test on a page, form, email or ad, when checking whether a test can reach significance, or when a test has finished and needs a verdict."
---

# A/B test design and readout

## When to use

- A test idea from a CRO audit, email review or ad review needs a plan.
- Someone asks "how long do we need to run this?" or "is this result real?".
- A test has ended and needs a decision.

## Inputs

Ask for:
- What is changing, and the evidence behind the idea.
- The primary metric and its current baseline rate.
- Traffic per week that will see the test (visitors, recipients or impressions).
- The smallest lift worth acting on (the minimum detectable effect, MDE).
- For a readout: visitors and conversions per variant, start and end dates.

Read `config/team.md` for cadence (webinar and email schedules limit how long a test can run) and `brand/claims-and-proof.md` if variant copy includes numbers.

## Steps

1. **Hypothesis.** "Because <evidence>, changing <element> to <variant> will raise <metric> for <audience>." One change per test unless it is a deliberate bold redesign.
2. **Metrics.** One primary metric. One or two guardrails (lead quality, unsubscribe rate, bounce rate) that must not get worse.
3. **Sample size per variant** (two variants, 95% confidence, 80% power). A good approximation:

   `n per variant = 16 x p x (1 - p) / d^2`

   where `p` is the baseline rate and `d` is the absolute lift you want to detect.

   | Baseline | Relative lift | Absolute d | n per variant (approx.) |
   |---|---|---|---|
   | 2% | 30% | 0.6 pt | 8,700 |
   | 5% | 20% | 1.0 pt | 7,600 |
   | 10% | 20% | 2.0 pt | 3,600 |
   | 20% | 20% | 4.0 pt | 1,600 |
   | 30% | 10% | 3.0 pt | 3,700 |

   For three or more variants, multiply the total and tighten the confidence level, or don't run that many.
4. **Run length.** `days = 2 x n / daily traffic`. Round up to whole weeks so every weekday is covered. If it is longer than about six weeks, change the plan: test a bolder change (larger d), pool across pages that share a template, test higher in the funnel, or run a dated before/after with its caveats stated.
5. **Stop rules**, written before launch: fixed end date or sample, no peeking decisions, stop early only for a broken variant or a guardrail breach.
6. **QA**: both variants render on desktop and mobile, the split is roughly even, the conversion event fires in both.
7. **Readout.** With `p1 = conversions1 / n1` (control) and `p2 = conversions2 / n2`:
   - absolute difference `diff = p2 - p1`; relative lift `diff / p1`
   - `SE = sqrt(p1(1-p1)/n1 + p2(1-p2)/n2)`
   - 95% interval `diff +/- 1.96 x SE`
   - If the interval excludes zero, the result is significant at about 95%. If it spans zero, call it inconclusive, not "no effect".
   - Check sample ratio: if the split is far from 50/50 (for example 46/54 on thousands of visitors), suspect a bug before trusting the result.
8. **Decision**: ship, don't ship, or re-test, with the guardrails checked.

## Output template

```
## Test: <name>
Hypothesis:
Variants: A (control) = ... | B = ...
Primary metric: <metric>, baseline <x%>   Guardrails: ...
MDE: <relative %> (<absolute pt>)   Sample: <n> per variant   Run: <weeks>, <start> to <end>
Stop rules:
QA checklist: [ ] render [ ] split [ ] events

## Readout (<dates>)
| Variant | Visitors | Conversions | Rate |
Difference: <pt> (<relative %>), 95% CI <low> to <high>
Guardrails: ...
Decision: ship / don't ship / re-test, because ...
```

## Quality checks

- Baseline and traffic come from real data, with the date range named. No invented rates.
- The plan says plainly when the page is too small to test.
- Readout states the interval, not only "it won".
- Variant copy follows `brand/glossary.md` and uses only approved claims.
