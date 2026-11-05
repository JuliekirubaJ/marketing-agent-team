<#
.SYNOPSIS
  Cuts a webinar recording into vertical (1080x1920) shorts for YouTube Shorts and LinkedIn, driven by a CSV
  of start/end times. Light SaaS motion style: logo + kicker, two-line headline with highlight sweep, the
  screen share in a floating card, the speaker in a small card, caption pills, and an outro card.

.EXAMPLE
  .\build-snippets.ps1 -Recording cam.mp4 -Screen share.mp4 -Cuts cuts.csv -Captions captions.csv `
      -Logo logo.png -OutroTitle '<WEBINAR TITLE>' -OutroUrl '<WEBINAR LINK>'
  .\build-snippets.ps1 -Recording talk.mp4 -Cuts cuts.csv -Only S2 -NoVideo

.INPUTS
  -Cuts CSV (required). One row per continuous run of speech; rows with the same snippet id are joined
  in order as jump cuts. Times are in milliseconds on the recording timeline.
      snippet,title,headline1,headline2,highlight,start_ms,end_ms
      S1,The average hides the risk,The average says on time.,The bill says otherwise.,on time,471000,492950
      S1,,,,,503100,508650
  Only the first row of a snippet needs title/headline1/headline2/highlight (highlight = a phrase inside
  the headline that gets a tinted sweep). Snap start/end to pauses so no cut lands mid-word.

  -Captions CSV (optional). Source-time captions; each is shown during the run it falls in.
      snippet,start_ms,end_ms,text

.NOTES
  Zoom cloud recordings come as separate files: *_avo_* = camera only (carries the audio), *_as_* =
  screen share only (muted here), and the plain one = share plus speaker thumbnail.
  With -Screen, the share plays in the main card and the camera in the speaker card. Without it, the
  recording fills the main card.
  Crops are 0..1 fractions of the source frame: x, y, width, height.
#>
param(
  [Parameter(Mandatory = $true)][string]$Recording,
  [Parameter(Mandatory = $true)][string]$Cuts,
  [string]$Screen,
  [string]$Captions,
  [string]$Root,
  [string]$Out,
  [string]$Only = '',
  [string]$Logo,
  [string]$Kicker = 'FROM THE WEBINAR',
  [string]$Footnote = '',
  [string]$OutroTitle = '<WEBINAR TITLE>',
  [string]$OutroSub = '',
  [string]$OutroCta = 'Watch the full webinar',
  [string]$OutroUrl = '<WEBINAR LINK>',
  [double[]]$ScreenCrop = @(0.02, 0.04, 0.66, 0.8),
  [double[]]$CamCrop = @(0.2, 0.03, 0.53, 0.94),
  [hashtable]$Palette,
  [switch]$NoVideo
)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = $(if ($env:MARKETING_ROOT) { $env:MARKETING_ROOT } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }) }
function Get-FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }
if (-not $Out) { $Out = Join-Path $Root ('videos\snippets-' + [IO.Path]::GetFileNameWithoutExtension((Get-FullPath $Cuts))) }
$Out = Get-FullPath $Out
New-Item -ItemType Directory -Force -Path $Out | Out-Null

. (Join-Path $PSScriptRoot 'ppt-video-helpers.ps1')
$VX.Log = Join-Path $env:TEMP 'build-snippets.log'

# Local copies: synced folders can block PowerPoint, and overlapping clips of one file need separate copies
$CAM = (Copy-MediaPool (Get-FullPath $Recording) 1)[0]
$SCR = $(if ($Screen) { (Copy-MediaPool (Get-FullPath $Screen) 1)[0] } else { $null })
$LOGO = $(if ($Logo) { Get-FullPath $Logo } else { $null })

# ---------------------------------------------------------------- load cuts
$snips = [ordered]@{}
foreach ($r in (Import-Csv -LiteralPath (Get-FullPath $Cuts) -Encoding UTF8)) {
  $id = [string]$r.snippet
  if (-not $snips.Contains($id)) {
    $snips[$id] = @{ id = $id; title = [string]$r.title; head = @([string]$r.headline1, [string]$r.headline2) | Where-Object { $_ }; hl = [string]$r.highlight; runs = @(); caps = @() }
  }
  $snips[$id].runs += @{ a = [double]$r.start_ms / 1000; b = [double]$r.end_ms / 1000 }
}
if ($Captions) {
  foreach ($c in (Import-Csv -LiteralPath (Get-FullPath $Captions) -Encoding UTF8)) {
    $id = [string]$c.snippet
    if ($snips.Contains($id)) { $snips[$id].caps += , @(([double]$c.start_ms / 1000), ([double]$c.end_ms / 1000), [string]$c.text) }
  }
}

# ---------------------------------------------------------------- layout (540x960 pt -> 1080x1920 px)
$W = 540; $H = 960
$CARD = @{ l = 24; t = 214; w = 492; h = 346; pad = 10 }
$CAPY = 574
$SPK = @{ l = 24; t = 650; w = 200; h = 200 }
$ARROW = [char]0x2192

function Frame($slide, $sn, $first) {
  $K = $VX.Palette
  Set-SlideBackground $slide $K.bg1 $K.white 1
  if ($LOGO) { $logo = $slide.Shapes.AddPicture($LOGO, 0, -1, 24, 40, -1, -1); $logo.LockAspectRatio = -1; $logo.Height = 30 }
  $tag = Add-Text $slide $Kicker 300 46 216 14 9.5 $K.primary 'Bold' 3
  $tag.TextFrame2.TextRange.Font.Spacing = [single]1.4
  $full = $sn.head -join "`r"
  $hd = Add-Text $slide $full 24 92 492 110 31 $K.ink 'Bold'
  $hd.TextFrame.TextRange.ParagraphFormat.SpaceWithin = [single]0.95
  $hl = $null
  if ($sn.hl -and $full.IndexOf($sn.hl) -ge 0) {
    $chars = $hd.TextFrame.TextRange.Characters($full.IndexOf($sn.hl) + 1, $sn.hl.Length)
    $hl = Add-Shape $slide ($chars.BoundLeft - 4) ($chars.BoundTop + 3) ($chars.BoundWidth + 8) ($chars.BoundHeight - 4) $K.tint 5 $null 0 0.22
    $hl.ZOrder(1)   # behind the headline
  }
  $card = Add-Shape $slide $CARD.l $CARD.t $CARD.w $CARD.h $K.white 5 $K.line 1 0.06; Set-SoftShadow $card $K.deep 18 6 0.84
  $spk = $null
  if ($SCR) { $spk = Add-Shape $slide ($SPK.l - 4) ($SPK.t - 4) ($SPK.w + 8) ($SPK.h + 8) $K.white 5 $K.line 1 0.12; Set-SoftShadow $spk $K.deep 18 6 0.84 }
  if ($Footnote) { Add-Text $slide $Footnote 24 872 492 14 9 $K.muted | Out-Null }
  if ($first) {
    if ($LOGO) { FxAt $slide $logo $FADE 0 0.4 | Out-Null }
    FxAt $slide $tag $FADE 0.1 0.4 | Out-Null
    $e = FxAt $slide $hd $FADE 0.05 0.6
    $null = $slide.TimeLine.MainSequence.ConvertToTextUnitEffect($e, 2)   # word by word
    FxAt $slide $card $RISE 0.15 0.45 | Out-Null
    if ($spk) { FxAt $slide $spk $RISE 0.25 0.45 | Out-Null }
    if ($hl) { FxAt $slide $hl $WIPE 0.8 0.45 -dir $DIR_LEFT | Out-Null }
  }
}

function Build($sn) {
  $pres = New-VideoDeck -Width $W -Height $H -Palette $Palette
  $K = $VX.Palette
  $o = 0.0; foreach ($r in $sn.runs) { $r.o = $o; $r.len = $r.b - $r.a; $o += $r.len }
  $total = $o
  $idx = 0
  $bx = @{ l = $CARD.l + $CARD.pad; t = $CARD.t + $CARD.pad; w = $CARD.w - 2 * $CARD.pad; h = $CARD.h - 2 * $CARD.pad }
  foreach ($r in $sn.runs) {
    $idx++
    $s = $pres.Slides.Add($idx, 12)
    Frame $s $sn ($idx -eq 1)
    # One slide per run. A clip whose EndPoint runs past AdvanceTime stretches the slide, so every clip
    # ends exactly at the run length.
    if ($SCR) {
      $v = Add-LinkedVideo $s $SCR $r.a $r.len $bx.l $bx.t $bx.w $bx.h $ScreenCrop -Mute
      FxAt $s $v $PLAY 0 0.01 | Out-Null
      $cam = Add-LinkedVideo $s $CAM $r.a $r.len $SPK.l $SPK.t $SPK.w $SPK.h $CamCrop -Fit cover -round 0.1
    } else {
      $cam = Add-LinkedVideo $s $CAM $r.a $r.len $bx.l $bx.t $bx.w $bx.h $CamCrop -Fit cover
    }
    FxAt $s $cam $PLAY 0 0.01 | Out-Null
    foreach ($cp in $sn.caps) {
      if ($cp[0] -lt $r.a - 0.05 -or $cp[0] -ge $r.b) { continue }
      $p = Add-Pill $s $cp[2] 0 $CAPY 100 30 $K.ink $K.white 19 'Bold' -Auto -padX 16 -padY 7
      if ($p.Width -gt 488) { $p.TextFrame.WordWrap = -1; $p.TextFrame.AutoSize = 0; $p.Width = 488; $p.TextFrame.AutoSize = 1; $p.Adjustments.Item(1) = [single]0.3 }
      $p.Left = [single](($W - $p.Width) / 2)
      $at = $cp[0] - $r.a; $end = [Math]::Min($cp[1], $r.b) - $r.a
      FxAt $s $p $RISE $at 0.22 | Out-Null
      if ($end -lt $r.len - 0.05) { FxAt $s $p $FADE $end 0.1 -Exit | Out-Null }
    }
    $tr = $s.SlideShowTransition; $tr.AdvanceOnClick = 0; $tr.AdvanceOnTime = -1; $tr.AdvanceTime = [single]$r.len
  }
  # ---- outro: static CTA, no sound
  $s = $pres.Slides.Add($idx + 1, 12)
  Set-SlideBackground $s $K.bg1 $K.white 1
  $t1 = Add-Text $s $OutroTitle 30 380 480 90 30 $K.ink 'Bold' 2
  if ($OutroSub) { $t2 = Add-Text $s $OutroSub 30 476 480 24 16 $K.muted 'Regular' 2; FxAt $s $t2 $RISE 0.55 0.45 | Out-Null }
  $btn = Add-Pill $s "$OutroCta  $ARROW" 0 520 100 40 $K.primary $K.white 19 'Bold' -Auto -padX 26 -padY 12
  $btn.Left = [single](($W - $btn.Width) / 2); Set-SoftShadow $btn $K.deep
  $url = Add-Text $s $OutroUrl 30 590 480 20 14 $K.primary 'Bold' 2
  FxAt $s $t1 $RISE 0.3 0.45 | Out-Null
  if ($LOGO) {
    $lg = $s.Shapes.AddPicture($LOGO, 0, -1, 0, 0, -1, -1); $lg.LockAspectRatio = -1; $lg.Height = 40
    $lg.Left = ($W - $lg.Width) / 2; $lg.Top = 280
    FxAt $s $lg $SWIVEL 0 0.8 | Out-Null   # logo coin-flip
  }
  $tr = $s.SlideShowTransition; $tr.AdvanceOnClick = 0; $tr.AdvanceOnTime = -1; $tr.AdvanceTime = [single]3.5

  $name = ('{0} - {1}' -f $sn.id, $sn.title).Trim(' -') -replace '[\\/:*?"<>|]', '-'
  $base = Join-Path $Out $name
  $pres.SaveAs("$base.pptx")
  $pres.Slides.Item(1).Export("$base-thumb.png", 'PNG', 1080, 1920)
  if (-not $NoVideo) {
    $t0 = Get-Date
    $st = Export-Video $pres "$base.mp4" -Height 1920 -DefaultSlideSec 4 -TimeoutSec 900
    '{0}: status {1}, {2:N1}s video, rendered in {3}s' -f $name, $st, ($total + 3.5), [int]((Get-Date) - $t0).TotalSeconds
  } else { '{0}: {1:N1}s planned (pptx only)' -f $name, ($total + 3.5) }
  Close-VideoDeck $pres -KeepPowerPoint
}

foreach ($sn in $snips.Values) {
  if ($Only -and $sn.id -ne $Only) { continue }
  Build $sn
}
if ($VX.App -and $VX.App.Presentations.Count -eq 0) { $VX.App.Quit() }
