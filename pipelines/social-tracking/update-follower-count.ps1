<#
.SYNOPSIS
  Appends this week's follower counts to the social follower tracker workbook, one sheet per page,
  without Excel COM. Keep this file plain ASCII.

.DESCRIPTION
  Each page has its own sheet with this layout (data from row 2):
    A = Date (Monday of the week, usually pre-filled weeks ahead)
    B = Followers
    C = % Growth WoW, formula =(B{row}-B{prevRow})/B{row}*100
        (it divides by the current row, not the previous one; that is the sheet's convention, kept as-is)
    D = Posts that week (optional)

  For each page the script finds the row after the last row that has a Followers value and writes
  B, C (with a matching cached value, so it displays correctly without a recalc) and, if given, D.
  Styles for B, C and D are copied from the previous filled row.

  It edits the .xlsx as a zip archive and rewrites only the worksheet parts it changes. Styles,
  shared strings, other sheets and data connections stay byte-for-byte untouched. This is on
  purpose: Excel COM can hang on workbooks with live data connections (an invisible "data
  connection" prompt), and some labelled files refuse COM opens altogether.

  Safety: it refuses to overwrite a row that already has a Followers value, so a re-run is safe.
  If the next row does not exist yet (Date column not pre-filled that far), it stops unless you
  pass -AddMissingRow, which creates the row with the Monday of the current week in column A.
  Close the workbook in Excel before running; a synced file should be fully synced first.

.PARAMETER Counts
  Hashtable of page name -> follower count, e.g. @{ 'Company' = 16600; 'Product' = 5950 }.
.PARAMETER Posts
  Optional hashtable of page name -> post count for the week (column D).
.PARAMETER Page
  Single page name (alternative to -Counts).
.PARAMETER Count
  Follower count for -Page.
.PARAMETER PostCount
  Optional post count for -Page.
.PARAMETER SheetMap
  Optional hashtable of page name -> sheet name, when the sheet is not named after the page.
.PARAMETER TrackerPath
  The workbook. Defaults to <Root>\trackers\Social Media Followers.xlsx (see config/paths.md).
.PARAMETER Root
  Marketing root. Defaults to $env:MARKETING_ROOT, then the repo root.
.PARAMETER WhatIf
  Show what would be written without changing the file.

.EXAMPLE
  .\update-follower-count.ps1 -Counts @{ 'Company' = 16600; 'Product' = 5950 }
.EXAMPLE
  .\update-follower-count.ps1 -Page 'Company' -Count 16600 -PostCount 3
.EXAMPLE
  .\update-follower-count.ps1 -Counts @{ 'Company' = 16600 } -SheetMap @{ 'Company' = 'Corporate page' }
#>
param(
  [hashtable]$Counts,
  [hashtable]$Posts,
  [string]$Page,
  [int]$Count = -1,
  [int]$PostCount = -1,
  [hashtable]$SheetMap,
  [string]$TrackerPath,
  [string]$Root,
  [switch]$AddMissingRow,
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not $Root) { $Root = $env:MARKETING_ROOT }
if (-not $Root) { $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
if (-not $TrackerPath) { $TrackerPath = Join-Path $Root 'trackers\Social Media Followers.xlsx' }
elseif (-not [System.IO.Path]::IsPathRooted($TrackerPath)) { $TrackerPath = Join-Path $Root $TrackerPath }
if (-not (Test-Path -LiteralPath $TrackerPath)) { throw "Workbook not found: $TrackerPath" }

$work = [ordered]@{}
if ($Counts) { foreach ($k in $Counts.Keys) { $work[[string]$k] = @{ Followers=[int]$Counts[$k]; Posts=$null } } }
if ($Page) {
  if ($Count -lt 0) { throw 'Pass -Count with -Page' }
  $work[$Page] = @{ Followers=$Count; Posts=$null }
  if ($PostCount -ge 0) { $work[$Page].Posts = $PostCount }
}
if ($Posts) { foreach ($k in $Posts.Keys) { if ($work.Contains([string]$k)) { $work[[string]$k].Posts = [int]$Posts[$k] } else { throw "Posts given for '$k' but no follower count" } } }
if ($work.Count -eq 0) { throw 'Pass -Counts @{ PageName = count } or -Page NAME -Count N' }

$nsMain = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
$nsRel  = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'

function Read-Entry($zip, [string]$name) {
  $e = $zip.GetEntry($name); if (-not $e) { throw "$name not found inside workbook" }
  $s = $e.Open(); $r = New-Object System.IO.StreamReader($s, [System.Text.Encoding]::UTF8)
  $t = $r.ReadToEnd(); $r.Close(); $s.Close(); return $t
}
function Write-Entry($zip, [string]$name, [string]$text) {
  $zip.GetEntry($name).Delete()
  $e = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
  $s = $e.Open(); $w = New-Object System.IO.StreamWriter($s, (New-Object System.Text.UTF8Encoding($false)))
  $w.Write($text); $w.Close(); $s.Close()
}

function Get-SheetParts($zip) {
  # sheet name -> zip part path, via xl/workbook.xml + xl/_rels/workbook.xml.rels
  [xml]$wbx = Read-Entry $zip 'xl/workbook.xml'
  [xml]$rels = Read-Entry $zip 'xl/_rels/workbook.xml.rels'
  $relMap = @{}; foreach ($r in $rels.Relationships.Relationship) { $relMap[$r.Id] = $r.Target }
  $map = @{}
  foreach ($s in $wbx.workbook.sheets.sheet) {
    $rid = $s.GetAttribute('id', $nsRel)
    $target = $relMap[$rid]
    if ($target.StartsWith('/')) { $part = $target.TrimStart('/') } else { $part = 'xl/' + $target }
    $map[$s.name] = $part
  }
  return $map
}

function Get-CellXml([string]$rowInner, [string]$col) {
  $m = [regex]::Match($rowInner, '<c r="' + $col + '\d+"[^>]*?(/>|>.*?</c>)', 'Singleline')
  if ($m.Success) { return $m.Value } return $null
}
function Get-CellValue([string]$cellXml) {
  if (-not $cellXml) { return $null }
  $m = [regex]::Match($cellXml, '<v>([^<]*)</v>')
  if ($m.Success -and $m.Groups[1].Value -ne '') { return $m.Groups[1].Value } return $null
}
function Get-CellStyle([string]$cellXml) {
  if (-not $cellXml) { return '' }
  $m = [regex]::Match($cellXml, ' s="(\d+)"'); if ($m.Success) { return ' s="' + $m.Groups[1].Value + '"' } return ''
}
function Get-ColNum([string]$letters) { $n = 0; foreach ($ch in $letters.ToCharArray()) { $n = $n * 26 + ([int][char]$ch - 64) }; return $n }

function Update-Sheet([string]$content, [string]$label, [int]$followers, $posts) {
  $rows = [regex]::Matches($content, '<row r="(\d+)"([^>]*?)(/>|>(.*?)</row>)', 'Singleline')
  $lastNum = 0; $lastB = $null; $lastInner = ''
  foreach ($m in $rows) {
    $v = Get-CellValue (Get-CellXml $m.Groups[4].Value 'B')
    $n = 0
    if ($v -and [double]::TryParse($v, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$n)) {
      $lastNum = [int]$m.Groups[1].Value; $lastB = $n; $lastInner = $m.Groups[4].Value
    }
  }
  if ($null -eq $lastB) { throw "${label}: no existing Followers value in column B. Enter the first week by hand in Excel." }
  $target = $lastNum + 1
  $styleB = Get-CellStyle (Get-CellXml $lastInner 'B')
  $styleC = Get-CellStyle (Get-CellXml $lastInner 'C')
  $styleD = Get-CellStyle (Get-CellXml $lastInner 'D')
  $growth = ($followers - $lastB) / $followers * 100
  $inv = [System.Globalization.CultureInfo]::InvariantCulture
  $newCells = @{
    'B' = '<c r="B' + $target + '"' + $styleB + '><v>' + $followers + '</v></c>'
    'C' = '<c r="C' + $target + '"' + $styleC + '><f>(B' + $target + '-B' + $lastNum + ')/B' + $target + '*100</f><v>' + $growth.ToString('R', $inv) + '</v></c>'
  }
  if ($null -ne $posts) { $newCells['D'] = '<c r="D' + $target + '"' + $styleD + '><v>' + $posts + '</v></c>' }

  $rm = [regex]::Match($content, '<row r="' + $target + '"([^>]*?)(/>|>(.*?)</row>)', 'Singleline')
  if ($rm.Success) {
    $inner = $rm.Groups[3].Value
    foreach ($col in @($newCells.Keys)) {
      $existing = Get-CellXml $inner $col
      if ($col -eq 'B' -and (Get-CellValue $existing)) { throw "${label}: row $target already has a Followers value - refusing to overwrite. Check the sheet." }
      if ($col -ne 'B' -and ((Get-CellValue $existing) -or ($existing -match '<f>'))) { throw "${label}: row $target column $col already has a value - refusing to overwrite." }
    }
    $attrs = $rm.Groups[1].Value -replace '\s+spans="[^"]*"', ''
  } else {
    if (-not $AddMissingRow) { throw "${label}: row $target does not exist (Date column not pre-filled that far). Add dates in Excel, or re-run with -AddMissingRow." }
    $monday = (Get-Date).Date; while ($monday.DayOfWeek -ne [DayOfWeek]::Monday) { $monday = $monday.AddDays(-1) }
    $styleA = Get-CellStyle (Get-CellXml $lastInner 'A')
    $inner = '<c r="A' + $target + '"' + $styleA + '><v>' + [int]$monday.ToOADate() + '</v></c>'
    $attrs = ''
  }

  $rowDate = ''; $av = Get-CellValue (Get-CellXml $inner 'A'); $dn = 0
  if ($av -and [double]::TryParse($av, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$dn)) { $rowDate = [DateTime]::FromOADate($dn).ToString('yyyy-MM-dd') }

  # Merge cells in column order; drop empty placeholder cells for the columns being written.
  $cells = New-Object System.Collections.Generic.List[object]
  foreach ($cm in [regex]::Matches($inner, '<c r="([A-Z]+)\d+"[^>]*?(/>|>.*?</c>)', 'Singleline')) {
    $L = $cm.Groups[1].Value
    if (-not $newCells.ContainsKey($L)) { $cells.Add(@{ Col=(Get-ColNum $L); Xml=$cm.Value }) }
  }
  foreach ($L in $newCells.Keys) { $cells.Add(@{ Col=(Get-ColNum $L); Xml=$newCells[$L] }) }
  $merged = ($cells | Sort-Object { $_.Col } | ForEach-Object { $_.Xml }) -join ''
  $newRow = '<row r="' + $target + '"' + $attrs + '>' + $merged + '</row>'

  if ($rm.Success) {
    $content = $content.Substring(0, $rm.Index) + $newRow + $content.Substring($rm.Index + $rm.Length)
  } else {
    # insert after the last row with a lower number
    $after = $null
    foreach ($m in [regex]::Matches($content, '<row r="(\d+)"[^>]*?(/>|>.*?</row>)', 'Singleline')) { if ([int]$m.Groups[1].Value -lt $target) { $after = $m } }
    if ($after) { $pos = $after.Index + $after.Length } else { $pos = $content.IndexOf('<sheetData>') + '<sheetData>'.Length }
    $content = $content.Substring(0, $pos) + $newRow + $content.Substring($pos)
  }
  return @{ Content=$content; Result=[pscustomobject]@{ Sheet=$label; Row=$target; Date=$rowDate; PrevFollowers=[int]$lastB; NewFollowers=$followers; GrowthPct=$growth } }
}

$results = @()
$fs = [System.IO.File]::Open($TrackerPath, [System.IO.FileMode]::Open, $(if ($WhatIf) { [System.IO.FileAccess]::Read } else { [System.IO.FileAccess]::ReadWrite }))
try {
  $mode = $(if ($WhatIf) { [System.IO.Compression.ZipArchiveMode]::Read } else { [System.IO.Compression.ZipArchiveMode]::Update })
  $zip = New-Object System.IO.Compression.ZipArchive($fs, $mode)
  try {
    $parts = Get-SheetParts $zip
    # Validate every page before writing anything.
    $plan = @()
    foreach ($pg in $work.Keys) {
      $sheet = $pg; if ($SheetMap -and $SheetMap.ContainsKey($pg)) { $sheet = [string]$SheetMap[$pg] }
      if (-not $parts.ContainsKey($sheet)) { throw "No sheet named '$sheet' in the workbook (sheets: $(@($parts.Keys) -join ', ')). Nothing was changed." }
      $u = Update-Sheet (Read-Entry $zip $parts[$sheet]) $sheet $work[$pg].Followers $work[$pg].Posts
      $plan += @{ Part=$parts[$sheet]; Update=$u }
    }
    $seen = @{}; foreach ($p in $plan) { if ($seen.ContainsKey($p.Part)) { throw "Two pages map to the same sheet. Nothing was changed." }; $seen[$p.Part] = 1 }
    foreach ($p in $plan) {
      if (-not $WhatIf) { Write-Entry $zip $p.Part $p.Update.Content }
      $results += $p.Update.Result
    }
  } finally { $zip.Dispose() }
} finally { $fs.Close() }

foreach ($r in $results) {
  $sign = if ($r.GrowthPct -ge 0) { '+' } else { '' }
  $prefix = if ($WhatIf) { 'WHATIF ' } else { '' }
  Write-Output ("{0}{1}: row {2} (week of {7}) | {3} to {4} followers ({5}{6:N2} pct WoW)" -f $prefix, $r.Sheet, $r.Row, $r.PrevFollowers, $r.NewFollowers, $sign, $r.GrowthPct, $r.Date)
}
