<#
.SYNOPSIS
  Short demo of ppt-video-helpers.ps1: a 4-scene 1920x1080 explainer built over a screenshot.
  Every number on screen comes from the screenshot; overlays only mask, reveal, highlight and move.

.EXAMPLE
  .\example-build-video.ps1                     # placeholder screenshot, pptx + stills + mp4
  .\example-build-video.ps1 -NoVideo            # pptx + stills only
  .\example-build-video.ps1 -Screenshot my-dashboard.png -Out ..\..\videos\my-demo

.NOTES
  Without -Screenshot, a placeholder dashboard image (1280x720) is drawn into <Out>\assets\. The pixel
  regions used by Mask/Box/Lens below match that placeholder; measure your own image's regions in an image
  editor (pixel coordinates of the original file) when you swap it in.
  Copy is placeholder text: replace it with approved copy from brand/positioning.md and brand/claims-and-proof.md.
#>
param(
  [string]$Root,
  [string]$Out,
  [string]$Screenshot,
  [string]$Title = '<PRODUCT> in 20 seconds',
  [string]$EndLine = 'See it with your own data',
  [string]$EndUrl = '<WEBSITE>',
  [switch]$NoVideo
)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = $(if ($env:MARKETING_ROOT) { $env:MARKETING_ROOT } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }) }
if (-not $Out) { $Out = Join-Path $Root 'videos\example-build-video' }
$Out = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
$assets = Join-Path $Out 'assets'
New-Item -ItemType Directory -Force -Path $assets | Out-Null

. (Join-Path $PSScriptRoot 'ppt-video-helpers.ps1')

# ---------------------------------------------------------------- placeholder screenshot
function New-PlaceholderDashboard([string]$path) {
  Add-Type -AssemblyName System.Drawing
  $bmp = New-Object Drawing.Bitmap 1280, 720
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'
  $g.Clear([Drawing.Color]::FromArgb(250, 250, 252))
  $ink = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(30, 30, 60))
  $mut = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(110, 110, 130))
  $acc = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(79, 70, 229))
  $acc2 = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(160, 155, 255))
  $card = New-Object Drawing.SolidBrush ([Drawing.Color]::White)
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(225, 225, 238)), 2
  $fH = New-Object Drawing.Font 'Segoe UI', 22, ([Drawing.FontStyle]::Bold)
  $fK = New-Object Drawing.Font 'Segoe UI', 30, ([Drawing.FontStyle]::Bold)
  $fS = New-Object Drawing.Font 'Segoe UI', 13
  $g.DrawString('Sales plan - FY overview', $fH, $ink, 32, 24)
  $kpis = @(@('Revenue', '12.4M'), @('Margin', '31.2%'), @('Units', '86,450'))
  for ($i = 0; $i -lt 3; $i++) {
    $x = 32 + $i * 410
    $g.FillRectangle($card, $x, 80, 390, 120); $g.DrawRectangle($pen, $x, 80, 390, 120)
    $g.DrawString($kpis[$i][0], $fS, $mut, $x + 20, 96); $g.DrawString($kpis[$i][1], $fK, $ink, $x + 20, 124)
  }
  $g.FillRectangle($card, 32, 224, 800, 464); $g.DrawRectangle($pen, 32, 224, 800, 464)
  $g.DrawString('Revenue by quarter', $fS, $mut, 52, 240)
  $vals = @(220, 300, 260, 360, 330, 400)
  for ($i = 0; $i -lt 6; $i++) {
    $x = 90 + $i * 120; $h = $vals[$i]
    $g.FillRectangle($acc, $x, 660 - $h, 64, $h)
    $g.DrawString(('Q{0}' -f ($i + 1)), $fS, $mut, $x + 18, 664)
  }
  $g.FillRectangle($card, 856, 224, 392, 464); $g.DrawRectangle($pen, 856, 224, 392, 464)
  $g.DrawString('Scenario', $fS, $mut, 876, 240)
  $g.DrawString('Price change', $fS, $ink, 876, 290)
  $g.FillRectangle((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(220, 220, 230))), 876, 330, 340, 6)
  $g.FillRectangle($acc2, 876, 330, 230, 6)
  $g.FillEllipse($acc, 1098, 323, 20, 20)
  $g.DrawString('+5%', $fK, $ink, 876, 360)
  $g.Dispose(); $bmp.Save($path, [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}
if (-not $Screenshot) {
  $Screenshot = Join-Path $assets 'placeholder-dashboard.png'
  if (-not (Test-Path -LiteralPath $Screenshot)) { New-PlaceholderDashboard $Screenshot }
}

# ---------------------------------------------------------------- deck
$pres = New-VideoDeck -Width 960 -Height 540 -Assets $assets
$K = $VX.Palette   # $K, not $C or $c: PowerShell variable names are case-insensitive

# --- Scene 1: hook (kinetic type + floating card)
$s = New-VideoSlide $pres
$chip = Add-Pill $s 'PRODUCT TOUR' 40 30 140 26 $K.primary $K.white 10.5 'Bold'
$l1 = Add-Text $s 'Plan the year.' 40 160 520 64 52 $K.ink 'Black'
$l2 = Add-Text $s 'See every change.' 40 224 520 64 52 $K.primary 'Black'
$sub = Add-Text $s $Title 40 312 520 28 18 $K.muted
FxAt $s $chip $FADE 0 0.4 | Out-Null
Rise $s $l1 $AFTER 0.2 0.5 | Out-Null
Rise $s $l2 $AFTER 0 0.5 | Out-Null
Rise $s $sub $AFTER 0.1 0.5 | Out-Null
$card = Add-Card $s 600 140 320 260
$bars = @()
for ($i = 0; $i -lt 4; $i++) { $bars += Add-Shape $s (640 + $i * 70) (360 - 40 * ($i + 1)) 40 (40 * ($i + 1)) $K.primary2 5 $null 0 0.2 }
Rise $s $card $WITH 0.2 0.6 20 | Out-Null
$first = $true
foreach ($b in $bars) { Fx $s $b $WIPE $(if ($first) { $AFTER } else { $WITH }) 0.5 0.12 -dir $DIR_DOWN | Out-Null; $first = $false }
Complete-Slide $s 1.2

# --- Scene 2: the real screenshot, revealed and highlighted
$s = New-VideoSlide $pres
$h = Add-Text $s 'Every figure stays real' 40 40 880 40 28 $K.ink 'Bold'
Rise $s $h $WITH 0.1 0.5 | Out-Null
$m = Shot $s $Screenshot
$chartMask = Mask $s $m 60 250 830 660 $K.white            # hide the bars, then wipe away to "draw" them
Fx $s $chartMask $WIPE $AFTER 1.4 0.3 -Exit -dir $DIR_DOWN | Out-Null
$kpi = Box $s $m 32 80 422 200 3
Fx $s $kpi $FADE $AFTER 0.4 0.2 | Out-Null
$lens = Lens $s $m 32 80 422 200 300 380 1.4
Fx $s $lens $FADEDZOOM $AFTER 0.5 0.2 | Out-Null
Hold 1.4
Fx $s $lens $FADE $AFTER 0.4 0 -Exit | Out-Null
Fx $s $kpi $FADE $WITH 0.4 0 -Exit | Out-Null
Complete-Slide $s 1.0

# --- Scene 3: a control moves into its real final position
$s = New-VideoSlide $pres
$h = Add-Text $s 'Try a scenario' 40 40 880 40 28 $K.ink 'Bold'
Rise $s $h $WITH 0.1 0.5 | Out-Null
$m = Shot $s $Screenshot
# cover the finished slider and value, draw a neutral start state, then slide the knob to where the screenshot has it
$cover = Mask $s $m 870 320 1240 410 $K.white
$a = P $m 876 330; $b = P $m 1216 336
$track = Add-Shape $s $a[0] $a[1] ($b[0] - $a[0]) ($b[1] - $a[1]) $K.skel
$k0 = P $m 886 333; $r = 10 * $m.s
$knob = Add-Shape $s ($k0[0] - $r) ($k0[1] - $r) (2 * $r) (2 * $r) $K.primary $SHP_OVAL
$panel = Box $s $m 856 224 1248 688 4
Fx $s $panel $FADE $AFTER 0.4 0.3 | Out-Null
$e = Slide-Knob $s $knob ((1108 - 886) * $m.s) 0 $AFTER 1.1 0.2
Fx $s $cover $FADE $AFTER 0.3 0 -Exit | Out-Null
Fx $s $track $FADE $WITH 0.3 0 -Exit | Out-Null
Fx $s $knob $FADE $WITH 0.3 0 -Exit | Out-Null
Complete-Slide $s 1.6

# --- Scene 4: end card (static CTA, no sound)
$s = New-VideoSlide $pres
Set-SlideBackground $s $K.primary $K.deep
$t1 = Add-Text $s $EndLine 80 220 800 44 32 $K.white 'Bold' 2
$cta = Add-Pill $s $EndUrl 340 300 280 46 $K.white $K.deep 17 'Bold'
Rise $s $t1 $AFTER 0.1 0.5 | Out-Null
Complete-Slide $s 2.4

# ---------------------------------------------------------------- save + render
$pptx = Join-Path $Out 'example-video.pptx'
$pres.SaveAs($pptx)
Export-QAStills $pres (Join-Path $Out '_qa') 1920 1080
'Saved {0}  (~{1:0.0}s)' -f $pptx, (Get-DeckRuntime $pres)
if (-not $NoVideo) {
  $st = Export-Video $pres (Join-Path $Out 'example-video.mp4') -Height 1080
  "Video status: $st (3 = done)"
}
Close-VideoDeck $pres
