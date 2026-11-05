---
name: campaign-postmortem
description: "Runs a short, evidence-based review of a finished campaign, webinar or event: goals against results through the funnel, what drove them, what to keep and change, with each finding tied to a number. Use at T+7 after a webinar, about 30 days after an event, at the end of a campaign, or when someone asks why a campaign over- or under-performed."
---

# Campaign post-mortem

## When to use

- A webinar is a week past (registrations, attendance and follow-up clicks are in).
- An event is about a month past (early pipeline is visible).
- A campaign has ended, or results look unusual.

## Inputs

Ask for: the plan (goals, budget, channels, dates), results by channel and stage (reach, clicks, registrations or leads, attendance, engaged, meetings, opportunities, pipeline), email metrics per send, costs, and any changes during the campaign (date moves, list changes, creative swaps).

Read: `config/team.md` (cadence, rules of the house), `brand/channels.md`. For comparison, earlier post-mortems or reports if they exist.

## Steps

1. **Restate the goal** and the primary metric as the plan set them. If the plan had no goal, say so and compare with the last few similar campaigns instead.
2. **Build the funnel** with numbers and conversion rates per step. For a webinar: registrations by source, registration-to-attendance rate, average watch time, poll and Q&A participation, follow-up clicks, meetings.
3. **Compare** with the goal and with the last 3-5 comparable campaigns. Use medians, not one outlier.
4. **Explain movements** only with evidence: timing, topic, speaker, channel mix, list changes, send collisions, platform issues. For email drops, check list changes first.
5. **Separate** what we controlled (copy, timing, channel mix) from what we did not (holidays, competing events).
6. **Decide:** 3 things to keep, 3 to change, each with an owner and the next campaign it applies to.
7. **Note data gaps** (missing UTMs, untracked sources) as gaps, without guessing at the missing numbers.

## Output template

```
# Post-mortem: <campaign> (<dates>)
Goal: ...   Result: ...   Verdict: met | partly met | missed

## Funnel
| Stage | Result | Rate | Goal | Last-5 median |

## By channel
| Channel | Spend | Registrations / leads | Cost per | Note |

## What drove the result (with evidence)
## Keep
## Change (owner, applies to)
## Data gaps
```

## Quality checks

- Every claim ties to a number in the tables.
- No process gap is claimed without evidence.
- List changes are named next to any email metric change.
- Crisp and straight: short sentences, no padding, no blame.
- No invented benchmarks; external figures cite a source.
