# Docs conversion pipeline

`md2docx.ps1` converts a Markdown file to a styled Word `.docx` on a machine with **no pandoc, Node, Python or LibreOffice**. It needs Microsoft Word, which it drives through COM. The route is Markdown, then styled HTML, then `Word.Application`, `Documents.Open(html)` and `SaveAs(path, 16)` (wdFormatXMLDocument).

```powershell
.\md2docx.ps1 -MdPath campaigns\2026-01-15-launch\campaign-strategy.md -DocxPath campaigns\2026-01-15-launch\campaign-strategy.docx
.\md2docx.ps1 -In notes.md -Out notes.docx -CssFile my-styles.css     # optional: replace the default styles
```

Campaign packages are delivered as both `.md` and `.docx` (see `config/paths.md`), unless the reader asked for Markdown only.

## What it supports

- Headings, paragraphs, horizontal rules, ordered and unordered lists
- Tables (pipe syntax with a separator row), with a dark header row
- Fenced code blocks and inline code
- Blockquotes, rendered as amber callout boxes. These work well as image placeholders in drafts.
- Links, bold, italic
- Images: a line `![alt](url)`, optionally followed by an `*italic caption*` line. Remote images are downloaded to `images\` next to the docx and embedded, with the caption and an "Image source: <url>" line underneath. WebP is converted to PNG. An animated GIF is embedded as its first frame, because a 35 MB GIF stalled Word.
- Word opens HTML images as links to files, so the script breaks each link and stores the picture inside the docx.

It prints paragraph, table, word and page counts, then a `SAVED:` line that is checked with `Test-Path`.

## Traps

- **`SaveAs` argument types.** `$doc.SaveAs([ref]$path, [ref]16)` can throw `Cannot convert the "..." value of type "psobject" to type "Object"` when `$path` came from `Join-Path`. Force the types: `$doc.SaveAs([ref]([string]$path), [ref]([int]16))`. In some call patterns this error does not stop the script, which can then print a false "Saved" line. Always confirm the output with `Test-Path`, as the script does.
- **The target docx is open in Word.** SaveAs fails. The script checks for a file lock first and stops with a clear message.
- **Paths over 260 characters.** Image downloads fail on long paths, such as a deep temp or session folder. Test in a short folder, for example `$env:TEMP\md`.
- **Verifying without a PDF renderer.** `ExportAsFixedFormat` to PDF works, but there may be no tool to turn the PDF into images. Check the structure over COM instead: `Tables.Count`, `Paragraphs.Count`, `Hyperlinks.Count`, `ComputeStatistics(2)` for pages, and each paragraph's `Style.NameLocal` to count headings.
- **Encoding.** The Markdown is read as UTF-8, and the intermediate HTML is written as UTF-8 with a BOM so Word reads non-ASCII text correctly.
- **Custom CSS.** The parameter is `-CssFile`, not `-Css`. PowerShell variable names are case-insensitive, and `$css` already holds the default styles.
