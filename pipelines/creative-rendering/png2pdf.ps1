<#
.SYNOPSIS
  Builds a full-bleed PDF (one image per page) from PNG/JPG files through PowerPoint COM.
  Typical use: a LinkedIn document-carousel PDF from rendered slide PNGs.

.EXAMPLE
  .\png2pdf.ps1 -In creatives\launch\png -Filter 'carousel-s*@2x.png' -Out creatives\launch\carousel.pdf
  .\png2pdf.ps1 -In a.png,b.png,c.png -Out deck.pdf -PageWidth 810

.NOTES
  - -In is a folder (with -Filter) or a list of image files. Folder matches are sorted naturally by the
    last number in the file name (s2 before s10).
  - Page size: -PageWidth points wide, height from the first image's aspect ratio unless -PageHeight is given.
    810 x 1012.5 pt is a 4:5 carousel page.
  - PowerPoint is only quit when this script leaves no other presentation open.
#>
param(
  [Parameter(Mandatory = $true)][string[]]$In,
  [Parameter(Mandatory = $true)][string]$Out,
  [string]$Filter = '*.png',
  [double]$PageWidth = 810,
  [double]$PageHeight = 0
)
$ErrorActionPreference = 'Stop'
function Get-FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }

$files = @()
foreach ($i in $In) {
  $full = Get-FullPath $i
  if (Test-Path -LiteralPath $full -PathType Container) {
    $files += Get-ChildItem -LiteralPath $full -Filter $Filter -File |
      Sort-Object @{ Expression = { $m = [regex]::Matches($_.BaseName, '\d+'); if ($m.Count) { [int]$m[$m.Count - 1].Value } else { 0 } } }, Name
  } elseif (Test-Path -LiteralPath $full) {
    $files += Get-Item -LiteralPath $full
  } else { Write-Warning "Not found: $full" }
}
if (-not $files) { throw 'No images found.' }

if ($PageHeight -le 0) {
  Add-Type -AssemblyName System.Drawing
  $img = [Drawing.Image]::FromFile($files[0].FullName)
  try { $PageHeight = [Math]::Round($PageWidth * $img.Height / $img.Width, 2) } finally { $img.Dispose() }
}

$outFull = Get-FullPath $Out
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outFull) | Out-Null
$pp = New-Object -ComObject PowerPoint.Application
$pres = $pp.Presentations.Add(0)
try {
  $pres.PageSetup.SlideWidth = [single]$PageWidth
  $pres.PageSetup.SlideHeight = [single]$PageHeight
  foreach ($f in $files) {
    $s = $pres.Slides.Add($pres.Slides.Count + 1, 12)   # ppLayoutBlank
    $null = $s.Shapes.AddPicture($f.FullName, 0, -1, 0, 0, [single]$PageWidth, [single]$PageHeight)
  }
  $pres.SaveAs([string]$outFull, 32)   # ppSaveAsPDF
} finally {
  $pres.Close()
  if ($pp.Presentations.Count -eq 0) { $pp.Quit() }
  [void][Runtime.InteropServices.Marshal]::ReleaseComObject($pp)
}
if (-not (Test-Path -LiteralPath $outFull)) { throw "PDF was not created: $outFull" }
'{0}: {1} pages, {2:N0} bytes' -f (Split-Path $outFull -Leaf), $files.Count, (Get-Item -LiteralPath $outFull).Length
