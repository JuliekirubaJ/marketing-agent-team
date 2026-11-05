---
name: webinar-replay-package
description: "Plans and tracks the T+1 to T+3 post-webinar assets: replay and follow-up emails, recording upload, clips and snippets, recap posts, data consolidation and the companion page, each with an owner and a due date. Use right after a webinar ends, or when someone asks what is still owed for a past webinar."
---

# Webinar replay package

## When to use

- A webinar has just finished (T+0).
- Someone asks for the status of post-event deliverables.

## Inputs

Ask for: webinar title and date, recording location, length, speaker approval status, whether slides are shareable, the CTA for attendees and for no-shows, the next webinar in the series (if any).

Read: `config/team.md` (post-event deliverables, team roles, standard sequence), `config/paths.md` (webinar folder), `docs/webinar-companion-page-spec.md`, `docs/webinar-speaker-checklist.md` section 11, `brand/channels.md`.

## Steps

1. **T+0.** Confirm the recording saved. Download attendee, poll and Q&A exports into `<webinar folder>/webinar data/`. List parked questions with an owner for written answers.
2. **T+1 recording.** Video editor trims the start and end, adds the intro and outro, uploads to the replay page. Speaker approves within 24 hours. Save the transcript (host captions or the platform transcript) in the webinar folder.
3. **T+1 emails.** Two versions of the follow-up: attendees ("thanks, here is the recording and the top questions") and no-shows ("you missed it, here is the replay"). Different subject lines, the agreed CTA in each.
4. **T+1 posts.** Company recap post with the replay link; the speaker's personal recap (drafted for them). Use only channels listed in `brand/channels.md`.
5. **T+1 data.** webinar-data-consolidator merges the exports into the master report. Pass attendee, no-show and engaged lists to lifecycle-marketer.
6. **T+2 clips.** Run the `webinar-snippets` skill on the transcript; the video editor cuts the agreed 2-3 clips and the snippets. Written Q&A answers due. Sales debrief held.
7. **T+3 companion page.** Built from the transcript and the Q&A export per `docs/webinar-companion-page-spec.md`, saved as `companion-page.md` in the webinar folder, reviewed against `brand/` and published.
8. **T+3 nurture.** Attendee nurture email with a next-step CTA.
9. Shift every due date off non-working days. Flag anything blocked on an approval.

## Output template

```
# Replay package: <title> (<date>)
Recording: <saved / uploaded / approved>   Slides shareable: yes / no / redacted

| Due | Asset | Owner (role) | Depends on | Status |
|-----|-------|--------------|------------|--------|
| T+0 | Exports downloaded | Producer | - | |
| T+1 | Recording live | Video editor | Speaker approval | |
| T+1 | Follow-up email: attendees | Email | Recording link | |
| T+1 | Follow-up email: no-shows | Email | Recording link | |
| T+1 | Company recap post | Social | Recording link | |
| T+1 | Speaker recap post (draft) | Social | - | |
| T+1 | Master report updated | Data consolidator | Exports | |
| T+2 | Clips and snippets | Video editor | Transcript | |
| T+2 | Written answers to parked Q&A | Speaker | - | |
| T+3 | Companion page live | Content / Web | Transcript, Q&A | |
| T+3 | Attendee nurture email | Email | - | |

## Blockers
## Notes for the post-mortem
```

## Quality checks

- Attendee and no-show messages are different, not one email to both.
- No asker names in any public asset.
- Companion page takeaways come from what was said, not the abstract.
- Every claim and term checked against `brand/claims-and-proof.md` and `brand/glossary.md`.
- No channel used that `brand/channels.md` lists as not used.
