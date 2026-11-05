# Webinar companion page: spec

Every webinar gets a companion section on its replay page once the recording is up. The replay page lives on `<COMMUNITY_OR_WEBINAR_SITE>`. The section sits under the existing abstract and above Speakers. Chapters go on the video player, not on the page.

**Due:** T+3 working days. The recording goes up at T+1, and the transcript comes from that upload. This is part of the standard post-event deliverables in `config/team.md`.

**Output:** Markdown, `webinars/<YYYY-MM-DD>-<slug>/companion-page.md` (see `config/paths.md`). Deliver Markdown only unless a docx is requested.

## Sources

1. **Transcript.** Use the auto-captions of the uploaded recording (most video hosts expose them as text tracks), or the webinar platform's transcript file (for example Zoom's `.transcript.vtt`). Save a copy in the webinar folder.
2. **Q&A export** from the webinar platform (for Zoom, `qa_<id>_<date>.csv`). These are the FAQ questions.
3. **Brand files.** Check every claim and figure against `brand/claims-and-proof.md` and every term against `brand/glossary.md` before it goes on the page.

Never write the takeaways from the abstract or the agenda. Use what was actually said.

## Sections (keep it crisp)

| Section | Rules |
|---|---|
| **Modules** | One line naming which product modules or areas the webinar covers, primary first. Use only the module names listed in `brand/company.md`, and only list one that the session actually demonstrates or discusses in substance. A general or commercial session with no module focus says `General (all modules)`. |
| **In short** | One meta line: `Recorded <date> - <length> - <Part x of y if a series>`. Then 2-3 plain sentences on what the session covers. Do not name the speaker or write "<Speaker> explains...". State the content directly. |
| **Key takeaways** | 5-7 points. Bold lead-in, then one or two sentences. Each point is something said in the session, in plain words, with no hype. |
| **FAQ** | 4-6 real attendee questions, answered with what was said live and corrected against `brand/`. Never use the askers' names. Leave out questions that weren't answered live, or that got a "we'll follow up" reply. |
| **Resources** | The standing resources listed for companion pages in `brand/channels.md` (for example a pricing or capacity estimator, the forums), 1-3 related webinar replays, and docs where relevant. No presentation or deck link, because the page has a separate slot for it. |

## Guardrails

- **Numbers keep their caveats.** Any savings, pricing or performance figure goes on the page only in the wording and with the assumption that `brand/claims-and-proof.md` gives it.
- **No undated roadmap items** ("coming soon", "in the next few weeks"). For sessions held before a general-availability date, also leave out preview pricing, setup steps and roadmap items.
- **Correct the speaker's slips against `brand/`.** Speakers use deprecated terms, round numbers loosely and paraphrase award or partner wording. The page uses the canonical form. Keep a short list of the corrections you made at the bottom of the draft for the reviewer.
- **Glossary terms only.** See `brand/glossary.md`.
- **Plain B2B voice.** No AI-sounding phrasing. See `brand/voice-and-tone.md`.

## Why the page has its own content, not the abstract

- **The recording is gated.** Signed-out visitors and crawlers see only the page text.
- **Duplicate text.** A copied abstract duplicates the main website, so the replay page has nothing of its own to rank on.
- **The abstract is pre-event.** It is a promise. The takeaways say what was actually covered.
- **Real questions match searches.** FAQ blocks built from attendee questions are the queries prospects type into search engines and AI assistants.

## Template

```markdown
**Modules:** <Primary module>, <Secondary module>

## In short
Recorded <Mon D, YYYY> - <NN> min - <Part x of y>

<2-3 sentences on what the session covers.>

## Key takeaways
- **<Lead-in>.** <One or two sentences.>
- ...

## FAQ
**<Attendee question, lightly tidied>**
<Answer as given live, corrected against brand/.>

## Resources
- <Standing resource from brand/channels.md>
- <Related replay>
- <Docs page>

<!-- Reviewer notes: corrections made against brand/ -->
```
