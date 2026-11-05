# Working paths

All paths are relative to the marketing root: `$env:MARKETING_ROOT`, or this repo's folder when that variable is unset. Change them here; agents and scripts read this file or take the same values as parameters.

| What | Default path |
|---|---|
| Task tracker workbook | `trackers/Task Tracker Marketing.xlsx` |
| Social follower tracker | `trackers/Social Media Followers.xlsx` |
| Campaign packages | `campaigns/<YYYY-MM-DD>-<slug>/` (campaign-strategy.md + .docx) |
| Webinar folders | `webinars/<YYYY-MM-DD>-<slug>/` (master report xlsx, `webinar data/` raw exports) |
| Creatives | `creatives/<slug>/` (HTML source, `_shared.css`, `assets/`, 1x and 2x PNGs) |
| Videos | `videos/<slug>/` |
| SEO exports | `seo/_exports/<YYYY-MM>/<site-key>/` |
| SEO reports | `seo/reports/` |
| Deck template | `templates/<Master Deck>.pptx` |
| Brand guidelines document | `templates/<Brand Guidelines>.pdf` (palette, fonts; fallback when there is no deck template) |
| Webinar schedule | `<https://example.com/webinars>` (public upcoming-webinars page) |
| Logo library | `assets/logos/` (`Dark/` for light backgrounds, `Light/` for dark) |

Keep working data (`trackers/`, `campaigns/`, `webinars/`, `creatives/`, `videos/`, `seo/`) out of git. The `.gitignore` already excludes them.
