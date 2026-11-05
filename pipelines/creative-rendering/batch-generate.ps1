<#
.SYNOPSIS
  Batch creative generator: one row per creative in a CSV of briefs -> HTML from a template -> PNG and/or PDF.
  Use it for a content series (for example a "chart of the week" set of 3-slide carousels).

.EXAMPLE
  .\batch-generate.ps1 -Briefs templates\example-briefs.csv -Template templates\example-creative.html -Png -Pdf
  .\batch-generate.ps1 -Briefs briefs.csv -Template series.html -Only 3,7 -Png -Slides s1,s2,s3
  .\batch-generate.ps1 -Briefs briefs.csv -Template series.html -Combined -SkipDownload

.NOTES
  CSV
    - Needs an `id` column (number or short code). A `slug` column names the output folder; otherwise the
      folder is <id>-<slug of title>. Every other column is free-form.
  Template
    - {{column}} is replaced with the HTML-escaped value; {{{column}}} with the raw value (for markup).
    - Unknown placeholders are left empty and reported once.
    - A <base href> pointing at the template folder is injected, so the template's relative links
      (_shared.css, assets/...) keep working from the output folder.
  Images
    - -ImageColumns names columns that hold image URLs. Each is downloaded to <out>\<folder>\assets\ and the
      placeholder gets the local file URL. Downloads under 2 KB are treated as failures (error pages), and the
      placeholder is left empty so the template can hide the slot. -SkipDownload reuses files already there.
  Output
    - <Out>\<folder>\<folder>.html, plus slide PNGs (-Png, via render.ps1) and a PDF (-Pdf, Edge print).
    - -Combined also writes <Out>\all-creatives.html and .pdf with every creative in one file.
#>
param(
  [Parameter(Mandatory = $true)][string]$Briefs,
  [Parameter(Mandatory = $true)][string]$Template,
  [string]$Root,
  [string]$Out,
  [string[]]$Only,
  [string[]]$Slides = @('s1', 's2', 's3'),
  [string[]]$ImageColumns = @(),
  [int]$Width = 1080,
  [int]$Height = 1350,
  [int[]]$Scale = @(2),
  [switch]$Png,
  [switch]$Pdf,
  [switch]$Combined,
  [switch]$SkipDownload,
  [string]$PdfSuffix = ''
)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = $(if ($env:MARKETING_ROOT) { $env:MARKETING_ROOT } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }) }
function Get-FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }
$briefsFull = Get-FullPath $Briefs
$templateFull = Get-FullPath $Template
if (-not $Out) { $Out = Join-Path $Root ('creatives\' + [IO.Path]::GetFileNameWithoutExtension($briefsFull)) }
$outFull = Get-FullPath $Out
New-Item -ItemType Directory -Force -Path $outFull | Out-Null
$render = Join-Path $PSScriptRoot 'render.ps1'
$utf8 = New-Object Text.UTF8Encoding $false

function Slug([string]$s) { $x = ($s.ToLower() -replace '[^a-z0-9]+', '-').Trim('-'); if ($x.Length -gt 48) { $x = $x.Substring(0, 48).Trim('-') }; $x }
function HtmlEsc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }
function FileUrl([string]$p) { ([Uri]$p).AbsoluteUri }

function Get-Img([string]$url, [string]$dest) {
  if (-not $url) { return $null }
  if ($SkipDownload -and (Test-Path -LiteralPath $dest)) { return $dest }
  if ($url -notmatch '^https?://') {
    $local = $(if ([IO.Path]::IsPathRooted($url)) { $url } else { Join-Path (Split-Path -Parent $templateFull) $url })
    if (Test-Path -LiteralPath $local) { return $local } else { return $null }
  }
  try {
    Invoke-WebRequest ($url -replace '&amp;', '&') -OutFile $dest -UseBasicParsing -UserAgent 'Mozilla/5.0' -TimeoutSec 40
    if ((Get-Item -LiteralPath $dest).Length -gt 2000) { return $dest }
  } catch { Write-Warning "Download failed: $url" }
  Remove-Item -LiteralPath $dest -ErrorAction SilentlyContinue
  return $null
}

function Print-Pdf([string]$html, [string]$pdf, [int]$timeoutSec = 120) {
  & $render -Html $html -PdfOnly -Pdf $pdf -TimeoutSec $timeoutSec
}

$tpl = [IO.File]::ReadAllText($templateFull)
$baseTag = '<base href="' + (FileUrl ((Split-Path -Parent $templateFull) + '\')) + '">'
$tpl = $(if ($tpl -match '(?i)<head[^>]*>') { $tpl -replace '(?i)(<head[^>]*>)', ('$1' + $baseTag) } else { $baseTag + $tpl })
$missing = @{}

function Fill([string]$text, $row) {
  $names = @($row.PSObject.Properties | ForEach-Object { $_.Name })
  $r = [regex]::Replace($text, '\{\{\{\s*([A-Za-z0-9_]+)\s*\}\}\}', {
      param($m) $n = $m.Groups[1].Value; if ($names -contains $n) { [string]$row.$n } else { $script:missing[$n] = 1; '' } })
  [regex]::Replace($r, '\{\{\s*([A-Za-z0-9_]+)\s*\}\}', {
      param($m) $n = $m.Groups[1].Value; if ($names -contains $n) { HtmlEsc ([string]$row.$n) } else { $script:missing[$n] = 1; '' } })
}

$rows = @(Import-Csv -LiteralPath $briefsFull -Encoding UTF8)
if (-not $rows) { throw "No rows in $briefsFull" }
if (-not ($rows[0].PSObject.Properties.Name -contains 'id')) { throw 'The briefs CSV needs an id column.' }
"Loaded $($rows.Count) briefs"

$bodies = New-Object System.Collections.Generic.List[string]
$headHtml = $null
foreach ($row in $rows) {
  $id = [string]$row.id
  $title = $(if ($row.PSObject.Properties.Name -contains 'title') { [string]$row.title } else { '' })
  $folder = $(if ($row.PSObject.Properties.Name -contains 'slug' -and $row.slug) { [string]$row.slug } else { ('{0}-{1}' -f $id, (Slug $title)).Trim('-') })
  $dir = Join-Path $outFull $folder
  $selected = (-not $Only) -or ($Only -contains $id)
  if (-not $selected -and -not $Combined) { continue }
  New-Item -ItemType Directory -Force -Path (Join-Path $dir 'assets') | Out-Null

  foreach ($col in $ImageColumns) {
    if (-not ($row.PSObject.Properties.Name -contains $col)) { continue }
    $src = [string]$row.$col
    $ext = [IO.Path]::GetExtension(($src -replace '[?#].*$', ''))
    if (-not $ext -or $ext.Length -gt 5) { $ext = '.png' }
    $dest = Join-Path $dir "assets\$col$ext"
    $got = $(if ($selected) { Get-Img $src $dest } elseif (Test-Path -LiteralPath $dest) { $dest } else { $null })
    $row.$col = $(if ($got) { FileUrl $got } else { '' })
  }

  $html = Fill $tpl $row
  $htmlPath = Join-Path $dir "$folder.html"
  [IO.File]::WriteAllText($htmlPath, $html, $utf8)
  if ($Combined) {
    if (-not $headHtml) { $headHtml = [regex]::Match($html, '(?is)^.*?<body[^>]*>').Value }
    $bodies.Add([regex]::Match($html, '(?is)<body[^>]*>(.*)</body>').Groups[1].Value)
  }
  if (-not $selected) { continue }

  if ($Png) { & $render -Html $htmlPath -Ids $Slides -Prefix $folder -Out (Join-Path $dir 'png') -Width $Width -Height $Height -Scale $Scale | Out-Host }
  if ($Pdf) {
    $name = $(if ($title) { $title } else { $folder }) -replace '[\\/:*?"<>|]', '-'
    Print-Pdf $htmlPath (Join-Path $dir ("$name$PdfSuffix.pdf"))
  }
  '#{0} {1}' -f $id, $folder
}

if ($missing.Count) { Write-Warning ('Placeholders with no CSV column (left empty): ' + (($missing.Keys | Sort-Object) -join ', ')) }

if ($Combined -and $bodies.Count) {
  $all = $headHtml + "`n" + ($bodies -join "`n<div style=""break-after:page""></div>`n") + "`n</body></html>"
  $allHtml = Join-Path $outFull 'all-creatives.html'
  [IO.File]::WriteAllText($allHtml, $all, $utf8)
  Print-Pdf $allHtml (Join-Path $outFull 'all-creatives.pdf') 900
  "Combined: $allHtml"
}
