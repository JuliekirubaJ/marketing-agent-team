<#
.SYNOPSIS
  Converts a Markdown file to a styled Word .docx with no pandoc, Node, Python or LibreOffice:
  Markdown -> styled HTML -> Word COM (Documents.Open + SaveAs wdFormatXMLDocument).

.EXAMPLE
  .\md2docx.ps1 -MdPath campaigns\2026-01-15-launch\campaign-strategy.md -DocxPath campaigns\2026-01-15-launch\campaign-strategy.docx
  .\md2docx.ps1 -In notes.md -Out notes.docx -CssFile my-styles.css

.NOTES
  Supported: headings, paragraphs, tables, fenced code, ordered/unordered lists, blockquotes (rendered as
  amber callout boxes, handy for image placeholders), links, bold, italic, inline code, horizontal rules,
  and images: a line ![alt](url) plus an optional *caption* line on the next non-blank line. Remote images
  are downloaded to images\ next to the docx and embedded with the caption and an "Image source" line.
  WebP is converted to PNG; animated GIFs are embedded as their first frame (large GIFs stall Word).
  Prints paragraph/table/word/page counts and a SAVED line that is verified with Test-Path.
  See README.md for the traps (path length, file open in Word, SaveAs argument types).
#>
param(
    [Parameter(Mandatory=$true)][Alias('In')][string]$MdPath,
    [Parameter(Mandatory=$true)][Alias('Out')][string]$DocxPath,
    [string]$CssFile
)

$ErrorActionPreference = 'Stop'
$MdPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($MdPath)
$DocxPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DocxPath)
if (-not (Test-Path -LiteralPath $MdPath)) { throw "Markdown file not found: $MdPath" }
[System.IO.Directory]::CreateDirectory((Split-Path -Parent $DocxPath)) | Out-Null

# SaveAs fails if the target docx is open in Word: check for a lock before doing any work
if (Test-Path -LiteralPath $DocxPath) {
    try { $fs = [System.IO.File]::Open($DocxPath, 'Open', 'ReadWrite', 'None'); $fs.Close() }
    catch { throw "The target is open or locked (close it in Word first): $DocxPath" }
}
function Convert-Inline {
    param([string]$t)
    $t = $t -replace '&', '&amp;'
    $t = $t -replace '<', '&lt;'
    $t = $t -replace '>', '&gt;'
    # inline code
    $t = [regex]::Replace($t, '`([^`]+)`', '<code>$1</code>')
    # links
    $t = [regex]::Replace($t, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
    # bold
    $t = [regex]::Replace($t, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
    # italic
    $t = [regex]::Replace($t, '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>')
    return $t
}

$lines = Get-Content -LiteralPath $MdPath -Encoding UTF8
$html = New-Object System.Collections.Generic.List[string]

$i = 0
while ($i -lt $lines.Count) {
    $line = $lines[$i]

    # fenced code block
    if ($line -match '^```') {
        $i++
        $code = New-Object System.Collections.Generic.List[string]
        while ($i -lt $lines.Count -and $lines[$i] -notmatch '^```') {
            $c = $lines[$i] -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
            $code.Add($c)
            $i++
        }
        $i++
        $html.Add('<pre class="code">' + ($code -join "`r`n") + '</pre>')
        continue
    }

    # table
    if ($line -match '^\s*\|' -and ($i + 1) -lt $lines.Count -and $lines[$i+1] -match '^\s*\|[\s:\-\|]+\|\s*$') {
        $hdr = $line.Trim().Trim('|').Split('|')
        $html.Add('<table><thead><tr>')
        foreach ($h in $hdr) { $html.Add('<th>' + (Convert-Inline $h.Trim()) + '</th>') }
        $html.Add('</tr></thead><tbody>')
        $i += 2
        while ($i -lt $lines.Count -and $lines[$i] -match '^\s*\|') {
            $cells = $lines[$i].Trim().Trim('|').Split('|')
            $html.Add('<tr>')
            foreach ($c in $cells) { $html.Add('<td>' + (Convert-Inline $c.Trim()) + '</td>') }
            $html.Add('</tr>')
            $i++
        }
        $html.Add('</tbody></table>')
        continue
    }

    # blockquote -> callout box
    if ($line -match '^>') {
        $qs = New-Object System.Collections.Generic.List[string]
        while ($i -lt $lines.Count -and $lines[$i] -match '^>') {
            $qs.Add(($lines[$i] -replace '^>\s?', ''))
            $i++
        }
        $html.Add('<div class="callout">')
        $buf = New-Object System.Collections.Generic.List[string]
        foreach ($q in $qs) {
            if ([string]::IsNullOrWhiteSpace($q)) {
                if ($buf.Count -gt 0) { $html.Add('<p class="co">' + (Convert-Inline ($buf -join ' ')) + '</p>'); $buf.Clear() }
            } else { $buf.Add($q) }
        }
        if ($buf.Count -gt 0) { $html.Add('<p class="co">' + (Convert-Inline ($buf -join ' ')) + '</p>') }
        $html.Add('</div>')
        continue
    }

    # image: ![alt](url), optionally followed by an *italic caption* line.
    # Remote images are downloaded next to the docx (images\), webp is converted to png,
    # and the picture is embedded with its caption and source URL underneath.
    if ($line -match '^\s*!\[([^\]]*)\]\(([^)\s]+)\)\s*$') {
        $alt = $Matches[1]; $src = $Matches[2]
        $i++
        while ($i -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$i])) { $i++ }
        $cap = $null
        if ($i -lt $lines.Count -and $lines[$i] -match '^\s*\*([^*].*[^*])\*\s*$') { $cap = $Matches[1]; $i++ }
        $local = $src
        if ($src -match '^https?://') {
            $imgDir = Join-Path (Split-Path -Parent $DocxPath) 'images'
            [System.IO.Directory]::CreateDirectory($imgDir) | Out-Null
            $local = Join-Path $imgDir ([System.IO.Path]::GetFileName(([uri]$src).AbsolutePath))
            if (-not (Test-Path -LiteralPath $local)) {
                (New-Object System.Net.WebClient).DownloadFile($src, $local)
            }
        }
        if ($local -match '\.webp$') {
            Add-Type -AssemblyName PresentationCore
            $png = [System.IO.Path]::ChangeExtension($local, '.png')
            if (-not (Test-Path -LiteralPath $png)) {
                $fs = [System.IO.File]::OpenRead($local)
                try {
                    $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create($fs, 'PreservePixelFormat', 'OnLoad')
                    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
                    $enc.Frames.Add($dec.Frames[0])
                    $out = [System.IO.File]::Create($png); try { $enc.Save($out) } finally { $out.Close() }
                } finally { $fs.Close() }
            }
            $local = $png
        }
        # Animated GIFs can be tens of MB and stall Word: embed the first frame as a PNG instead.
        if ($local -match '\.gif$') {
            Add-Type -AssemblyName System.Drawing
            $png = [System.IO.Path]::ChangeExtension($local, '.png')
            if (-not (Test-Path -LiteralPath $png)) {
                $gif = [System.Drawing.Image]::FromFile($local)
                try { $gif.Save($png, [System.Drawing.Imaging.ImageFormat]::Png) } finally { $gif.Dispose() }
            }
            $local = $png
        }
        $w = 600
        try {
            Add-Type -AssemblyName System.Drawing
            $bmp = [System.Drawing.Image]::FromFile($local); $w = [math]::Min(600, $bmp.Width); $bmp.Dispose()
        } catch {}
        $altEsc = $alt -replace '&','&amp;' -replace '"','&quot;' -replace '<','&lt;'
        $html.Add('<p class="img"><img src="file:///' + ($local -replace '\\','/') + '" width="' + $w + '" alt="' + $altEsc + '" /></p>')
        if ($cap) { $html.Add('<p class="cap">' + (Convert-Inline $cap) + '</p>') }
        if ($src -match '^https?://') { $html.Add('<p class="isrc">Image source: <a href="' + $src + '">' + $src + '</a></p>') }
        continue
    }

    # headings
    if ($line -match '^(#{1,6})\s+(.*)$') {
        $lvl = $Matches[1].Length
        $html.Add("<h$lvl>" + (Convert-Inline $Matches[2].Trim()) + "</h$lvl>")
        $i++
        continue
    }

    # horizontal rule
    if ($line -match '^\s*---+\s*$') {
        $html.Add('<hr />')
        $i++
        continue
    }

    # ordered list
    if ($line -match '^\s*\d+\.\s+') {
        $html.Add('<ol>')
        while ($i -lt $lines.Count -and $lines[$i] -match '^\s*\d+\.\s+(.*)$') {
            $html.Add('<li>' + (Convert-Inline $Matches[1]) + '</li>')
            $i++
        }
        $html.Add('</ol>')
        continue
    }

    # unordered list
    if ($line -match '^\s*[-*]\s+') {
        $html.Add('<ul>')
        while ($i -lt $lines.Count -and $lines[$i] -match '^\s*[-*]\s+(.*)$') {
            $html.Add('<li>' + (Convert-Inline $Matches[1]) + '</li>')
            $i++
        }
        $html.Add('</ul>')
        continue
    }

    # blank
    if ([string]::IsNullOrWhiteSpace($line)) { $i++; continue }

    # paragraph
    $para = New-Object System.Collections.Generic.List[string]
    while ($i -lt $lines.Count -and -not [string]::IsNullOrWhiteSpace($lines[$i]) `
           -and $lines[$i] -notmatch '^(#{1,6}\s|>|\s*\||```|\s*---+\s*$|\s*\d+\.\s|\s*[-*]\s)') {
        $para.Add($lines[$i].Trim())
        $i++
    }
    if ($para.Count -gt 0) { $html.Add('<p>' + (Convert-Inline ($para -join ' ')) + '</p>') }
}

$css = @"
<style>
body { font-family: Calibri, sans-serif; font-size: 11pt; color: #1a1a1a; line-height: 1.45; }
h1 { font-family: Calibri, sans-serif; font-size: 22pt; color: #0b3d5c; margin: 18pt 0 10pt 0; }
h2 { font-family: Calibri, sans-serif; font-size: 16pt; color: #0b3d5c; margin: 16pt 0 6pt 0; border-bottom: 1px solid #cfd8dc; padding-bottom: 3pt; }
h3 { font-family: Calibri, sans-serif; font-size: 13pt; color: #17627f; margin: 12pt 0 4pt 0; }
h4 { font-size: 11.5pt; color: #17627f; margin: 10pt 0 4pt 0; }
p { margin: 0 0 8pt 0; }
table { border-collapse: collapse; width: 100%; margin: 8pt 0 12pt 0; font-size: 10pt; }
th { background: #0b3d5c; color: #ffffff; text-align: left; padding: 5pt 7pt; border: 1px solid #0b3d5c; }
td { padding: 5pt 7pt; border: 1px solid #cfd8dc; vertical-align: top; }
pre.code { background: #f4f6f7; border-left: 3px solid #17627f; padding: 8pt 10pt; font-family: Consolas, monospace; font-size: 9.5pt; margin: 8pt 0 12pt 0; }
code { font-family: Consolas, monospace; font-size: 9.5pt; background: #f4f6f7; }
div.callout { background: #fff6e0; border: 1px solid #e8b84b; border-left: 4px solid #e8b84b; padding: 8pt 10pt; margin: 10pt 0 12pt 0; }
p.co { margin: 0 0 5pt 0; font-size: 10pt; }
hr { border: none; border-top: 1px solid #cfd8dc; margin: 14pt 0; }
ul, ol { margin: 0 0 10pt 0; }
li { margin-bottom: 4pt; }
p.img { text-align: center; margin: 12pt 0 4pt 0; }
p.cap { text-align: center; font-style: italic; font-size: 10pt; color: #455a64; margin: 0 0 2pt 0; }
p.isrc { text-align: center; font-size: 8.5pt; color: #78909c; margin: 0 0 14pt 0; }
</style>
"@

# $CssFile, not $Css: PowerShell variable names are case-insensitive and $css holds the default styles
if ($CssFile) { $css = '<style>' + [System.IO.File]::ReadAllText(($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CssFile))) + '</style>' }

$doc = '<html><head><meta charset="utf-8" />' + $css + '</head><body>' + ($html -join "`r`n") + '</body></html>'

$tmpHtml = [System.IO.Path]::ChangeExtension($DocxPath, '.tmp.html')
[System.IO.File]::WriteAllText($tmpHtml, $doc, (New-Object System.Text.UTF8Encoding($true)))

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $d = $word.Documents.Open([string]$tmpHtml, $false, $false)
    # Word opens HTML images as links to the files; store them inside the docx instead.
    foreach ($shp in @($d.InlineShapes)) {
        if ($shp.LinkFormat) { $shp.LinkFormat.SavePictureWithDocument = $true; $shp.LinkFormat.BreakLink() }
    }
    $d.SaveAs([ref]([string]$DocxPath), [ref]([int]16))
    $stats = @{
        Paragraphs = $d.Paragraphs.Count
        Tables     = $d.Tables.Count
        Words      = $d.ComputeStatistics(0)
        Pages      = $d.ComputeStatistics(2)
    }
    $d.Close([ref]$false)
    $stats.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Output ("  {0}: {1}" -f $_.Key, $_.Value) }
} finally {
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    Remove-Item -LiteralPath $tmpHtml -Force -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath $DocxPath) {
    $kb = [math]::Round((Get-Item -LiteralPath $DocxPath).Length / 1KB, 1)
    Write-Output ("SAVED: {0} ({1} KB)" -f $DocxPath, $kb)
} else {
    Write-Output ("FAILED: {0} was not created" -f $DocxPath)
    exit 1
}
