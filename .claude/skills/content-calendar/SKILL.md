---
name: content-calendar
description: "Builds a weekly or monthly content calendar across the channels we use, balancing content types, webinar promotion windows, recurring series and owner capacity, with every slot dated and assigned. Use when planning next month's content, slotting a new campaign or webinar into existing plans, or checking a calendar for gaps and overload."
---

# Content calendar

## When to use

- Planning the next week, month or quarter of content.
- A new webinar, launch or campaign needs to fit into what is already planned.
- The current calendar looks thin, crowded or one-note.

## Inputs

Ask for:
- Period to plan and any fixed dates (webinars, launches, events, holidays).
- Existing calendar or planner, if any (file path).
- Team capacity: who writes, designs and edits, and how many pieces each can take per week.
- The goals for the period.

Read `brand/channels.md` (channels in use and NOT used), `config/team.md` (webinar cadence, standard email sequence, team, timezone), `config/paths.md`, `brand/audiences.md` and `brand/positioning.md` (messaging pillars).

## Steps

1. **Pin the fixed dates** first: webinars, launches, events. For each webinar, add its promotion window and post-event deliverables (recording T+1, clips by T+2, companion page T+3, per `docs/video-production.md`) and the email sequence from `config/team.md`.
2. **Set the channel rhythm.** Posts per week per channel, based on what the team can sustain, not on what is ideal. A steady cadence beats bursts.
3. **Balance the mix** each week across messaging pillars and content types: educational, product, proof (customer or community), promotional, and recurring series. As a starting point, keep promotional pieces to about a third of the slots.
4. **Fill from what exists.** Pull pieces from repurposing plans before commissioning new work.
5. **Check load.** Count pieces per owner per week against capacity. Move or cut, don't overbook.
6. **Check collisions.** No two promotional asks to the same audience on the same day; no promo landing on a public holiday in the main market (timezone from `config/team.md`).
7. **Assign** owner, due date (draft) and publish date for every slot. Leave one or two open slots a month for timely news.
8. **Mark dependencies**: design, video, review and approval steps that must finish first.

## Output template

```
## Content calendar: <period> (v<n>, <date>)
Goals: ...   Fixed dates: ...

| Week of | Day | Channel | Format | Title / angle | Pillar | Type | Owner | Draft due | Publish | Depends on | Status |

### Load by owner
| Owner | Wk1 | Wk2 | Wk3 | Wk4 | Capacity |

### Notes: risks, open slots, items moved to backlog
```

For a spreadsheet, use the same columns; one row per piece.

## Quality checks

- No channel that `brand/channels.md` says we don't use.
- Every slot has an owner and date; no owner over capacity.
- Webinar deliverable dates follow `docs/video-production.md`.
- Titles use glossary terms and plain language.
