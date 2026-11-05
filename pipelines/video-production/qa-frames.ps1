<#
.SYNOPSIS
  Grabs still frames from an MP4 at given seconds, without ffmpeg: the video is inserted into a PowerPoint
  slide, its poster frame is set to each time, and the slide is exported as PNG.

.EXAMPLE
  .\qa-frames.ps1 -Video ..\..\videos\best-clip\best-clip.mp4 -Times 4.6,26,44.2,62 -Vertical
  .\qa-frames.ps1 -Video demo.mp4 -Times 1,5,10 -Out stills

.NOTES
  - The MP4 is copied to %TEMP% first: PowerPoint fails intermittently on files in cloud-synced folders,
    and a copy avoids locking the original while it is open elsewhere.
  - Use these for review stills. Static slide exports from the build script overlap every caption state.
#>
param(
  [Parameter(Mandatory = $true)][string]$Video,
  [Parameter(Mandatory = $true)][double[]]$Times,
  [string]$Out,
  [switch]$Vertical,
  [int]$WaitMs = 800
)
$ErrorActionPreference = 'Stop'
function Get-FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }
$src = Get-FullPath $Video
if (-not $Out) { $Out = Join-Path (Split-Path -Parent $src) 'stills' }
$Out = Get-FullPath $Out
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$mp4 = Join-Path $env:TEMP ('qa-' + [IO.Path]::GetFileName($src))
Copy-Item -LiteralPath $src -Destination $mp4 -Force

$sw = $(if ($Vertical) { 540 } else { 960 }); $sh = $(if ($Vertical) { 960 } else { 540 })
$ppt = New-Object -ComObject PowerPoint.Application
$pres = $ppt.Presentations.Add(0)
try {
  $pres.PageSetup.SlideWidth = $sw; $pres.PageSetup.SlideHeight = $sh
  foreach ($t in $Times) {
    $s = $pres.Slides.Add(1, 12)
    $v = $s.Shapes.AddMediaObject2($mp4, -1, 0, 0, 0, $sw, $sh)
    $v.Left = 0; $v.Top = 0; $v.Width = $sw; $v.Height = $sh
    $v.MediaFormat.SetDisplayPicture([int]($t * 1000))
    Start-Sleep -Milliseconds $WaitMs
    $png = Join-Path $Out ('qa-{0:00.0}s.png' -f $t)
    $s.Export($png, 'PNG', $sw * 2, $sh * 2)
    $s.Delete()
    $png
  }
} finally {
  $pres.Close()
  if ($ppt.Presentations.Count -eq 0) { $ppt.Quit() }
  Remove-Item -LiteralPath $mp4 -Force -ErrorAction SilentlyContinue
}
