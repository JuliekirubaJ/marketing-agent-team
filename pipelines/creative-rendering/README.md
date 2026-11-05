# Creative rendering pipeline

Static social creatives (single images, LinkedIn document carousels, series of reference cards) are written as HTML/CSS and exported with **headless Microsoft Edge**. No Node, Python or design app is needed. For the full workflow and design rules, see `docs/creative-rendering.md`.

| File | What it does |
|---|---|
| `render.ps1` | HTML to PNG (1x/2x) for one page or for each `#sN` slide of a page, plus an optional PDF |
| `png2pdf.ps1` | Builds a full-bleed PDF, one image per page, from PNGs through PowerPoint COM (carousel PDFs) |
| `batch-generate.ps1` | One row per creative in a briefs CSV, filled into an HTML template, then rendered to PNG/PDF. Optional combined PDF. |
| `templates/_shared.css` | Neutral base styles. Brand colours and fonts are CSS variables in `:root`. |
| `templates/example-creative.html` | 3-slide 4:5 carousel template with `{{column}}` placeholders |
| `templates/example-briefs.csv` | Two example briefs for the template |

## Quick start

```powershell
cd pipelines\creative-rendering

# one page, one PNG at 2x
.\render.ps1 -Html ..\..\creatives\launch\post.html -Width 1200 -Height 627

# a 3-slide carousel: 1x and 2x PNGs of each slide, plus a PDF of all slides
.\render.ps1 -Html carousel.html -Ids s1,s2,s3 -Scale 1,2 -Out png -Pdf carousel.pdf

# carousel PDF from existing PNGs (PowerPoint COM, full bleed)
.\png2pdf.ps1 -In png -Filter 'carousel-s*@2x.png' -Out carousel.pdf

# a whole series from a CSV
.\batch-generate.ps1 -Briefs templates\example-briefs.csv -Template templates\example-creative.html -Png -Pdf -Combined
```

`batch-generate.ps1` writes to `-Out`. The default is `<root>\creatives\<briefs file name>\`, where `<root>` is `-Root`, then `$env:MARKETING_ROOT`, then the repo root.

## Template contract

- One `<section class="slide" id="sN">` per slide. `page.html#s2` shows only slide 2 (for screenshots). With no fragment, every slide shows, one per printed page (for PDF).
- `{{column}}` is filled with the HTML-escaped CSV value, and `{{{column}}}` with the raw value. A placeholder with no matching column is left empty and reported.
- An empty `src` hides the image slot (`.logo`, `.hero-img`), so optional images need no template change.
- Brand colours go in the `:root` variables of `_shared.css`. Take the values from your brand guidelines (see `brand/voice-and-tone.md`), not from memory.
- Keep a copy of every logo and image a creative uses in its own `assets/` folder. Relative `<img src="assets/x.svg">` works from a `file://` page.

## Traps (each one failed silently once)

- **The `file:///` URL must be built from a full Windows path with forward slashes (`file:///C:/...`).** An MSYS path like `/c/...` (for example from `$PWD` in a Bash shell) renders a blank error page that still saves as a plausible PNG. The tell is that two different slides export to byte-identical sizes. `render.ps1` builds the URL itself and warns on identical sizes.
- **Edge can keep running after the screenshot is written,** so a loop over many renders can exceed a shell timeout even though every file landed. Check for the output files before assuming failure. `render.ps1` waits for the file, not the process.
- **`--virtual-time-budget`** (default 4000 ms) gives web fonts, images and layout scripts time to settle. Raise it if late-loading content is missing.
- **`--force-device-scale-factor=2`** gives the retina export. `=1` gives the nominal size.
- **Mobile check.** LinkedIn shows a feed image about 500 px wide on a phone. Look at every creative at that width before it ships: text under about 28 px at 1080 wide is unreadable.
- **Remote images** go through `-ImageColumns` in `batch-generate.ps1`. They are downloaded once, and a response under 2 KB is treated as an error page. A browser user agent is sent because some CDNs reject the default one.
- **Third-party marks** (platform or partner logos) are often missing from a logo library but present inside an official slide template. Unzip the `.pptx` and look in `ppt/media/`. A quick way to identify the files is an HTML contact sheet of `ppt/media/*` rendered with `render.ps1`.
- **PowerPoint COM** (`png2pdf.ps1`) quits PowerPoint only when no other presentation is open, so it does not close the user's work.
