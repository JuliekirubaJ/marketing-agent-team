---
name: webinar-promotion-timeline
description: "Builds a dated promotion calendar for one webinar, from announcement to the day itself, by channel, using the cadence and standard email sequence in config/team.md and the channels in brand/channels.md. Use when a new webinar is announced, when several webinars in a month need their promotion staggered, or when someone asks what promotion is due this week."
---

# Webinar promotion timeline

## When to use

- A webinar has a confirmed date and title.
- Several webinars fall in the same month and their promotion needs to avoid collisions.

## Inputs

Ask for: title, date, start time and time zone, announcement date (if fixed), speaker, persona, whether it is part of a series, and any paid budget (default: none).

Read: `config/team.md` (cadence, default time, standard email sequence, rules of the house), `brand/channels.md` (channels in use and not used, communities), `docs/webinar-speaker-checklist.md` (master deadline map), and the upcoming-webinars page in `config/paths.md` to see other events in the same window.

## Steps

1. Set T-0 and count back. Default announcement is T-21 to T-16, once title, abstract and headshot are in. If the announcement date is fixed, use that date, not the default.
2. Lay out the standard sequence from `config/team.md`. Default timing: generic invite T-10, non-opener resend T-3, 1-day-to-go T-1, warm attendee T-0 (1-2 hours before), follow-up T+1.
3. Add the channels from `brand/channels.md` only. Typical slots:
   - Website: listing and landing page live at announcement.
   - Company social page: announcement, T-7 post, T-1 "tomorrow" post, T-0 "live in 2 hours" post.
   - Speaker and employee advocacy: personal post at T-7, 2-3 variants circulated the same day.
   - Communities and groups: value-first seeding around T-5, where the community rules allow it.
   - Paid: only if the plan says so (`config/team.md`).
4. Check collisions. With several webinars a month, no two invites go out on the same day, and no contact gets more than the agreed number of webinar emails per week. Stagger by a day where needed.
5. Move dates off weekends and non-working days. Prefer Tuesday to Thursday for invites unless past results say otherwise.
6. Attach a deadline for each asset the slot needs (copy, creative, link) two working days before it goes out.

## Output template

```
# Promotion timeline: <title>
Webinar: <date> <time> <time zone>   Announce: <date>   Paid: none | <budget>

| Date | T- | Channel | Asset | Audience / segment | Asset due | Owner (role) |
|------|----|---------|-------|--------------------|-----------|--------------|

## Collisions with other webinars
## Open items
```

## Quality checks

- Every channel used appears as in use in `brand/channels.md`.
- The email steps match `config/team.md`; any extra send is marked optional.
- Dates are real calendar dates with weekdays, not just T-numbers.
- No paid line unless the plan includes one.
- Titles and hooks use `brand/glossary.md` terms.
