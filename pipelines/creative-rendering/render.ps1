<#
.SYNOPSIS
  Renders an HTML page (or several #fragment "slides" of one page) to PNG, and optionally to PDF,
  with headless Microsoft Edge. No Node, Python or design app needed.

.EXAMPLE
  .\render.ps1 -Html creatives\launch\post.html -Width 1200 -Height 627
  .\render.ps1 -Html carousel.html -Ids s1,s2,s3 -Prefix carousel -Out png -Scale 2 -Pdf carousel.pdf
  .\render.ps1 -Html carousel.html -Ids s1,s2,s3 -Scale 1,2      # 1x and 2x of every slide

.NOTES
  - Relative paths resolve against the current directory.
  - With -Ids, the page is loaded once per id as page.html#id; the page CSS decides what a fragment shows
    (see templates\example-creative.html). Without -Ids, one screenshot of the whole viewport is taken.
  - -Out is a .png file path for a single render, or a folder when -Ids or several -Scale values are given.
  - Output names: <prefix>-<id>.png at scale 1, <prefix>-<id>@2x.png at scale 2.
  - Two silent-failure traps are guarded here: the file:/// URL is always built from a full Windows path
    with forward slashes (an MSYS /c/... path renders a blank error page), and identical byte sizes across
    different slides are reported because that is the tell of a blank render.
#>
param(
  [Parameter(Mandatory = $true)][string]$Html,
  [string]$Out,
  [int]$Width = 1080,
  [int]$Height = 1350,
  [int[]]$Scale = @(2),
  [string[]]$Ids,
  [string]$Prefix,
  [string]$Pdf,
  [switch]$PdfOnly,
  [int]$BudgetMs = 4000,
  [int]$TimeoutSec = 60,
  [string]$Edge
)
$ErrorActionPreference = 'Stop'

function Find-Edge {
  $cands = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe')
  )
  foreach ($c in $cands) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
  foreach ($hive in 'HKLM:', 'HKCU:') {
    try {
      $p = (Get-ItemProperty "$hive\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" -ErrorAction Stop).'(default)'
      if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    } catch {}
  }
  throw 'Microsoft Edge (msedge.exe) not found. Pass -Edge <path to msedge.exe>.'
}

function Get-FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }

# file:///C:/forward/slash/path.html - built from the full Windows path, never from an MSYS-style path
function Get-FileUrl([string]$fullPath) { ([Uri]$fullPath).AbsoluteUri }

function Invoke-Edge([string[]]$argList, [string]$expect) {
  if (Test-Path -LiteralPath $expect) { Remove-Item -LiteralPath $expect -Force }
  $p = Start-Process -FilePath $script:EdgeExe -ArgumentList $argList -PassThru -WindowStyle Hidden
  # Edge can linger after writing the file, so wait for the file rather than for the process alone
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if ($p.HasExited -and (Test-Path -LiteralPath $expect)) { break }
    if ((Test-Path -LiteralPath $expect) -and (Get-Item -LiteralPath $expect).Length -gt 0) { Start-Sleep -Milliseconds 300; break }
    Start-Sleep -Milliseconds 200
  }
  if (-not $p.HasExited) { try { $p | Wait-Process -Timeout 5 -ErrorAction Stop } catch { try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {} } }
  if (Test-Path -LiteralPath $expect) { return (Get-Item -LiteralPath $expect).Length }
  Write-Warning "No output written: $expect"
  return 0
}

$script:EdgeExe = $(if ($Edge) { $Edge } else { Find-Edge })
$htmlFull = Get-FullPath $Html
if (-not (Test-Path -LiteralPath $htmlFull)) { throw "HTML not found: $htmlFull" }
$htmlDir = Split-Path -Parent $htmlFull
$url = Get-FileUrl $htmlFull
if (-not $Prefix) { $Prefix = [IO.Path]::GetFileNameWithoutExtension($htmlFull) }

$multi = ($Ids -and $Ids.Count -gt 0) -or $Scale.Count -gt 1
if (-not $Out) { $Out = $(if ($multi) { $htmlDir } else { Join-Path $htmlDir "$Prefix.png" }) }
$outFull = Get-FullPath $Out
if ($multi -or -not $outFull.ToLower().EndsWith('.png')) {
  $outDir = $outFull; $single = $null
} else {
  $outDir = Split-Path -Parent $outFull; $single = $outFull
}
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$targets = $(if ($PdfOnly) { @() } elseif ($Ids) { $Ids } else { @('') })
$sizes = @{}
foreach ($id in $targets) {
  foreach ($sc in $Scale) {
    $suffix = $(if ($sc -eq 1) { '' } else { "@${sc}x" })
    $name = $(if ($id) { "$Prefix-$id$suffix.png" } else { "$Prefix$suffix.png" })
    $png = $(if ($single) { $single } else { Join-Path $outDir $name })
    $u = $(if ($id) { "$url#$id" } else { $url })
    $argList = @('--headless=new', '--disable-gpu', '--hide-scrollbars', "--force-device-scale-factor=$sc",
      "--virtual-time-budget=$BudgetMs", "--window-size=$Width,$Height", "--screenshot=`"$png`"", "`"$u`"")
    $len = Invoke-Edge $argList $png
    '{0}  {1:N0} bytes' -f (Split-Path $png -Leaf), $len
    if ($id -and $len -gt 0) {
      $key = "$sc|$len"
      if ($sizes.ContainsKey($key)) { Write-Warning "$name has the same byte size as $($sizes[$key]). Check it is not a blank or error page." }
      else { $sizes[$key] = $name }
    }
  }
}

if ($Pdf) {
  $pdfPath = Get-FullPath $Pdf
  if (-not [IO.Path]::IsPathRooted($Pdf)) { $pdfPath = Join-Path $outDir $Pdf }
  $argList = @('--headless=new', '--disable-gpu', '--no-pdf-header-footer', "--virtual-time-budget=$BudgetMs",
    "--print-to-pdf=`"$pdfPath`"", "`"$url`"")
  $len = Invoke-Edge $argList $pdfPath
  '{0}  {1:N0} bytes' -f (Split-Path $pdfPath -Leaf), $len
}
