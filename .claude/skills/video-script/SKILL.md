---
name: video-script
description: "Writes a video script and storyboard for a product explainer, demo, short or promo: hook, scenes with voiceover, on-screen text, the real screenshot used and the overlay move for each scene, timing and end card, in the house motion-graphics style. Use when a video needs a script, a storyboard or a motion brief before it is built."
---

# Video script and storyboard

## When to use

- A product explainer, feature demo, short or webinar promo needs a script.
- A motion-graphics brief is needed before building with `pipelines/video-production/`.

For clips cut from a webinar recording, use `webinar-snippets` instead: those keep the speaker's words verbatim and need a cut list, not a script.

## Inputs

Ask for:
- Goal, audience, channel and format (1080x1920 Shorts by default; 1920x1080 for website or main channel).
- Target length (shorts 20-45 s; explainers 60-90 s).
- The feature or story, and the real screenshots or screen recordings available.
- The CTA and destination URL.

Read `docs/motion-graphics-style.md`, `docs/video-production.md`, `brand/glossary.md`, `brand/voice-and-tone.md`, `brand/positioning.md`, `brand/audiences.md` and `brand/claims-and-proof.md`.

## Steps

1. **One sentence** the viewer should remember. If you can't write it, the video isn't ready.
2. **Hook (first 2-3 s).** Name the viewer's problem or show the result. No logo intro, no "In this video".
3. **Scenes.** One idea per scene. For each: voiceover line, on-screen text (short, 3-7 words), the screenshot file, the overlay move (mask and reveal, highlight box, magnify lens, control moving to its real position, kinetic headline) and duration.
4. **Timing.** Voiceover at roughly 2.5 words per second. On-screen text held about one second per three words. Entrances 0.3-0.6 s.
5. **Numbers.** Any figure on screen must be visible in the real screenshot. Spoken claims must be in `brand/claims-and-proof.md`.
6. **Sound notes.** A click for each UI beat; at most one quiet whoosh per scene change; none on the end card.
7. **End card.** Logo, title, one static CTA and the URL. The CTA promises nothing the offer doesn't include.
8. **Read it aloud** against a timer and trim to length. Run the voiceover through `ai-prose-check`.

## Output template

```
## <Video title> - script v<n> (<date>)
Format: <1080x1920 | 1920x1080>   Length: <s>   Channel: ...   CTA: ... -> <URL>
Takeaway: <one sentence>

| # | Time | Voiceover | On-screen text | Visual (screenshot file) | Move / overlay | SFX |
|---|------|-----------|----------------|--------------------------|----------------|-----|
| 1 | 0-3 s | ... | ... | ... | Rise headline | click |
...
| End | ... | (none) | <title> / <CTA> / <URL> | end card | static | none |

Screens needed: <list of real screenshots to capture>
Claims to verify: <list>
Captions: <yes/no, burned-in for social>
```

## Quality checks

- Every on-screen number exists in a real screenshot; nothing generated.
- Glossary terms exact; spoken claims approved with caveats.
- Shorts content fits the safe area noted in `docs/motion-graphics-style.md`.
- Voiceover sounds like a person explaining to a colleague: plain, no hype.
