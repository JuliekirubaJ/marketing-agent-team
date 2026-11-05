---
name: marketing-okrs
description: "Writes and scores marketing OKRs: three to five objectives, measurable key results with baselines and owners, and an end-of-period scoring. Use when setting quarterly or annual marketing goals, aligning channel owners on targets, or reviewing how a quarter went."
---

# Marketing OKRs

## When to use
- Start of a quarter or year
- When channel owners are working to different or unstated goals
- End of a period, to score and learn

## Inputs
Ask the user for: the company goal for the period, the pipeline or revenue target marketing is accountable for (if any), the budget, and last period's actuals.

Read: `config/team.md` (roles, rules), `brand/channels.md`, `brand/audiences.md`, `brand/positioning.md`. Ask `analytics-reporter` for last period's numbers if the user does not have them.

## Steps
1. **Start from the company goal.** Every objective should explain how marketing contributes to it.
2. **Write three to five objectives.** Qualitative, specific, and short. "Make the webinar program a reliable pipeline source", not "Improve webinars".
3. **Write two to four key results per objective.** Each one:
   - is a number with a baseline and a target ("from 120 to 200")
   - measures an outcome, not an activity ("qualified registrations", not "emails sent")
   - can be measured with data the team actually has
   - has one owner role
4. **Check the set.** Mix of leading indicators (traffic, registrations, engagement) and lagging ones (pipeline, opportunities). No more than about 15 key results in total.
5. **List the initiatives** that drive each key result, separately from the KRs.
6. **Set the scoring rule.** 0.0-1.0 per KR; 0.7 is a good result on a stretch target. Agree whether targets are stretch or committed.
7. **At the end of the period,** score each KR, write one line on why, and carry the lessons into the next set.

## Output template
```
# Marketing OKRs: <period>
Company goal: <...> | Type: <stretch / committed>

## O1: <objective>
| Key result | Baseline | Target | Owner role | Data source |
Initiatives: <...>

## O2 ...

## Scoring (end of period)
| KR | Target | Actual | Score | Why |
## Lessons for next period
```

## Quality checks
- Every baseline is a real number from a named source, or marked **[NO BASELINE: measure first]**.
- No activity metrics dressed up as key results.
- Every KR has a data source the team can access today; if not, the first initiative is to set up the tracking (`marketing-ops-specialist`).
- Plain wording. Someone outside marketing should understand each objective.
