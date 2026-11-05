<#
.SYNOPSIS
  Reusable helpers for building motion-graphics videos with PowerPoint COM: animations over real
  screenshots or footage, rendered to MP4 with Presentation.CreateVideo. No ffmpeg, Node or Python.

.USAGE
  . (Join-Path $PSScriptRoot 'ppt-video-helpers.ps1')          # dot-source
  $pres = New-VideoDeck -Width 960 -Height 540 -Assets $assets  # 960x540 pt -> 1920x1080 MP4
  $s = New-VideoSlide $pres
  $m = Shot $s 'screen.png'                                     # screenshot in a framed card
  $mk = Mask $s $m 100 80 600 300 $VX.Palette.white             # cover a region...
  Fx $s $mk $WIPE $AFTER 1.2 0.3 -Exit -dir 4 | Out-Null        # ...and wipe it away to reveal
  Complete-Slide $s 1.5
  Export-Video $pres 'out.mp4'
  Close-VideoDeck $pres

.TIMING MODELS
  Sequential (explainer videos): Fx/Rise/Slide-Knob with $AFTER or $WITH. The helpers keep a running
  clock ($script:VxClock) per slide, so Complete-Slide knows how long the slide's animations take.
  Absolute (footage edits): FxAt places every effect "with previous" at a fixed second on the slide,
  which keeps captions and overlays locked to the source timeline.

.STATE
  All configuration lives in $VX (palette, fonts, slide size, assets folder, SFX map). PowerShell
  variable names are case-insensitive: do not name your own variables $vx, $VxClock, $VxLastStart or $VxScene.
#>

# ---------------------------------------------------------------- constants
# effect ids (msoAnimEffect)
$CUSTOM = 0; $APPEAR = 1; $FADE = 10; $STRETCH = 17; $SWIVEL = 19; $WIPE = 22; $ZOOM = 23
$RISE = 34; $FADEDZOOM = 53; $PLAY = 83
# triggers (msoAnimTriggerType)
$ON_CLICK = 1; $WITH = 2; $AFTER = 3
# wipe / stretch directions (msoAnimDirection) used most often
$DIR_UP = 1; $DIR_RIGHT = 2; $DIR_DOWN = 3; $DIR_LEFT = 4; $DIR_ACROSS = 18
# shape types (msoAutoShapeType)
$SHP_RECT = 1; $SHP_ROUNDED = 5; $SHP_TRIANGLE = 7; $SHP_OVAL = 9

$script:VxClock = 0.0; $script:VxLastStart = 0.0; $script:VxScene = 0

function ConvertTo-OleColor([string]$hex) {
  # PowerPoint wants BGR as an int: R + 256*G + 65536*B
  $h = $hex.TrimStart('#')
  [int]('0x' + $h.Substring(0, 2)) + 256 * [int]('0x' + $h.Substring(2, 2)) + 65536 * [int]('0x' + $h.Substring(4, 2))
}
function RGB([string]$hex) { ConvertTo-OleColor $hex }

function New-VideoPalette([hashtable]$Hex) {
  # Neutral defaults; override any key with brand colours (hex strings).
  $base = [ordered]@{
    ink = '#16163A'; primary = '#4F46E5'; primary2 = '#8B85FF'; deep = '#312E81'; tint = '#EEF0FF'
    bg1 = '#F8F8FC'; bg2 = '#ECECF8'; white = '#FFFFFF'; muted = '#5E5E78'; line = '#DDDDF0'
    good = '#1F9D55'; bad = '#E5383B'; skel = '#E4E4F2'; band = '#F8F8F8'
  }
  if ($Hex) { foreach ($k in $Hex.Keys) { $base[$k] = $Hex[$k] } }
  $p = @{}; foreach ($k in $base.Keys) { $p[$k] = ConvertTo-OleColor $base[$k] }
  return $p
}

$VX = @{
  W = 960; H = 540; Font = 'Segoe UI'; FontBlack = 'Segoe UI Black'; FontSemi = 'Segoe UI Semibold'
  Icons = 'Segoe Fluent Icons'; Assets = $null; Palette = (New-VideoPalette); NoAudio = $false
  Sfx = @{}; SceneLen = @(); App = $null; Log = $null
}

function Write-VideoLog([string]$msg) {
  # Logs to a file outside synced folders (cloud sync locks can block writes mid-render). Retries briefly.
  if (-not $VX.Log) { return }
  for ($i = 0; $i -lt 5; $i++) { try { [IO.File]::AppendAllText($VX.Log, ('{0:HH:mm:ss} {1}' -f (Get-Date), $msg) + "`r`n"); return } catch { Start-Sleep -Milliseconds 200 } }
}

function Resolve-Asset([string]$file) {
  if ([IO.Path]::IsPathRooted($file)) { return $file }
  if ($VX.Assets) { return (Join-Path $VX.Assets $file) }
  return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($file)
}

# ---------------------------------------------------------------- deck
function New-VideoDeck([double]$Width = 960, [double]$Height = 540, [string]$Assets, [hashtable]$Palette, [string]$Font) {
  # 960x540 pt renders 1920x1080 at Export-Video -Height 1080; 540x960 pt renders 1080x1920 at -Height 1920.
  $VX.W = $Width; $VX.H = $Height
  if ($Assets) { $VX.Assets = $Assets }
  if ($Palette) { $VX.Palette = New-VideoPalette $Palette }
  if ($Font) { $VX.Font = $Font }
  if (-not $VX.App) { $VX.App = New-Object -ComObject PowerPoint.Application }
  $pres = $VX.App.Presentations.Add(0)
  $pres.PageSetup.SlideWidth = [single]$Width; $pres.PageSetup.SlideHeight = [single]$Height
  $script:VxScene = 0
  return $pres
}

function Close-VideoDeck($pres, [switch]$KeepPowerPoint) {
  $pres.Close()
  if (-not $KeepPowerPoint -and $VX.App -and $VX.App.Presentations.Count -eq 0) { $VX.App.Quit(); $VX.App = $null }
}

# ---------------------------------------------------------------- animation (sequential model)
function Fx($slide, $shape, $effect, $trigger = $AFTER, $dur = 0.5, $delay = 0, [switch]$Exit, $dir = 0) {
  $e = $slide.TimeLine.MainSequence.AddEffect($shape, $effect, 0, $trigger)
  if ($Exit) { $e.Exit = -1 }
  if ($dir) { try { $e.EffectParameters.Direction = $dir } catch {} }
  # Duration and TriggerDelayTime must be [single], or the call throws "Specified cast is not valid"
  $e.Timing.Duration = [single]$dur
  $e.Timing.TriggerDelayTime = [single]$delay
  if ($trigger -eq $WITH) { $start = $script:VxLastStart + $delay } else { $start = $script:VxClock + $delay; $script:VxLastStart = $start }
  $script:VxClock = [Math]::Max($script:VxClock, $start + $dur)
  return $e
}

# Fade in while drifting into place from (dx, dy) pt away: kinetic text and card entrances
function Rise($slide, $shape, $trigger = $WITH, $delay = 0, $dur = 0.6, $dy = 14, $dx = 0) {
  $e = Fx $slide $shape $FADE $trigger $dur $delay
  $b = $e.Behaviors.Add(1)
  $b.MotionEffect.Path = ('M {0:0.#####} {1:0.#####} L 0 0 E' -f (-$dx / $VX.W), ($dy / $VX.H))
  $b.Timing.Duration = [single]$dur
  $e.Timing.Decelerate = [single]0.8
  return $e
}

# Move a shape by (dx, dy) pt along a straight eased path: slider knobs, cursors, dragged fields
function Slide-Knob($slide, $shape, $dxPt, $dyPt, $trigger = $AFTER, $dur = 1.2, $delay = 0) {
  $e = Fx $slide $shape $CUSTOM $trigger $dur $delay
  $b = $e.Behaviors.Add(1)
  $b.MotionEffect.Path = ('M 0 0 L {0:0.#####} {1:0.#####} E' -f ($dxPt / $VX.W), ($dyPt / $VX.H))
  $e.Timing.SmoothStart = -1; $e.Timing.SmoothEnd = -1
  return $e
}

function Hold($seconds) { $script:VxClock += $seconds }

# ---------------------------------------------------------------- animation (absolute model)
function FxAt($slide, $shape, $effect, $at, $dur = 0.4, [switch]$Exit, $dir = 0, [switch]$Smooth) {
  $e = $slide.TimeLine.MainSequence.AddEffect($shape, $effect, 0, $WITH)
  if ($Exit) { $e.Exit = -1 }
  if ($dir) { try { $e.EffectParameters.Direction = $dir } catch {} }
  $e.Timing.Duration = [single][Math]::Max(0.01, $dur)
  $e.Timing.TriggerDelayTime = [single][Math]::Max(0, $at)
  if ($Smooth) { try { $e.Timing.SmoothEnd = -1 } catch {} }
  return $e
}

# ---------------------------------------------------------------- slides
function Set-SlideBackground($slide, $from, $to = $null, [int]$style = 3) {
  $slide.FollowMasterBackground = 0
  if ($null -eq $to) { $slide.Background.Fill.Solid(); $slide.Background.Fill.ForeColor.RGB = $from; return }
  $slide.Background.Fill.TwoColorGradient($style, 1)   # 1 = horizontal, 3 = diagonal up
  $slide.Background.Fill.ForeColor.RGB = $from; $slide.Background.Fill.BackColor.RGB = $to
}

function New-VideoSlide($pres, [double]$FadeIn = 0.5) {
  $s = $pres.Slides.Add($pres.Slides.Count + 1, 12)   # ppLayoutBlank
  Set-SlideBackground $s $VX.Palette.bg1 $VX.Palette.bg2
  if ($FadeIn -gt 0) { $s.SlideShowTransition.EntryEffect = 3849; $s.SlideShowTransition.Duration = [single]$FadeIn }   # fade smoothly
  $script:VxClock = 0.0; $script:VxLastStart = 0.0
  return $s
}

# Sets how long the slide stays up: its animations plus $hold seconds. With $VX.SceneLen set (voiceover
# timing per scene, including the fade), the slide is stretched to its voice slot, and a warning is
# printed when the animations run longer than the slot.
function Complete-Slide($slide, $hold = 1.2, [double]$FadeIn = 0.5) {
  $tr = $slide.SlideShowTransition
  $tr.AdvanceOnClick = 0; $tr.AdvanceOnTime = -1
  $len = $script:VxClock + $hold
  if (-not $VX.NoAudio -and $VX.SceneLen -and $script:VxScene -lt $VX.SceneLen.Count) {
    $target = $VX.SceneLen[$script:VxScene] - $FadeIn
    if ($script:VxClock -gt $target + 0.01) { Write-Warning ('Scene {0}: animations run {1:0.00}s, longer than its {2:0.00}s voice slot' -f ($script:VxScene + 1), $script:VxClock, $target) }
    $len = [Math]::Max($script:VxClock, $target)
  }
  $tr.AdvanceTime = [single]([Math]::Ceiling($len * 100) / 100)
  $script:VxScene++
}

# ---------------------------------------------------------------- shapes and text
function Add-Shape($slide, $l, $t, $w, $h, $fill, $type = 1, $line = $null, $lineW = 0, $round = 0.2) {
  $s = $slide.Shapes.AddShape($type, $l, $t, $w, $h)
  if ($null -eq $fill) { $s.Fill.Visible = 0 } else { $s.Fill.Solid(); $s.Fill.ForeColor.RGB = $fill }
  if ($null -eq $line) { $s.Line.Visible = 0 } else { $s.Line.Visible = -1; $s.Line.ForeColor.RGB = $line; $s.Line.Weight = [single]$lineW }
  if ($type -eq 5) { $s.Adjustments.Item(1) = [single]$round }
  $s.Shadow.Visible = 0
  $s.TextFrame.TextRange.Text = ''
  return $s
}

function Set-SoftShadow($shape, $color = $null, [double]$blur = 22, [double]$dy = 6, [double]$transparency = 0.86) {
  $shape.Shadow.Visible = -1; $shape.Shadow.Blur = [single]$blur; $shape.Shadow.OffsetX = [single]0; $shape.Shadow.OffsetY = [single]$dy
  $shape.Shadow.ForeColor.RGB = $(if ($null -ne $color) { $color } else { $VX.Palette.primary }); $shape.Shadow.Transparency = [single]$transparency
}

# Floating white card with a soft tinted shadow
function Add-Card($slide, $l, $t, $w, $h, $round = 0.06) {
  $c = Add-Shape $slide $l $t $w $h $VX.Palette.white 5 $null 0 $round
  Set-SoftShadow $c
  return $c
}

function Add-Text($slide, $str, $l, $t, $w, $h, $size, $color, $weight = 'Regular', $align = 1, [switch]$Fit) {
  $tb = $slide.Shapes.AddTextbox(1, $l, $t, $w, $h)
  $tf = $tb.TextFrame
  $tf.MarginLeft = 0; $tf.MarginRight = 0; $tf.MarginTop = 0; $tf.MarginBottom = 0
  if ($Fit) { $tf.WordWrap = 0; $tf.AutoSize = 1 } else { $tf.WordWrap = -1; $tf.AutoSize = 0 }
  $r = $tf.TextRange
  $r.Text = $str; $r.Font.Size = [single]$size; $r.Font.Color.RGB = $color   # sizes like 10.5 need [single]
  switch ($weight) {
    'Bold' { $r.Font.Name = $VX.Font; $r.Font.Bold = -1 }
    'Semibold' { $r.Font.Name = $VX.FontSemi }
    'Black' { $r.Font.Name = $VX.FontBlack }
    default { $r.Font.Name = $VX.Font }
  }
  $r.ParagraphFormat.Alignment = $align   # 1 left, 2 centre, 3 right
  $tf.VerticalAnchor = 1
  return $tb
}

# Icon from the Segoe Fluent Icons font (code point, e.g. 0xE73E check), centred in a $box square
function Add-Glyph($slide, $code, $l, $t, $size, $box, $color) {
  $g = Add-Text $slide ([string][char]$code) $l ($t + $size * 0.28) $box $box $size $color 'Regular' 2
  $g.TextFrame.TextRange.Font.Name = $VX.Icons
  $g.TextFrame.VerticalAnchor = 3
  return $g
}

# Rounded pill with a centred label. With -Auto the pill sizes itself to the text.
function Add-Pill($slide, $str, $l, $t, $w, $h, $fill, $color, $size = 13, $weight = 'Semibold', $line = $null, [switch]$Auto, $padX = 14, $padY = 6) {
  $p = Add-Shape $slide $l $t $w $h $fill 5 $line 1.25 0.5
  $tf = $p.TextFrame; $tf.WordWrap = 0
  $tf.MarginLeft = $(if ($Auto) { $padX } else { 4 }); $tf.MarginRight = $tf.MarginLeft
  $tf.MarginTop = $(if ($Auto) { $padY } else { 0 }); $tf.MarginBottom = $tf.MarginTop
  $r = $tf.TextRange; $r.Text = $str; $r.Font.Size = [single]$size; $r.Font.Color.RGB = $color
  if ($weight -eq 'Bold') { $r.Font.Name = $VX.Font; $r.Font.Bold = -1 } else { $r.Font.Name = $VX.FontSemi }
  $r.ParagraphFormat.Alignment = 2; $tf.VerticalAnchor = 3
  if ($Auto) { $tf.AutoSize = 1; $p.Left = [single]$l; $p.Top = [single]$t }
  return $p
}

function Group-Shapes($slide, $shapes) { $slide.Shapes.Range([object[]]($shapes | ForEach-Object { $_.Name })).Group() }

# ---------------------------------------------------------------- images
# Pixel size of an image. WebP is read from its header (System.Drawing cannot open it); never guess sizes.
function Get-ImageSize([string]$file) {
  $file = Resolve-Asset $file
  if ($file -match '\.webp$') {
    $b = [IO.File]::ReadAllBytes($file)
    $fourcc = [Text.Encoding]::ASCII.GetString($b, 12, 4)
    switch ($fourcc) {
      'VP8 ' { return @((($b[26] -bor ($b[27] -shl 8)) -band 0x3FFF), (($b[28] -bor ($b[29] -shl 8)) -band 0x3FFF)) }
      'VP8L' { $bits = [uint32]$b[21] -bor ([uint32]$b[22] -shl 8) -bor ([uint32]$b[23] -shl 16) -bor ([uint32]$b[24] -shl 24)
        return @([int](($bits -band 0x3FFF) + 1), [int]((($bits -shr 14) -band 0x3FFF) + 1)) }
      'VP8X' { return @((1 + ($b[24] -bor ($b[25] -shl 8) -bor ($b[26] -shl 16))), (1 + ($b[27] -bor ($b[28] -shl 8) -bor ($b[29] -shl 16)))) }
      default { throw "Unknown WebP chunk '$fourcc' in $file" }
    }
  }
  Add-Type -AssemblyName System.Drawing
  $img = [Drawing.Image]::FromFile($file)
  try { return @($img.Width, $img.Height) } finally { $img.Dispose() }
}

# Places a screenshot in a framed card inside the content area. Returns a mapper (l, t, s, file, imgW, imgH)
# that converts image pixels to slide points, used by P, Box, Mask and Lens.
function Shot($slide, $file, $imgW = 0, $imgH = 0, $top = 116, $maxW = 880, $maxH = 384, $frameColor = $null) {
  $path = Resolve-Asset $file
  if (-not $imgW -or -not $imgH) { $sz = Get-ImageSize $path; $imgW = $sz[0]; $imgH = $sz[1] }
  $sc = [Math]::Min($maxW / $imgW, $maxH / $imgH)
  $w = $imgW * $sc; $h = $imgH * $sc; $l = ($VX.W - $w) / 2
  $frame = Add-Shape $slide ($l - 6) ($top - 6) ($w + 12) ($h + 12) $VX.Palette.white 5 $null 0 0.03
  Set-SoftShadow $frame $frameColor 18 4 0.82
  $pic = $slide.Shapes.AddPicture($path, 0, -1, $l, $top, $w, $h)
  return [pscustomobject]@{ pic = $pic; frame = $frame; l = $l; t = $top; s = $sc; file = $path; imgW = $imgW; imgH = $imgH }
}

function P($m, $x, $y) { @(($m.l + $x * $m.s), ($m.t + $y * $m.s)) }

# Glowing highlight box around an image-pixel region
function Box($slide, $m, $x1, $y1, $x2, $y2, $pad = 4, $color = $null) {
  $col = $(if ($null -ne $color) { $color } else { $VX.Palette.primary2 })
  $a = P $m $x1 $y1; $b = P $m $x2 $y2
  $s = Add-Shape $slide ($a[0] - $pad) ($a[1] - $pad) ($b[0] - $a[0] + 2 * $pad) ($b[1] - $a[1] + 2 * $pad) $null 5 $col 2.5 0.12
  $s.Glow.Color.RGB = $col; $s.Glow.Radius = [single]6; $s.Glow.Transparency = [single]0.55
  return $s
}

# Solid mask over an image-pixel region. Wipe it away (Fx ... -Exit) to "draw" a chart or reveal a result.
# Named MASK_* so Export-QAStills can hide it.
function Mask($slide, $m, $x1, $y1, $x2, $y2, $color) {
  $a = P $m $x1 $y1; $b = P $m $x2 $y2
  $r = Add-Shape $slide $a[0] $a[1] ($b[0] - $a[0]) ($b[1] - $a[1]) $color
  $r.Name = "MASK_$($r.Id)"
  return $r
}

# Magnified callout of an image-pixel region, centred at (cx, cy) slide pt, scaled by k relative to the shot
function Lens($slide, $m, $x1, $y1, $x2, $y2, $cx, $cy, $k = 1.5, $border = $null) {
  $w = ($x2 - $x1) * $m.s * $k; $h = ($y2 - $y1) * $m.s * $k
  # crop is measured against the picture's native size: insert at native size (-1, -1), crop, then resize
  $pic = $slide.Shapes.AddPicture($m.file, 0, -1, 0, 0, -1, -1)
  $u = $pic.Width / $m.imgW
  $pic.LockAspectRatio = 0
  $pic.PictureFormat.CropLeft = [single]($x1 * $u); $pic.PictureFormat.CropTop = [single]($y1 * $u)
  $pic.PictureFormat.CropRight = [single](($m.imgW - $x2) * $u); $pic.PictureFormat.CropBottom = [single](($m.imgH - $y2) * $u)
  $pic.Width = [single]$w; $pic.Height = [single]$h
  $pic.Left = [single]($cx - $w / 2); $pic.Top = [single]($cy - $h / 2)
  $pic.Line.Visible = -1; $pic.Line.ForeColor.RGB = $(if ($null -ne $border) { $border } else { $VX.Palette.primary2 }); $pic.Line.Weight = [single]2
  $pic.Shadow.Visible = -1; $pic.Shadow.Blur = [single]24; $pic.Shadow.OffsetY = [single]6; $pic.Shadow.Transparency = [single]0.7
  return $pic
}

# ---------------------------------------------------------------- audio
# Sound effects: $VX.Sfx['click'] = @{ file = 'sfx\click.mp3'; from = 120; to = 400; vol = 0.8 }
# (from/to in ms trim the file's leading silence; levels sit under the voiceover).
# Sfx plays a sound together with the effect just added ($fx must be the last effect in the sequence).
# The media sits off-slide (Left 1000+) so its icon never shows. Never touch AnimationSettings for SFX.
function Sfx($slide, $name, $fx, $offset = 0) {
  if ($VX.NoAudio) { return }
  $c = $VX.Sfx[$name]
  if (-not $c) { Write-Warning "No SFX named '$name' in `$VX.Sfx"; return }
  $m = $slide.Shapes.AddMediaObject2((Resolve-Asset $c.file), 0, -1, $VX.W + 40, 10, 20, 20)
  $m.Name = "SFX_${name}_$($m.Id)"
  $m.MediaFormat.StartPoint = [int]$c.from; $m.MediaFormat.EndPoint = [int]$c.to; $m.MediaFormat.Volume = [single]$c.vol
  $e = $slide.TimeLine.MainSequence.AddEffect($m, $PLAY, 0, $WITH)
  $base = $(if ($fx) { $fx.Timing.TriggerDelayTime } else { 0 })
  $e.Timing.TriggerDelayTime = [single]($base + $offset)
  return $e
}

# One voiceover track that starts with slide 1 and plays across $slideCount slides.
# MUST be called before any other effect is added to slide 1: touching AnimationSettings on a slide that
# already has effects rewrites them all as sequential 0.5 s "Appear" steps.
function Add-Voiceover($slide, $file, [int]$slideCount) {
  if ($slide.TimeLine.MainSequence.Count -gt 0) { throw 'Add-Voiceover must run before any other effect is added to this slide.' }
  $vo = $slide.Shapes.AddMediaObject2((Resolve-Asset $file), 0, -1, $VX.W + 40, $VX.H - 40, 24, 24)
  $vo.Name = 'voiceover'
  $ps = $vo.AnimationSettings.PlaySettings
  $ps.PlayOnEntry = -1; $ps.HideWhileNotPlaying = -1; $ps.StopAfterSlides = $slideCount
  $e = $slide.TimeLine.MainSequence.Item(1)
  $e.Timing.TriggerType = $WITH; $e.Timing.TriggerDelayTime = [single]0
  return $vo
}

# ---------------------------------------------------------------- footage
# Local working copies of media files. Use for files in cloud-synced folders (PowerPoint intermittently
# fails to reopen them) and for overlapping clips: PowerPoint will not play two instances of the SAME
# file on one slide, so each overlapping clip needs its own copy. Returns the list of copy paths.
function Copy-MediaPool([string]$file, [int]$copies = 1, [string]$dir) {
  if (-not $dir) { $dir = Join-Path $env:TEMP 'ppt-video-media' }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $base = [IO.Path]::GetFileNameWithoutExtension($file); $ext = [IO.Path]::GetExtension($file)
  $len = (Get-Item -LiteralPath $file).Length
  $out = @()
  for ($i = 1; $i -le $copies; $i++) {
    $dst = Join-Path $dir $(if ($i -eq 1) { "$base$ext" } else { "${base}_$i$ext" })
    if (-not (Test-Path -LiteralPath $dst) -or (Get-Item -LiteralPath $dst).Length -ne $len) { Copy-Item -LiteralPath $file -Destination $dst -Force }
    $out += $dst
  }
  return $out
}

# Linked video trimmed to [t0, t0+dur] seconds, cropped, and fitted into box l,t,w,h.
# Crop: @(x, y, w, h) in source pixels with -SrcW (source width px), or in 0..1 fractions without it.
# -Fit contain keeps the aspect ratio inside the box; cover trims the crop to the box's aspect and fills it;
# stretch fills the box as-is (only when the crop already has the box's aspect).
function Add-LinkedVideo($slide, $file, $t0, $dur, $l, $t, $w, $h, $crop = $null, $SrcW = 0, [ValidateSet('contain', 'cover', 'stretch')]$Fit = 'contain', [switch]$Mute, $round = 0.06) {
  $v = $null
  for ($try = 1; $try -le 4 -and $null -eq $v; $try++) {
    try { $v = $slide.Shapes.AddMediaObject2($file, -1, 0, 0, 0, -1, -1) }
    catch { Write-VideoLog "AddMediaObject2 retry $try ($file): $_"; if ($try -eq 4) { throw }; Start-Sleep 3 }
  }
  # inserted media is shrunk to fit the slide, but crop is measured at original size: reset scale first
  $v.ScaleHeight(1, -1); $v.ScaleWidth(1, -1)
  $nw = $v.Width; $nh = $v.Height
  if ($crop) {
    if ($SrcW -gt 0) { $k = $nw / $SrcW; $cx = $crop[0] * $k; $cy = $crop[1] * $k; $cw = $crop[2] * $k; $ch = $crop[3] * $k }
    else { $cx = $crop[0] * $nw; $cy = $crop[1] * $nh; $cw = $crop[2] * $nw; $ch = $crop[3] * $nh }
  } else { $cx = 0; $cy = 0; $cw = $nw; $ch = $nh }
  if ($Fit -eq 'cover') {
    # trim the crop to the box's aspect ratio: centred horizontally, biased upward vertically (keeps heads in frame)
    $aspect = $w / $h
    if ($cw / $ch -gt $aspect) { $ncw = $ch * $aspect; $cx += ($cw - $ncw) / 2; $cw = $ncw }
    else { $nch = $cw / $aspect; $cy += ($ch - $nch) * 0.35; $ch = $nch }
  }
  $v.LockAspectRatio = 0
  $v.PictureFormat.CropLeft = [single]$cx; $v.PictureFormat.CropTop = [single]$cy
  $v.PictureFormat.CropRight = [single]($nw - $cx - $cw); $v.PictureFormat.CropBottom = [single]($nh - $cy - $ch)
  if ($Fit -ne 'contain') { $vw = $w; $vh = $h } else { $sc = [Math]::Min($w / $cw, $h / $ch); $vw = $cw * $sc; $vh = $ch * $sc }
  $v.Width = [single]$vw; $v.Height = [single]$vh
  $v.Left = [single]($l + ($w - $vw) / 2); $v.Top = [single]($t + ($h - $vh) / 2)
  $v.MediaFormat.StartPoint = [int]($t0 * 1000); $v.MediaFormat.EndPoint = [int](($t0 + $dur) * 1000)
  if ($Mute) { $v.MediaFormat.Muted = -1 }
  $v.AutoShapeType = 5; $v.Adjustments.Item(1) = [single]$round
  return $v
}

# ---------------------------------------------------------------- output
# End-state stills of every slide for layout QA, with MASK_* shapes hidden (static export shows them).
function Export-QAStills($pres, [string]$dir, [int]$pxW = 0, [int]$pxH = 0) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if (-not $pxW) { $pxW = [int]($VX.W * 2); $pxH = [int]($VX.H * 2) }
  foreach ($sl in $pres.Slides) {
    $hidden = @(); foreach ($sh in $sl.Shapes) { if ($sh.Name -like 'MASK_*') { $sh.Visible = 0; $hidden += $sh } }
    $sl.Export((Join-Path $dir ('scene{0}.png' -f $sl.SlideIndex)), 'PNG', $pxW, $pxH)
    foreach ($sh in $hidden) { $sh.Visible = -1 }
  }
}

function Get-DeckRuntime($pres) {
  $total = 0.0
  foreach ($sl in $pres.Slides) { $total += $sl.SlideShowTransition.AdvanceTime + $sl.SlideShowTransition.Duration }
  return $total
}

# CreateVideo wrapper. -Height is the vertical resolution: 1080 for a 960x540 deck, 1920 for 540x960.
# Waits for the render and returns the final status (3 = done, 4 = failed).
# CreateVideo writes MP4 only: a .gif name still produces an MP4 (export GIFs from the PowerPoint UI).
function Export-Video($pres, [string]$mp4, [int]$Height = 1080, [int]$Fps = 30, [int]$Quality = 90, [int]$DefaultSlideSec = 5, [int]$TimeoutSec = 2400) {
  if ($mp4 -match '\.gif$') { throw 'CreateVideo cannot write GIF. Render an .mp4 and export a GIF from PowerPoint (File > Export).' }
  if (Test-Path -LiteralPath $mp4) {
    # CreateVideo fails with E_FAIL if the old file is held open (a player, a QA web server)
    try { Remove-Item -LiteralPath $mp4 -Force -ErrorAction Stop } catch { throw "Cannot replace $mp4. Close whatever has it open (player, QA server) and retry." }
  }
  $pres.CreateVideo($mp4, $true, $DefaultSlideSec, $Height, $Fps, $Quality)
  $t0 = Get-Date
  while (@(1, 2) -contains $pres.CreateVideoStatus) {   # 1 in progress, 2 queued
    Start-Sleep -Seconds 2
    if (((Get-Date) - $t0).TotalSeconds -gt $TimeoutSec) { Write-VideoLog 'render timeout'; break }
  }
  $st = $pres.CreateVideoStatus
  Write-VideoLog ('render status {0} after {1}s' -f $st, [int]((Get-Date) - $t0).TotalSeconds)
  return $st
}
