# Video production pipeline

Motion-graphics videos and edited webinar clips built with **PowerPoint COM**: animations over real screenshots or real footage, rendered to MP4 with `Presentation.CreateVideo`. No ffmpeg, Node, Python or generative-video tool is needed.

Generative video invents numbers. Animating over the real screenshots keeps every figure exact. Overlays only mask, reveal, highlight, magnify and move controls into their real final positions.

For the workflow (deliverables, timelines, QA), see `docs/video-production.md`. For the look, see `docs/motion-graphics-style.md`.

| File | What it does |
|---|---|
| `ppt-video-helpers.ps1` | Dot-sourced helper library: `Fx`, `FxAt`, `Rise`, `Hold`, `Slide-Knob`, `Shot`, `P`, `Box`, `Mask`, `Lens`, `Sfx`, `Add-Voiceover`, `Add-LinkedVideo`, `Copy-MediaPool`, shape/text/card/pill/glyph helpers, `Export-QAStills`, `Export-Video` (CreateVideo wrapper) |
| `example-build-video.ps1` | 4-scene 1920x1080 explainer over a placeholder dashboard screenshot. Start here. |
| `build-snippets.ps1` | Cuts a recording into vertical 1080x1920 shorts from a CSV of start/end ms (jump cuts, caption pills, outro) |
| `build-best-clip.ps1` | Podcast-style vertical highlight clip: camera card, word-by-word captions, waveform progress, optional screen cut-in, replay end card |
| `qa-frames.ps1` | Still frames from an MP4 at given seconds, for review |

## Quick start

```powershell
cd pipelines\video-production
.\example-build-video.ps1 -NoVideo            # pptx + _qa\sceneN.png stills (seconds)
.\example-build-video.ps1                     # + MP4 (a 90 s 1080p video renders in about 25 s)

.\build-snippets.ps1 -Recording cam.mp4 -Screen share.mp4 -Cuts cuts.csv -Captions captions.csv -Logo logo.png
.\build-best-clip.ps1 -Recording cam.mp4 -Runs runs.csv -Phrases phrases.csv -Envelope envelope.txt -Logo logo.png
.\qa-frames.ps1 -Video ..\..\videos\best-clip\best-clip.mp4 -Times 4.6,26,44 -Vertical
```

Outputs go under `<root>\videos\...` by default. `<root>` is `-Root`, then `$env:MARKETING_ROOT`, then the repo root.

## Using the helpers

```powershell
. (Join-Path $PSScriptRoot 'ppt-video-helpers.ps1')
$pres = New-VideoDeck -Width 960 -Height 540 -Assets $assets -Palette @{ primary = '#4F46E5'; ink = '#16163A' }
$K = $VX.Palette
$s = New-VideoSlide $pres
$m = Shot $s 'dashboard.png'                         # framed screenshot; returns an image-px -> slide-pt mapper
$mk = Mask $s $m 60 250 830 660 $K.white             # cover the chart...
Fx $s $mk $WIPE $AFTER 1.4 0.3 -Exit -dir $DIR_DOWN | Out-Null   # ...and wipe the cover away to "draw" it
$b = Box $s $m 32 80 422 200; Fx $s $b $FADE $AFTER 0.4 0.2 | Out-Null
$l = Lens $s $m 32 80 422 200 300 380 1.4; Fx $s $l $FADEDZOOM $AFTER 0.5 0.2 | Out-Null
Complete-Slide $s 1.2
Export-QAStills $pres '_qa'
Export-Video $pres 'out.mp4' -Height 1080
Close-VideoDeck $pres
```

- **Slide sizes.** A 960x540 pt slide renders 1920x1080 with `-Height 1080`. A 540x960 pt slide renders 1080x1920 (Shorts) with `-Height 1920`. For Shorts, keep content inside the safe area x 40-500 / y 60-740 pt.
- **Two timing models.** In the sequential model, `Fx`, `Rise` and `Slide-Knob` take `$AFTER` or `$WITH`, and a running clock lets `Complete-Slide` size each slide. In the absolute model, `FxAt` places every effect "with previous" at a fixed second. Use it for footage, so captions stay locked to the source timeline.
- **Voiceover timing.** Set `$VX.SceneLen` to each scene's length (0.5 s fade plus slide time), measured from the pauses in the voiceover. `Complete-Slide` then stretches each slide to its voice slot, and warns when the animations run past it.
- **Effect ids that work:** 1 appear, 10 fade, 17 stretch, 19 swivel (logo coin-flip), 22 wipe, 23 zoom, 34 rise-up, 53 faded zoom, 83 media play.

## PowerShell and COM traps

Each of these cost a debugging session. Most fail silently.

**PowerShell**
- **Variable names are case-insensitive.** `$c` overwrites `$C`, a loop `$k` overwrites a palette `$K`, and a parameter `-Runs` is the same variable as `$RUNS`. Name the palette `$K` and never use `$k` as a loop counter in the same scope. The helpers keep their state in `$VX`, `$VxClock`, `$VxLastStart` and `$VxScene`, so don't reuse those names.
- **Built-in aliases win over functions** with the same name: `Move`, `R` and others. Use distinct helper names.
- **`Timing.Duration`, `Timing.TriggerDelayTime`, font sizes like 10.5, and most COM numbers need `[single]`.** Otherwise the call throws "Specified cast is not valid".
- **Non-ASCII in scripts.** PowerShell 5.1 misreads non-ASCII characters (arrows, middle dots, plus-minus) in a UTF-8 file with no BOM. Keep string literals ASCII and build symbols with `[char]0x2192` and similar. If a file must hold non-ASCII text, save it as UTF-8 with a BOM.

**Pictures and media**
- **Crop is measured against the native size.** For a picture, insert at native size (`AddPicture(..., -1, -1)`), crop, then resize (`Lens` does this). Inserted video is shrunk to fit the slide, so call `ScaleHeight(1,-1); ScaleWidth(1,-1)` before computing a crop (`Add-LinkedVideo` does this).
- **Read image sizes from the file. Never guess them.** `Get-ImageSize` reads WebP sizes from the header, because System.Drawing cannot open WebP.
- **Two playing instances of the same media file on one slide fail silently.** The second shows nothing useful. Give each overlapping clip its own copy (`Copy-MediaPool -copies N`).
- **Files in cloud-synced folders.** PowerPoint intermittently fails to reopen synced media, and sync locks can block log writes. Work on local copies in `%TEMP%` (`Copy-MediaPool`), and log to `%TEMP%`. `AddMediaObject2` is retried 4 times.
- **A clip whose `EndPoint` runs past the slide's `AdvanceTime` stretches the slide,** and everything after it drifts. End every clip exactly at its run length. Each media start also adds about 0.1-0.4 s, but audio and captions on that slide stay in sync with each other.
- **Linked footage:** `AddMediaObject2(file, -1, 0, l, t, -1, -1)` links the file. Trim with `MediaFormat.StartPoint` and `EndPoint` (milliseconds), and start playback with effect 83 "with previous".
- **Zoom cloud recordings** come as separate files. `_avo_` is camera only and carries the audio. `_as_` is screen share only, so mute it. The plain file is share plus speaker thumbnail.

**Animation**
- **`AnimationSettings` rewrites a slide's effects.** Touching `AnimationSettings` on a slide that already has effects turns them all into sequential 0.5 s "Appear" steps. That once stretched slide 1 by 7 s. Add the voiceover (`Add-Voiceover`) before any other effect on that slide. Never use `AnimationSettings` for sound effects.
- **Sound effects** (`Sfx`): add the media off-slide (Left beyond the slide width, so no icon shows), set `StartPoint`, `EndPoint` and `Volume`, then add effect 83 "with previous" straight after the visual effect, with the same `TriggerDelayTime`.
- **Voiceover offset.** In the export, the audio starts about 0.56 s after its slide starts, by the same amount on every slide. Time each slide to the voice's line starts.
- **Rise-up (34) travels far,** so it does not suit per-word text. Per-word captions use one textbox per word state, shown and hidden with Appear (1).

**Rendering and output**
- **`CreateVideo` writes MP4 only.** A `.gif` file name still produces an MP4, and `SaveAs(..., 40)` writes nothing. Deliver the MP4. If a GIF is needed, export it from PowerPoint's own File > Export > Create an Animated GIF.
- **`CreateVideo` returns E_FAIL if the old MP4 is still open,** for example held by a player or a QA web server. Stop that first. `Export-Video` deletes the old file and says so if it can't.
- **Poll `CreateVideoStatus`:** 1 = in progress, 2 = queued, 3 = done, 4 = failed.
- **A static `Slide.Export` shows the reveal masks and every caption state at once.** `Export-QAStills` hides `MASK_*` shapes. Use the stills for layout checks only, and take review stills from the MP4 with `qa-frames.ps1`.

## QA without ffmpeg

- **Layout:** `Export-QAStills` (end state, masks hidden).
- **Frames:** `qa-frames.ps1`, which sets the poster frame of an embedded copy of the MP4 and exports the slide.
- **Motion and audio in a browser:** serve the folder with a small PowerShell `HttpListener` that supports Range requests. Then (1) a page that draws video frames to a canvas and counts pixels by colour, and (2) a page that runs an `OfflineAudioContext` RMS scan, which finds speech pauses so cuts don't land mid-word and produces the 50 ms envelope that `build-best-clip.ps1` uses. Some embedded browser panes show MP4 frames as black, and their timers stall when the pane is hidden. Check by drawing to a canvas, not by eye. Stop the listener before re-rendering.
- **Sound levels:** render a test with sound effects only (no voiceover) and scan its envelope. A whoosh at PowerPoint volume 0.35-0.55 sits just under a voiceover.
