# Motion-graphics style

The default look for every edited video: webinar snippets, summary clips and product explainers. It is a light, modern B2B SaaS editing style, with floating UI cards, kinetic type and camera moves over real product UI. Colours and fonts come from the brand (`brand/voice-and-tone.md` or your brand guidelines). Everything else here stays the same across brands.

Implementation: `pipelines/video-production/ppt-video-helpers.ps1` (PowerPoint COM). Workflow: `docs/video-production.md`.

## Canvas

- Light, airy background: off-white or a very pale tint of the brand colour, usually a soft two-colour gradient. Leave lots of empty space.
- An occasional warm gradient (cream to peach, or a pale brand tint) for variety between scenes.
- Dark-ink text (near-black navy), never pure black.
- End cards can flip to a solid brand-colour gradient with white text.

## Floating UI cards

- White rounded cards (corner radius about 6-14% of the short side) with a soft, low-opacity shadow tinted with the brand colour.
- Pills for chips, tags and buttons: fully rounded, either white or the brand colour.
- Gradient cards with a small bar chart and KPI chips, for example a green "+x%" badge.
- Screenshots sit inside a framed card, never edge to edge.

## Kinetic typography

- A bold geometric sans (Segoe UI Black or Bold on Windows; an Inter-like face if the brand has one).
- Headlines enter word by word or line by line, fading in while drifting up into place (`Rise`).
- A highlighter-box sweep behind the key phrase, wiping in from the left in a pale brand tint.
- An animated cursor and checkbox ticks for "done" beats.
- Captions on footage: 2-3 words at a time, with the active word in the brand colour on a tinted chip.

## Camera and UI moves

- Push-ins and zooms to a detail (a chart tooltip, a KPI): use `Lens` for a magnified callout, or a slight crop zoom on footage.
- Reveal masks that "draw" a chart (`Mask` plus a wipe), and glowing highlight boxes (`Box`).
- Controls that move into their real final positions (`Slide-Knob`).
- Device mockup reveals and light-to-dark mode swaps, when the product supports them.
- 3D tilt to flat is part of the reference style, but PowerPoint can't animate it well. Use a zoom or rise instead.

## Accent beats

- A full-frame solid-colour flash with one word.
- A circle wipe between scenes.
- A logo coin-flip (swivel, effect 19) on the end card.

## Motion and timing

- Smooth, eased motion (ease-in-out, slight deceleration). Nothing linear except progress bars.
- Fast cuts on the beat. Most entrances take 0.3-0.6 s, and holds are long enough to read: about 3 words per second of hold.
- One idea per scene.

## Sound

- A click for every UI beat (cards landing, ticks, selections).
- Whooshes are rare and quiet: at most one per scene change, at low volume, and never inside a scene.
- No sound on the end card. Music, if any, is upbeat and sits well under the voice.

## Format and safe areas

- Default delivery: YouTube Shorts / LinkedIn vertical, 1080x1920. Keep content inside x 40-500 / y 60-740 pt of a 540x960 slide.
- Landscape 1920x1080 for website, YouTube main channel and event screens.
- End card: logo, title, one static CTA and the URL. The CTA doesn't pop in and promises nothing the offer doesn't include.

## Content rules

- Every number on screen comes from the real screenshot or footage. Overlays reveal, highlight and move. They never alter figures.
- On-screen copy follows `brand/glossary.md` and `brand/voice-and-tone.md`: plain, short, no hype.
- Speaker words in captions stay verbatim.
