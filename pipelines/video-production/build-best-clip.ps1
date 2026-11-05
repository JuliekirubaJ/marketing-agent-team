<#
.SYNOPSIS
  Builds a podcast-style vertical highlight clip (1080x1920, 30 fps) from a webinar recording:
  camera card with lower third, word-by-word karaoke captions, a waveform progress bar, an optional
  screen-share cut-in, and a replay end card. Jump cuts between runs land in measured pauses.

.EXAMPLE
  .\build-best-clip.ps1 -Recording cam.mp4 -Runs runs.csv -Phrases phrases.csv -Envelope envelope.txt `
      -Headline1 "Don't copy your" -Headline2 'whole data model' -Logo logo.png -EndUrl '<WEBINAR LINK>'
  .\build-best-clip.ps1 ... -Screen share.mp4 -CutIn 2234.55,2249.15 -CutInCrop 0.05,0.2,0.3,0.32 -NoVideo

.INPUTS
  -Runs CSV: continuous pieces of the recording, in order (seconds). zoom > 1 punches in on the camera,
  which hides a jump cut between two runs.
      start_s,end_s,zoom
      2181.85,2188.78,1
      2192.40,2193.90,1.14
  -Phrases CSV: verbatim speech per window (seconds). Words are spread over the voiced 50 ms frames of each
  window, weighted by syllables. Write the transcript verbatim; do not tidy the speaker's wording.
      start_s,end_s,text
      2182.00,2188.75,"A lot of people looked at the documentation and said..."
  -Envelope (optional): one line per 50 ms frame, "<seconds> <rms 0..1>", on the recording timeline.
  Produce it with an audio RMS scan (see docs/video-production.md). Without it every frame counts as voiced
  and the waveform is drawn from word density, so captions drift more.

.OUTPUTS
  <Out>\<Name>.pptx, .mp4, assets\slideN-static.png stills, assets\caption-timing.txt (source time,
  output time and text of every caption chunk, for QA against the audio).
#>
param(
  [Parameter(Mandatory = $true)][string]$Recording,
  [Parameter(Mandatory = $true)][string]$Runs,
  [Parameter(Mandatory = $true)][string]$Phrases,
  [string]$Envelope,
  [string]$Screen,
  [double[]]$CutIn,
  [double[]]$CutInCrop = @(0, 0, 1, 1),
  [string]$CutInLabel = 'ON SCREEN',
  [double[]]$CamCrop = @(0.28, 0.07, 0.58, 0.88),
  [string]$Root,
  [string]$Out,
  [string]$Name = 'best-clip',
  [string]$Logo,
  [string]$Chip = 'WEBINAR CLIP',
  [string]$Kicker = '<WEBINAR TOPIC>',
  [string]$Headline1 = '<HEADLINE LINE 1>',
  [string]$Headline2 = '<HEADLINE LINE 2>',
  [string]$SpeakerName = '',
  [string]$SpeakerOrg = '',
  [string]$FooterText = 'Full replay at the end',
  [string]$EndKicker = 'WEBINAR REPLAY',
  [string]$EndTitle = '<WEBINAR TITLE>',
  [string]$EndSub = '',
  [string]$EndCta = 'Watch Full Replay',
  [string]$EndUrl = '<WEBINAR LINK>',
  [hashtable]$Palette,
  [switch]$NoVideo
)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = $(if ($env:MARKETING_ROOT) { $env:MARKETING_ROOT } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }) }
function Get-FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }
if (-not $Out) { $Out = Join-Path $Root "videos\$Name" }
$Out = Get-FullPath $Out
$assetsDir = Join-Path $Out 'assets'
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

. (Join-Path $PSScriptRoot 'ppt-video-helpers.ps1')
# log outside synced folders, so sync locks never block it
$VX.Log = Join-Path $env:TEMP "$Name-build.log"
try { [IO.File]::WriteAllText($VX.Log, '') } catch {}
Write-VideoLog 'start'
trap { Write-VideoLog ('ERROR line {0}: {1}' -f $_.InvocationInfo.ScriptLineNumber, $_); break }

$CAM = (Copy-MediaPool (Get-FullPath $Recording) 1)[0]
$SCR = $(if ($Screen) { (Copy-MediaPool (Get-FullPath $Screen) 1)[0] } else { $null })
$LOGO = $(if ($Logo) { Get-FullPath $Logo } else { $null })
$DOT = [char]0x00B7; $PLAYCH = [char]0x25B6

$W = 540; $H = 960
$CARD = @{ l = 24; t = 196; w = 492; h = 420; pad = 8 }
$CAPT = 640; $CAPH = 92
$WAVE = @{ l = 24; t = 738; w = 492; h = 92 }

# ---------------------------------------------------------------- inputs
$RunList = @(Import-Csv -LiteralPath (Get-FullPath $Runs) | ForEach-Object {
    @{ a = [double]$_.start_s; b = [double]$_.end_s; zoom = $(if ($_.zoom) { [double]$_.zoom } else { 1.0 }) } })
$PhraseList = @(Import-Csv -LiteralPath (Get-FullPath $Phrases) -Encoding UTF8 | ForEach-Object { , @([double]$_.start_s, [double]$_.end_s, [string]$_.text) })
$ENVL = @{}
if ($Envelope) { foreach ($ln in Get-Content -LiteralPath (Get-FullPath $Envelope)) { $p = $ln -split '\s+'; if ($p.Count -ge 2) { $ENVL[[int][Math]::Round([double]$p[0] * 20)] = [double]$p[1] } } }

# ---------------------------------------------------------------- word timing
function Syl([string]$w) {
  $x = $w.ToLower() -replace "[^a-z0-9\.\-']", ''
  $n = 0
  foreach ($part in ($x -split '-')) {
    $q = $part -replace "'", ''
    if ($q -match '[0-9]') { $n += [Math]::Max(2, ($q -replace '[^0-9]', '').Length); continue }
    $c = ([regex]::Matches($q, '[aeiouy]+')).Count
    if ($q.Length -gt 2 -and $q.EndsWith('e') -and -not $q.EndsWith('le') -and $c -gt 1) { $c-- }
    $n += [Math]::Max(1, $c)
  }
  return [Math]::Max(1, $n)
}
function Is-Voiced([int]$frame) { if ($ENVL.Count -eq 0) { return $true }; return ($ENVL[$frame] -gt 0.02) }

$WORDS = New-Object System.Collections.ArrayList
foreach ($ph in $PhraseList) {
  $ws = @($ph[2] -split ' ' | Where-Object { $_ })
  $voiced = @(); for ($fk = [int][Math]::Round($ph[0] * 20); $fk -lt [int][Math]::Round($ph[1] * 20); $fk++) { if (Is-Voiced $fk) { $voiced += $fk / 20.0 } }
  if (-not $voiced) { Write-Warning "No voiced frames in phrase at $($ph[0])s"; continue }
  $syl = @($ws | ForEach-Object { Syl $_ }); $tot = ($syl | Measure-Object -Sum).Sum
  $cum = 0
  for ($i = 0; $i -lt $ws.Count; $i++) {
    $fi = [Math]::Min($voiced.Count - 1, [int][Math]::Floor($cum / $tot * $voiced.Count))
    $cum += $syl[$i]
    $fe = [Math]::Max($fi, [Math]::Min($voiced.Count - 1, [int][Math]::Ceiling($cum / $tot * $voiced.Count) - 1))
    [void]$WORDS.Add(@{ w = $ws[$i]; s = $voiced[$fi]; e = $voiced[$fe] + 0.05 })
  }
}
# caption chunks: 2-3 words (4 if the 4th closes a clause), break on punctuation and pauses
$CHUNKS = New-Object System.Collections.ArrayList
$cur = @()
for ($i = 0; $i -lt $WORDS.Count; $i++) {
  $cur += $WORDS[$i]
  $punct = $WORDS[$i].w -match '[,\.\?!]$'
  $gap = ($i + 1 -lt $WORDS.Count) -and ($WORDS[$i + 1].s - $WORDS[$i].e -gt 0.35)
  $nextPunct = ($i + 1 -lt $WORDS.Count) -and ($WORDS[$i + 1].w -match '[,\.\?!]$')
  if ($punct -or $gap -or $cur.Count -ge 4 -or ($cur.Count -ge 3 -and -not $nextPunct)) { [void]$CHUNKS.Add($cur); $cur = @() }
}
if ($cur.Count) { [void]$CHUNKS.Add($cur) }
# merge a lone 1-word chunk into a short predecessor when they are adjacent
$merged = New-Object System.Collections.ArrayList
foreach ($c in $CHUNKS) {
  if ($merged.Count -and $c.Count -eq 1 -and $merged[$merged.Count - 1].Count -le 2 -and ($c[0].s - $merged[$merged.Count - 1][-1].e) -lt 0.3 -and $merged[$merged.Count - 1][-1].w -notmatch '[\.\?!]$') {
    $merged[$merged.Count - 1] = @($merged[$merged.Count - 1]) + @($c)
  } else { [void]$merged.Add(@($c)) }
}
$CHUNKS = $merged

# output timeline
$o = 0.0; foreach ($r in $RunList) { $r.o = $o; $r.len = $r.b - $r.a; $o += $r.len }
$TOTAL = $o
function SrcToOut($t) { foreach ($r in $RunList) { if ($t -ge $r.a -and $t -le $r.b) { return $r.o + $t - $r.a } }; return $null }

# waveform bars in output time (from the envelope, or from word density without one)
$NB = 58
$BARS = @()
for ($i = 0; $i -lt $NB; $i++) {
  $t0 = $i * $TOTAL / $NB; $t1 = ($i + 1) * $TOTAL / $NB; $acc = 0.0; $n = 0
  foreach ($r in $RunList) {
    for ($t = [Math]::Max($t0, $r.o); $t -lt [Math]::Min($t1, $r.o + $r.len); $t += 0.05) {
      $src = $r.a + $t - $r.o
      if ($ENVL.Count) { $fk = [int][Math]::Round($src * 20); if ($ENVL.ContainsKey($fk)) { $acc += $ENVL[$fk] } }
      else { foreach ($wd in $WORDS) { if ($src -ge $wd.s -and $src -lt $wd.e) { $acc += 1; break } } }
      $n++
    }
  }
  $BARS += $(if ($n) { $acc / $n } else { 0 })
}
$bmax = [Math]::Max(0.0001, ($BARS | Measure-Object -Maximum).Maximum)

# ---------------------------------------------------------------- frame pieces
function Header($slide) {
  $K = $VX.Palette
  if ($LOGO) { $lg = $slide.Shapes.AddPicture($LOGO, 0, -1, 24, 34, -1, -1); $lg.LockAspectRatio = -1; $lg.Height = 30 }
  $chipShape = Add-Pill $slide $Chip 0 38 100 24 $K.tint $K.primary 9.5 'Bold' -Auto -padX 12 -padY 5
  $chipShape.Left = [single]($W - 24 - $chipShape.Width)
  $chipShape.TextFrame2.TextRange.Font.Spacing = [single]1.2
  $kick = Add-Text $slide $Kicker.ToUpper() 24 88 492 14 10 $K.primary2 'Bold'
  $kick.TextFrame2.TextRange.Font.Spacing = [single]1.3
  $hd = Add-Text $slide "$Headline1`r$Headline2" 24 106 492 84 31 $K.ink 'Black'
  $hd.TextFrame.TextRange.ParagraphFormat.SpaceWithin = [single]0.92
  $hd.TextFrame.TextRange.Paragraphs(2).Font.Color.RGB = $K.primary
}
function Footer($slide) {
  $K = $VX.Palette
  $wc = Add-Shape $slide $WAVE.l $WAVE.t $WAVE.w $WAVE.h $K.white 5 $K.line 1 0.22; Set-SoftShadow $wc $K.deep 22 8 0.86
  $pb = Add-Shape $slide ($WAVE.l + 18) ($WAVE.t + 26) 40 40 $K.primary $SHP_OVAL
  $tri = Add-Shape $slide ($WAVE.l + 31) ($WAVE.t + 39) 18 14 $K.white $SHP_TRIANGLE; $tri.Rotation = [single]90
  if ($FooterText) { Add-Text $slide $FooterText 24 852 492 16 10.5 $K.muted 'Regular' 2 | Out-Null }
  return @($wc, $pb, $tri)
}
function BarGeom($i) {
  $x0 = $WAVE.l + 74; $span = $WAVE.w - 74 - 20; $step = $span / $NB
  $hgt = 6 + 46 * [Math]::Sqrt($BARS[$i] / $bmax)
  return @{ l = $x0 + $i * $step; t = $WAVE.t + $WAVE.h / 2 - $hgt / 2; w = 4.2; h = $hgt }
}
# grey bars for the whole clip, and accent bars that appear as playback passes them
function Bars($slide, $fromT, $toT) {
  $K = $VX.Palette
  for ($i = 0; $i -lt $NB; $i++) { $g = BarGeom $i; Add-Shape $slide $g.l $g.t $g.w $g.h $K.skel 5 $null 0 0.5 | Out-Null }
  for ($i = 0; $i -lt $NB; $i++) {
    $bt = $i * $TOTAL / $NB
    if ($bt -ge $toT) { break }
    $g = BarGeom $i
    $b = Add-Shape $slide $g.l $g.t $g.w $g.h $K.primary 5 $null 0 0.5
    if ($bt -ge $fromT) { FxAt $slide $b $APPEAR ($bt - $fromT) 0.01 | Out-Null }
  }
}
function LowerThird($slide, $animate) {
  if (-not $SpeakerName) { return }
  $K = $VX.Palette
  $label = $(if ($SpeakerOrg) { "$SpeakerName  $DOT  $SpeakerOrg" } else { $SpeakerName })
  $lt = Add-Pill $slide $label ($CARD.l + 20) ($CARD.t + $CARD.h - 54) 100 30 $K.white $K.ink 13 'Bold' -Auto -padX 14 -padY 7
  if ($SpeakerOrg) { $lt.TextFrame.TextRange.Characters($SpeakerName.Length + 1, $label.Length - $SpeakerName.Length).Font.Color.RGB = $K.primary }
  $lt.TextFrame.MarginLeft = 22
  Set-SoftShadow $lt $K.deep
  $acc = Add-Shape $slide ($lt.Left + 8) ($lt.Top + 8) 5 ($lt.Height - 16) $K.primary 5 $null 0 0.5
  if ($animate) { FxAt $slide $lt $RISE 0.5 0.45 | Out-Null; FxAt $slide $acc $RISE 0.5 0.45 | Out-Null }
}
# One caption textbox per word state; the active word is accent-coloured on a tinted chip. Each state is
# shown and hidden with Appear (rise-up travels too far for per-word text).
function Caption($slide, $chunk, $rOff, $rLen, $chunkEnd) {
  $K = $VX.Palette
  $text = ($chunk | ForEach-Object { $_.w }) -join ' '
  $idx = 0; $starts = @(); foreach ($wd in $chunk) { $starts += $idx; $idx += $wd.w.Length + 1 }
  for ($wi = 0; $wi -lt $chunk.Count; $wi++) {
    $on = $chunk[$wi].s - $rOff
    $off = $(if ($wi + 1 -lt $chunk.Count) { $chunk[$wi + 1].s - $rOff } else { $chunkEnd - $rOff })
    if ($off -le 0 -or $on -ge $rLen) { continue }
    $tb = Add-Text $slide $text 30 $CAPT 480 $CAPH 30 $K.ink 'Black' 2
    $tb.TextFrame.VerticalAnchor = 3
    $tb.TextFrame.TextRange.ParagraphFormat.SpaceWithin = [single]0.95
    $ch = $tb.TextFrame.TextRange.Characters($starts[$wi] + 1, $chunk[$wi].w.Length)
    $ch.Font.Color.RGB = $K.primary
    $hl = Add-Shape $slide ($ch.BoundLeft - 6) ($ch.BoundTop + 1) ($ch.BoundWidth + 12) ($ch.BoundHeight - 1) $K.tint 5 $null 0 0.28
    $hl.ZOrder(1)
    $grp = $slide.Shapes.Range([object[]]@($hl.Name, $tb.Name)).Group()
    $grp.ZOrder(0)
    $at = [Math]::Max(0, $on)
    if ($at -gt 0) { FxAt $slide $grp $APPEAR $at 0.01 | Out-Null }
    if ($off -lt $rLen - 0.03) { FxAt $slide $grp $APPEAR $off 0.01 -Exit | Out-Null }
  }
}

# ---------------------------------------------------------------- build
$pres = New-VideoDeck -Width $W -Height $H -Palette $Palette
$K = $VX.Palette
$si = 0
Write-VideoLog ('words {0}, chunks {1}, total {2:F2}s' -f $WORDS.Count, $CHUNKS.Count, $TOTAL)
$bx = @{ l = $CARD.l + $CARD.pad; t = $CARD.t + $CARD.pad; w = $CARD.w - 2 * $CARD.pad; h = $CARD.h - 2 * $CARD.pad }
foreach ($r in $RunList) {
  $si++
  Write-VideoLog "slide $si"
  $s = $pres.Slides.Add($si, 12)
  Set-SlideBackground $s $K.bg1 $K.white 1
  Header $s
  $camCard = Add-Shape $s $CARD.l $CARD.t $CARD.w $CARD.h $K.white 5 $K.line 1 0.07; Set-SoftShadow $camCard $K.deep 22 8 0.86
  # zoom punches in around the crop centre (vertical bias up, to keep the head in frame)
  $z = $r.zoom; $cw = $CamCrop[2] / $z; $chh = $CamCrop[3] / $z
  $crop = @(($CamCrop[0] + ($CamCrop[2] - $cw) / 2), ($CamCrop[1] + ($CamCrop[3] - $chh) * 0.35), $cw, $chh)
  $camShape = Add-LinkedVideo $s $CAM $r.a $r.len $bx.l $bx.t $bx.w $bx.h $crop -Fit cover -round 0.055
  FxAt $s $camShape $PLAY 0 0.01 | Out-Null
  LowerThird $s ($si -eq 1)
  if ($SCR -and $CutIn -and $CutIn.Count -eq 2 -and $CutIn[0] -ge $r.a -and $CutIn[0] -lt $r.b) {
    $inAt = $CutIn[0] - $r.a; $outAt = [Math]::Min($CutIn[1], $r.b) - $r.a
    $sc = Add-Shape $s $CARD.l $CARD.t $CARD.w $CARD.h $K.white 5 $K.line 1 0.07; Set-SoftShadow $sc $K.deep 22 8 0.86
    $sv = Add-LinkedVideo $s $SCR $CutIn[0] ($outAt - $inAt) $bx.l $bx.t $bx.w $bx.h $CutInCrop -Fit cover -Mute -round 0.04
    $tag = Add-Pill $s $CutInLabel ($CARD.l + 20) ($CARD.t + 20) 100 24 $K.primary $K.white 9.5 'Bold' -Auto -padX 12 -padY 5
    $tag.TextFrame2.TextRange.Font.Spacing = [single]1.1
    foreach ($x in @($sc, $sv, $tag)) { FxAt $s $x $ZOOM $inAt 0.35 | Out-Null }
    FxAt $s $sv $PLAY $inAt 0.01 | Out-Null
    if ($outAt -lt $r.len - 0.05) { foreach ($x in @($sc, $sv, $tag)) { FxAt $s $x $FADE $outAt 0.3 -Exit | Out-Null } }
  }
  $fw = Footer $s
  if ($si -eq 1) { foreach ($x in $fw) { FxAt $s $x $RISE 0.2 0.45 | Out-Null } }
  Bars $s $r.o ($r.o + $r.len)
  for ($c = 0; $c -lt $CHUNKS.Count; $c++) {
    $chunk = $CHUNKS[$c]
    if ($chunk[0].s -lt $r.a -or $chunk[0].s -ge $r.b) { continue }
    $nextS = $(if ($c + 1 -lt $CHUNKS.Count) { $CHUNKS[$c + 1][0].s } else { 1e9 })
    $end = [Math]::Min([Math]::Min($nextS, $chunk[-1].e + 0.6), $r.b)
    Caption $s $chunk $r.a $r.len $end
  }
  $tr = $s.SlideShowTransition; $tr.AdvanceOnClick = 0; $tr.AdvanceOnTime = -1; $tr.AdvanceTime = [single]$r.len
}

# ---- end card: content block centred vertically, static CTA, no sound
$s = $pres.Slides.Add($si + 1, 12)
Set-SlideBackground $s $K.bg1 $K.white 1
$top = 300
$glow = Add-Shape $s 70 ($top - 80) 400 400 $K.tint $SHP_OVAL; $glow.Fill.Transparency = [single]0.35; $glow.SoftEdge.Radius = [single]60
if ($LOGO) { $lg = $s.Shapes.AddPicture($LOGO, 0, -1, 0, 0, -1, -1); $lg.LockAspectRatio = -1; $lg.Height = 46; $lg.Left = ($W - $lg.Width) / 2; $lg.Top = [single]$top; FxAt $s $lg $ZOOM 0 0.5 | Out-Null }
$k1 = Add-Text $s $EndKicker 30 ($top + 94) 480 16 11 $K.primary2 'Bold' 2
$k1.TextFrame2.TextRange.Font.Spacing = [single]1.6
$t1 = Add-Text $s $EndTitle 24 ($top + 120) 492 80 25 $K.ink 'Black' 2
$t1.TextFrame.TextRange.ParagraphFormat.SpaceWithin = [single]0.95
if ($EndSub) { $t2 = Add-Text $s $EndSub 24 ($top + 210) 492 18 12 $K.muted 'Regular' 2; FxAt $s $t2 $RISE 0.5 0.45 | Out-Null }
$btn = Add-Pill $s "$EndCta   $PLAYCH" 0 ($top + 264) 100 40 $K.primary $K.white 20 'Bold' -Auto -padX 30 -padY 13
$btn.Left = [single](($W - $btn.Width) / 2)
$last = $btn.TextFrame.TextRange.Characters($btn.TextFrame.TextRange.Length, 1); $last.Font.Name = 'Segoe UI Symbol'; $last.Font.Size = [single]15
Set-SoftShadow $btn $K.deep
$url = Add-Text $s $EndUrl 24 ($top + 344) 492 40 12.5 $K.primary 'Bold' 2
FxAt $s $k1 $FADE 0.25 0.4 | Out-Null
FxAt $s $t1 $RISE 0.35 0.45 | Out-Null
FxAt $s $url $FADE 1.1 0.4 | Out-Null
$tr = $s.SlideShowTransition; $tr.AdvanceOnClick = 0; $tr.AdvanceOnTime = -1; $tr.AdvanceTime = [single]4.0

# ---- save, stills, timing log, render
$base = Join-Path $Out $Name
$pres.SaveAs("$base.pptx"); Write-VideoLog 'saved pptx'
# Static exports overlap every caption state; use them for layout only. Review motion stills come from
# the MP4 via qa-frames.ps1.
foreach ($i in 1..$pres.Slides.Count) { $pres.Slides.Item($i).Export((Join-Path $assetsDir "slide$i-static.png"), 'PNG', 1080, 1920) }
$log = @('total clip {0:F2}s + 4.0s end card' -f $TOTAL)
foreach ($c in $CHUNKS) { $log += ('{0,8:F2} {1,8:F2}  out {2,6:F2}  {3}' -f $c[0].s, $c[-1].e, (SrcToOut $c[0].s), (($c | ForEach-Object { $_.w }) -join ' ')) }
$log | Set-Content -LiteralPath (Join-Path $assetsDir 'caption-timing.txt') -Encoding UTF8
if (-not $NoVideo) {
  Write-VideoLog 'render start'
  $st = Export-Video $pres "$base.mp4" -Height 1920 -DefaultSlideSec 4 -TimeoutSec 2400
  'Video status {0} (3 = done): {1:N1}s planned' -f $st, ($TOTAL + 4)
}
Close-VideoDeck $pres
Write-VideoLog 'closed'
