# Creative rendering guide

How static social creatives are made: single images, LinkedIn document carousels and content-series reference cards. The scripts are in `pipelines/creative-rendering/` (see its README for usage and traps).

## Why HTML and headless Edge

Creatives are authored as HTML/CSS and exported with headless Microsoft Edge. Nothing else needs to be installed: no Node, Python or design app. HTML gives exact typography, CSS variables for brand colours, a reusable template for a whole series, and text that is easy to correct and re-render in seconds.

## Folder layout

Each creative lives in `creatives/<slug>/` (see `config/paths.md`):

```
creatives/<slug>/
  <slug>.html        source (one <section class="slide" id="sN"> per slide)
  _shared.css        copied from pipelines/creative-rendering/templates/, brand variables set
  assets/            a copy of every logo and image used (not links into a shared library)
  png/               1x and 2x PNG exports
  <name>.pdf         carousel PDF, when the format needs one
```

Logos come from the logo library (`assets/logos/` in `config/paths.md`): `Dark/` for light backgrounds, `Light/` for dark ones. Copy them into the creative's `assets/`, so the folder renders the same next year.

## Sizes

| Format | Size (px) | Notes |
|---|---|---|
| LinkedIn single image | 1200x627 or 1080x1080 | Square takes more feed space on mobile |
| LinkedIn document carousel | 1080x1350 (4:5) | Export PNGs, then build a PDF (`png2pdf.ps1` or `render.ps1 -Pdf`) |
| Vertical story / Shorts cover | 1080x1920 | Keep text out of the top and bottom 250 px |
| Webinar banner | per the landing page template | Check the CMS crop before designing |

Render at 2x (`-Scale 2`) for upload, and at 1x to check sizes.

## Workflow

1. **Brief.** Get the copy from the requester or the content agent. Every number and claim must match `brand/claims-and-proof.md`, and every term must match `brand/glossary.md`.
2. **Build** from `templates/example-creative.html` and `_shared.css`. Set the brand variables in `:root` once.
3. **Render** with `render.ps1`. For a series, put one row per creative in a CSV and run `batch-generate.ps1`.
4. **Check:**
   - Look at every PNG. Two slides with byte-identical sizes almost always means a blank render (see the README).
   - Mobile check: view the image at about 500 px wide, which is how LinkedIn shows it in a phone feed. Text under about 28 px at 1080 wide is unreadable there.
   - Brand check: `brand-voice-guardian` or `copy-editor` reviews the copy before it ships.
5. **Deliver** the 2x PNGs (and the PDF for carousels), plus the HTML source so edits are quick.

## Series creatives (batch)

For a recurring series (a chart of the week, a tip series, a feature series), keep the briefs in one CSV with one row per item and one column per slot in the template. `batch-generate.ps1` fills the template, downloads remote images into each creative's `assets/`, renders PNGs and PDFs, and can build one combined PDF for review. Fix copy in the CSV and re-run, rather than editing generated HTML.

Rules learned from running a series:
- **Use real product images, not mock-ups,** for anything that shows the product. A reader who later sees the real thing should recognise it.
- **Keep comparisons out of reference creatives** unless the comparison has been approved in `brand/competitors.md`.
- **Keep the colour semantics consistent** across the series: one colour for good or positive variance, one for bad or negative, used the same way on every card.

## Platform and partner marks

A logo library often lacks the platform or partner marks you need (the platform your product runs on, data-source logos). Official versions are usually inside the partner's or your own master slide template. A `.pptx` is a zip: extract it and look in `ppt/media/`. To identify the files quickly, build a small HTML contact sheet of `ppt/media/*` and render it with `render.ps1`. Record which file is which in the creative's README so nobody repeats the search. Follow the partner's logo usage rules.

## Animated creatives

For anything that moves (an animated LinkedIn post, a GIF-like loop, a product explainer), use `pipelines/video-production/` instead. PowerPoint COM renders MP4. It cannot write animated GIFs (see `docs/video-production.md`).
