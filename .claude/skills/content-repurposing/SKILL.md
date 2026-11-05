---
name: content-repurposing
description: "Turns one source asset (webinar, blog post, whitepaper, customer story, community thread or demo) into a set of derivative pieces for the channels we use, each with its angle, format, owner and publish date. Use after a webinar or a big content piece ships, or when the calendar needs filling from existing material."
---

# Content repurposing

## When to use

- A webinar has ended and its recording and transcript are available.
- A blog post, guide, report or customer story has shipped and should work harder.
- A community thread or sales question deserves a wider audience.
- The content calendar has gaps.

## Inputs

Ask for:
- The source asset (file, transcript or URL) and its main audience.
- The goal of the repurposed set (registrations for the next event, traffic, sales enablement, community answers).
- Any pieces already made from it.

Read `brand/channels.md` (channels in use and channels we do not use), `brand/audiences.md`, `brand/glossary.md`, `brand/claims-and-proof.md`, `config/team.md` (cadence, editors) and, for webinars, `docs/video-production.md` and `docs/webinar-companion-page-spec.md`.

## Steps

1. **Mine the source.** List the distinct ideas: each claim, how-to, framework, example, stat, quote and audience question. Note the timestamp or section for each.
2. **Check each idea.** Numbers and product statements must be in `brand/claims-and-proof.md`. Roadmap remarks and unsourced figures are out. Quotes from customers or guests need permission.
3. **Match ideas to formats.** One idea per piece. Typical set from a webinar:
   - 3-5 short videos (via the `webinar-snippets` skill and video-producer)
   - 1 summary clip
   - 1 companion page or recap post (at T+3, per the companion page spec)
   - 2-4 LinkedIn posts (one insight each; one carousel if there is a framework)
   - 1 follow-up email and a nurture email
   - 1-2 community posts answering the questions asked live
   - FAQ entries or a blog post for questions that came up more than once
4. **Write the angle** for each piece in one line: who it is for and what they get. Avoid "in case you missed it" as the only angle.
5. **Sequence** over two to four weeks so the channels don't all fire on one day. Respect deliverable dates in `docs/video-production.md`.
6. **Assign** each piece to an owner agent and date.
7. **Link back.** Every piece points to the full source, with a tagged link (`utm-builder`).

## Output template

```
## Repurposing plan: <source> (<date>)
Goal: ...   Source: <file or URL>

### Idea bank
| # | Idea | Type (how-to / stat / quote / framework / question) | Location in source | Cleared? |

### Pieces
| Piece | Format | Channel | Idea # | Angle | Owner | Publish date | Link |

### Not used (and why)
```

## Quality checks

- Only channels listed in `brand/channels.md`.
- Every number traced to `brand/claims-and-proof.md`; speaker words quoted verbatim when quoted.
- Each piece stands alone for someone who never saw the source.
- Drafts pass `ai-prose-check` before review.
