---
name: webinar-run-of-show
description: "Builds a minute-by-minute run-of-show for one webinar, with roles, cues, poll timing, Q&A handling and failure fallbacks, plus a day-of checklist. Use when a webinar needs its running order, moderator script, polls or day-of plan, usually by T-7 and locked at the dry run."
---

# Webinar run-of-show

## When to use

- A webinar is about a week out and the deck outline exists.
- A moderator or new speaker needs a script to follow.
- A customer or partner guest is joining and handoffs need planning.

## Inputs

Ask for: title, date, start time and time zone, total length, speaker(s), moderator, producer, the agenda (4-5 bullets), demo plan, the one CTA, the poll topics, and whether Q&A is live or pre-submitted.

Read: `docs/webinar-speaker-checklist.md` (sections 4, 6, 8, 9), `config/team.md` (platform, default time), `brand/glossary.md`, `brand/claims-and-proof.md`.

## Steps

1. Fix the split. A typical 45-60 minute session: welcome and housekeeping (3-5), framing slides (10-15), live demo (25-30), Q&A (10), close and CTA (2-3). Adjust to the speaker's plan, but keep the demo as the centre.
2. Write the pre-show block: panelists join 30 minutes early, sound and screen-share check, practice mode on, recording settings confirmed, polls loaded, holding slide up.
3. Script the moderator's opening word for word: welcome, who is speaking, length, how to ask questions, that it is recorded and the recording will be sent.
4. Place polls. Poll 1 in the first 5 minutes (warms the room, tells the speaker who is there). Poll 2 just before Q&A or the CTA (qualifies interest). Two polls is usually enough. Each poll: one question, 3-5 options, plus "Other" or "Not sure". Options use glossary terms.
5. Mark every handoff with a cue line ("I'll pass to <role> for the demo"), and the screen-share owner at each point.
6. Plan Q&A: the moderator groups questions, reads them aloud, and uses the agreed parking phrase for anything that needs a written answer. Seed 2-3 questions in case the room is quiet.
7. Script the close: one CTA matching the follow-up email, the next webinar if it is a series, thanks, recording note.
8. Write the fallbacks: demo environment fails (switch to the backup demo recording), speaker drops (moderator covers, backup speaker joins), audio fails (chat message plus slide), platform fails (pre-agreed message and reschedule rule).
9. Add the post-show block: stop recording, download attendee, poll and Q&A exports into `<webinar folder>/webinar data/`, note any parked questions and who answers them by T+2.

## Output template

```
# Run-of-show: <title>
<Date>, <start>-<end> <time zone>   Platform: ...
Roles: Speaker ... | Moderator ... | Producer ... | Backup speaker ...
CTA: ...

| Clock | Min | Segment | Who speaks | On screen | Cue / action |
|-------|-----|---------|-----------|-----------|--------------|
| -0:30 | 30 | Pre-show checks | All | Holding slide | Practice mode on |
| 0:00 | 4 | Welcome | Moderator | Title slide | Start recording; script below |
| ... |

## Moderator opening script
## Polls
Poll 1 (at ~0:04): <question> / <options>
Poll 2 (at ~0:40): <question> / <options>
## Seed questions
## Fallbacks
## Day-of checklist (producer)
- [ ] ...
## Post-show
```

## Quality checks

- Minutes add up to the booked length, with Q&A protected.
- Time zone on every clock time.
- Poll wording and slide titles use `brand/glossary.md` terms; any figure read aloud is in `brand/claims-and-proof.md`.
- The CTA matches the follow-up email.
- Plain, speakable sentences in the scripts. No filler.
