---
name: nurture-sequence-design
description: "Designs an email nurture journey: entry trigger, segments, step timing, branches, one goal per email, suppression and exit rules, and a brief per step for the copywriter. Use for post-webinar nurture (attendees, no-shows, engaged), trial onboarding, event follow-up, re-engagement of quiet contacts, or warming a cold or win-back segment."
---

# Nurture sequence design

## When to use

- A webinar, event or trial needs follow-up beyond the standard sequence.
- A segment has gone quiet and needs a re-engagement path.
- A cold, win-back or imported segment must be warmed before it joins the main list.

## Inputs

Ask for: the entry trigger, the audience and its size, the single goal (demo, trial activation, next webinar, reply), the offers and content available, other sends these contacts already get, and the sales handoff rule.

Read: `brand/audiences.md`, `brand/company.md` (offers), `brand/voice-and-tone.md`, `config/team.md` (cadence and standard sequence, so the nurture does not collide with webinar invites).

## Steps

1. **Define:** entry, goal, exit (goal reached, unsubscribed, handed to sales, sequence ended), and suppression (already in another active journey, customer, recent sales contact).
2. **Pick the track pattern.**
   - *Post-webinar:* attendees get the deepest content and a direct next step; engaged attendees (asked a question, answered a poll) go to sales or a personal email; no-shows get the replay first, then one useful follow-up.
   - *Trial or onboarding:* trigger on the activation steps, not on the calendar. Nudge only when a step has not happened.
   - *Re-engagement:* 2-3 emails over two to three weeks, best content, a clear "still want to hear from us?" step, then sunset non-responders.
   - *Warming a cold segment:* small batches, most engaging content, separate from the main list; merge only those who open or click.
3. **Space the steps.** Usually 3-5 emails, 3-7 days apart. Count webinar invites the same contacts will get and keep the weekly total within the agreed cap.
4. **One goal per email.** Write a step brief: purpose, the one point, the CTA, the content asset.
5. **Branches:** clicked the CTA, replied, visited pricing, or no action. Keep branching shallow, two levels at most.
6. **Measure:** the journey goal rate, plus per-step clicks and unsubscribes. Set a review date.

## Output template

```
# Nurture: <name>
Entry: ...   Goal: ...   Audience: <segment, size>
Exit: ...   Suppression: ...   Weekly cap check: ...

| # | Timing / trigger | Segment / branch | Purpose | Key point | CTA | Asset |

## Step briefs (for email-marketing-specialist)
## Sales handoff rule
## Success metric and review date
```

## Quality checks

- One goal for the journey, one CTA per email.
- Every journey has an exit and a suppression rule.
- Cold segments are never mixed straight into the main list.
- Offers and claims match `brand/company.md` and `brand/claims-and-proof.md`; terms match `brand/glossary.md`.
- Plain, human tone; no fake urgency.
