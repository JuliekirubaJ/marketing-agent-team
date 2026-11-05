# Video production guide

How videos are made: post-webinar recordings, clips and snippets, and motion-graphics product explainers. The scripts are in `pipelines/video-production/`, and every PowerShell and COM trap is listed in its README. The look is defined in `docs/motion-graphics-style.md`.

## Webinar video deliverables

Every webinar produces three video deliverables. Log each one as a row in the task tracker's videos tab, through `pipelines/task-tracker/task-tracker.ps1`.

| Deliverable | Due | Notes |
|---|---|---|
| **Webinar recording** (edited) | T+1 (next working day) | A Friday webinar rolls T+1 to Monday. The follow-up email ships with it. |
| **Summary clip** | T+1 or T+2, target T+2 | One highlight clip, podcast style (`build-best-clip.ps1`) |
| **Webinar snippets** | Live by T+2 (they take two days) | 3-5 vertical shorts (`webinar-snippets` skill, then `build-snippets.ps1`) |

When there is more than one video editor (`config/team.md`), alternate them. Per webinar, one editor takes the recording and summary clip and the other takes the snippets. Swap on the next webinar.

The companion page (`docs/webinar-companion-page-spec.md`) follows at T+3 and reuses the same transcript.

## Choosing what to cut

1. Run the `webinar-snippets` skill on the transcript and abstract. It returns standalone, product-oriented moments with exact start and end words, verbatim transcript, cut notes and a common outro.
2. Pick 3-5. Prefer moments that show the product solving a problem, and check that each clip makes sense to someone who never saw the webinar.
3. **Snap every cut to a pause.** Cue-level transcript timestamps are not word-level. Find the silence near each boundary with an audio RMS scan (see "QA" below) so no cut lands mid-word.
4. Flag anything that should not be clipped: roadmap statements, unsourced numbers, customer data on screen, demo errors.

## Footage edits (snippets and summary clips)

- **Sources.** Use the platform's separate tracks when they exist. For Zoom: `_avo_` is camera only and carries the audio, `_as_` is screen share only, and the plain file is share plus speaker thumbnail.
- **Shorts format.** 1080x1920 at 30 fps, from a 540x960 pt slide. Keep content inside the safe area, x 40-500 / y 60-740 pt.
- **Structure.** One slide per continuous run of speech. Jump cuts sit between slides. A slight camera punch-in (zoom 1.1-1.15) on alternate runs hides a jump cut.
- **Captions.** The verbatim speaker words, 2-3 words per caption chunk (4 if the fourth closes a clause), breaking on punctuation and pauses, with the active word highlighted. Don't tidy the wording.
- **Outro.** Webinar title, a static "Watch the full webinar" CTA and the replay link. No sound on the end card.

## Motion-graphics explainers

Product explainers are animations over **real screenshots**. Every number on screen comes from the screenshot. Overlays only:
- **mask and reveal**: a solid shape covers a chart or result, then wipes away so the chart appears to draw itself;
- **highlight**: a glowing rounded box around a region;
- **magnify**: a cropped, enlarged copy of a region (a lens);
- **move controls into their real final position**: a slider knob or a dragged field travels along a motion path to where the screenshot shows it.

Never animate a number that is not in the source image, and never use a generative-video tool for product footage: it invents figures.

**Voiceover.** Record or generate the voiceover first. Measure each line's start from the pauses in the audio, then set each scene's length (0.5 s fade plus slide time) so the scene appears about 0.1 s before its line. Put the scene lengths in `$VX.SceneLen`. `Complete-Slide` stretches each slide to its slot and warns when the animations overrun.

**Sound effects.** Use a click for every UI beat (pops, checkmarks, cards landing). Keep whooshes few and quiet: at most one per scene change, at PowerPoint volume around 0.35, and none inside scenes. No sound on the end card. A soft "pop" reads as odd, so prefer a click. Free libraries (for example Pixabay) work. Note the licence in the video's folder.

**Delivery.** The default is a YouTube Shorts cut (1080x1920). Make a 1920x1080 version only when the channel needs it. The end-card CTA is static (no pop-in) and must not promise anything the offer doesn't include (for example, don't say "free" unless the offer is free).

## QA

1. **Layout:** the build scripts export end-state stills with the reveal masks hidden (`_qa/` or `assets/`). Check alignment, text overflow and the safe area.
2. **Timing:** `build-best-clip.ps1` writes `caption-timing.txt` (source time, output time and text of each caption). Spot-check it against the audio.
3. **Frames:** `qa-frames.ps1 -Video out.mp4 -Times ...` exports stills from the rendered MP4. Use these for review, not the static slide exports.
4. **Motion and audio:** serve the folder with a small local web server that supports Range requests. Use a canvas page to grab frames and an `OfflineAudioContext` RMS page to check levels and pauses. The same RMS scan produces the 50 ms envelope that `build-best-clip.ps1` uses for word timing. Stop the server before re-rendering, because `CreateVideo` cannot overwrite an MP4 that is held open.
5. **Content:** the copy and any on-screen claims pass `brand-voice-guardian` or `copy-editor`.

## Rendering facts

- `CreateVideo(path, $true, <default slide sec>, <vertical px>, 30, 90)`: 1080 for landscape, 1920 for Shorts.
- A 90 s 1080p explainer renders in about 25 s, and a 35 s Shorts clip with linked footage in about 12 s.
- MP4 only. For a GIF, export it from PowerPoint's own UI.
