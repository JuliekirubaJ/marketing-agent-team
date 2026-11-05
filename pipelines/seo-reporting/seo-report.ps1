<#
.SYNOPSIS
  Monthly / weekly SEO report helper for the sites in config\sites.csv. Excel COM, no other dependencies.

.ACTIONS
  Prep   -Month 2026-10 -Site <key>          (monthly)
  Prep   -Week  2026-10-05 -Site <key>       (weekly; the Monday label)
         Creates <root>\seo\_exports\<Month>\<Site>\ (with sf\ and screenshots\ subfolders), or
         <root>\seo\_exports\weekly\<Week>\<Site>\, and a manual-inputs.csv listing every metric in
         metrics.csv (weekly-metrics.csv for -Week) with a blank value column for the optional manual
         rows. Never overwrites an existing manual-inputs.csv.

  Build  -DataFile <report-data.json> -OutFile <report.xlsx>
         Builds the formatted workbook from the JSON the agent assembles.
         Suggested paths: <root>\seo\reports\<YYYY-MM>\<site>-report-data.json and
         <root>\seo\reports\<YYYY-MM>\<site>-seo-report-<YYYY-MM>.xlsx (weekly:
         <root>\seo\reports\weekly\<site>-seo-weekly-<label>.xlsx). Keep the JSON: the next run
         reads it for the period-over-period comparison.

.JSON SHAPE (Build)
  {
    "layout": "monthly" (default) | "weekly"  -> weekly = Weekly Summary + your sheets only,
    "site": "example.com", "month": "2026-10", "window": "2026-10-03 to 2026-10-30",
    "generated": "2026-10-31",
    "summary": ["headline 1", "headline 2"],
    "overview": [ { "group": "...", "metric": "...", "value": 123, "previous": 100,
                    "source": "ga4-channels.csv", "note": "", "better": "higher|lower" } ],
    "sheets": [ { "name": "Top Queries", "title": "optional caption",
                  "headers": ["Query","Clicks"], "rows": [["example query", 12]] } ],
    "screenshotsDir": "optional folder of .png/.jpg to embed on the GSC Screenshots sheet",
    "improvements": [ { "priority": "P1", "area": "Technical", "url": "", "issue": "",
                        "evidence": "", "fix": "", "owner": "", "effort": "", "status": "New" } ]
  }
  "value"/"previous" may be numbers, strings, or null (null prints "Awaiting data").
  "better" is optional; when omitted it is inferred from the metric name.
#>
param(
  [Parameter(Mandatory)][ValidateSet('Prep','Build')][string]$Action,
  [string]$Month,
  [string]$Week,
  [string]$Site,
  [string]$DataFile,
  [string]$OutFile,
  [string]$Root
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'seo-common.ps1')

function Test-Num($v) { return ($null -ne $v) -and ($v -is [ValueType]) -and -not ($v -is [bool]) }

if ($Action -eq 'Prep') {
  if ((-not $Month -and -not $Week) -or -not $Site) { throw 'Prep needs -Site and -Month YYYY-MM (or -Week YYYY-MM-DD)' }
  $null = Get-SeoSite $Root $Site   # validates the key against config\sites.csv
  $data = Get-SeoDataDir $Root
  if ($Week) {
    $dir = Join-Path $data "_exports\weekly\$Week\$Site"; $metricsFile = Join-Path $PSScriptRoot 'weekly-metrics.csv'
    New-Item -ItemType Directory -Force $dir | Out-Null
  } else {
    $dir = Join-Path $data "_exports\$Month\$Site"; $metricsFile = Join-Path $PSScriptRoot 'metrics.csv'
    foreach ($d in @($dir, "$dir\sf", "$dir\screenshots")) { New-Item -ItemType Directory -Force $d | Out-Null }
  }
  foreach ($d in @("$data\reports", "$data\rankings")) { New-Item -ItemType Directory -Force $d | Out-Null }
  $mi = Join-Path $dir 'manual-inputs.csv'
  if (Test-Path $mi) { "manual-inputs.csv already exists, left untouched: $mi" }
  else {
    Import-Csv $metricsFile |
      Select-Object group, metric, @{n='value';e={''}}, @{n='note';e={''}}, @{n='how_to_get';e={$_.how_to_get}} |
      Export-Csv $mi -NoTypeInformation -Encoding UTF8
    "Created $mi"
  }
  "Export folder ready: $dir"
  return
}

# ---------------- Build ----------------
if (-not $DataFile -or -not $OutFile) { throw 'Build needs -DataFile and -OutFile' }
$data = [System.IO.File]::ReadAllText($DataFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$lowerBetter = 'error|404|broken|lost|missing|duplicate|bounce|blocked|redirect|insecure|issue|warning|over 2s|load time|size|position|not indexed|canonical'

$navy = 0x5A3A1F    # BGR for Excel .Color  (RGB 1F3A5A)
$grey = 0xF2F2F2
$green = 0xCEEFC6; $red = 0xCEC7FF

function Write-Block($ws, [int]$row, [int]$col, $rows2d) {
  $r = $rows2d.GetLength(0); $c = $rows2d.GetLength(1)
  if ($r -eq 0 -or $c -eq 0) { return }
  $rng = $ws.Range($ws.Cells.Item($row, $col), $ws.Cells.Item($row + $r - 1, $col + $c - 1))
  # a 2D array returned from a function arrives PSObject-wrapped; COM needs the bare array
  $rng.Value2 = [object[,]]($rows2d.PSObject.BaseObject)
}
function Set-Header($ws, [int]$row, [int]$ncol) {
  $h = $ws.Range($ws.Cells.Item($row, 1), $ws.Cells.Item($row, $ncol))
  $h.Font.Bold = $true; $h.Font.Color = 0xFFFFFF; $h.Interior.Color = $navy
}
function Set-Title($ws, [string]$text, [string]$sub) {
  $ws.Cells.Item(1,1).Value2 = $text
  $ws.Cells.Item(1,1).Font.Size = 14; $ws.Cells.Item(1,1).Font.Bold = $true
  if ($sub) { $ws.Cells.Item(2,1).Value2 = $sub; $ws.Cells.Item(2,1).Font.Italic = $true }
}
function To2D($headers, $rows) {
  $rows = @($rows)
  $n = $rows.Count + 1; $m = @($headers).Count
  $a = New-Object 'object[,]' $n, $m
  for ($j = 0; $j -lt $m; $j++) { $a[0,$j] = [string]$headers[$j] }
  for ($i = 0; $i -lt $rows.Count; $i++) {
    $row = @($rows[$i])
    for ($j = 0; $j -lt $m; $j++) {
      if ($j -lt $row.Count) {
        # COM can't marshal PSObject-wrapped values (from ConvertFrom-Json / @() rows); unwrap to base types
        $x = $row[$j]
        if ($null -ne $x -and $x -is [System.Management.Automation.PSObject]) { $x = $x.PSObject.BaseObject }
        if ($null -ne $x -and -not ($x -is [string]) -and -not ($x -is [ValueType])) { $x = [string]$x }
        $a[($i+1),$j] = $x
      }
    }
  }
  return ,$a
}

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
try {
  $wb = $xl.Workbooks.Add()
  while ($wb.Worksheets.Count -gt 1) { $wb.Worksheets.Item($wb.Worksheets.Count).Delete() }
  $sheetsMade = 0
  function New-Sheet([string]$name) {
    if ($script:sheetsMade -eq 0) { $ws = $wb.Worksheets.Item(1) }
    else { $ws = $wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
    $script:sheetsMade++
    $ws.Name = $name.Substring(0, [Math]::Min(31, $name.Length))
    return $ws
  }
  $caption = "$($data.site) | $($data.month) | window: $($data.window) | generated $($data.generated)"

  $weekly = ($data.layout -eq 'weekly')
  $thisLbl = if ($weekly) { 'This week' } else { 'This month' }
  $lastLbl = if ($weekly) { 'Last week' } else { 'Last month' }
  $bullet = [string][char]0x2022

  # Summary (monthly only; weekly bullets go under the Weekly Summary table)
  if (-not $weekly) {
    $ws = New-Sheet 'Summary'
    Set-Title $ws "SEO Monthly Report - $($data.site) - $($data.month)" $caption
    $r = 4
    foreach ($s in @($data.summary)) { $ws.Cells.Item($r,1).Value2 = $bullet + ' ' + $s; $ws.Cells.Item($r,1).WrapText = $true; $r++ }
    $ws.Columns.Item(1).ColumnWidth = 120
  }

  # Overview / Weekly Summary
  if ($weekly) { $ws = New-Sheet 'Weekly Summary'; Set-Title $ws "SEO Weekly Health Checks - $($data.site)" $caption }
  else { $ws = New-Sheet 'Overview'; Set-Title $ws "Overview - $($data.site)" $caption }
  $hdr = @('Section','Metric',$thisLbl,$lastLbl,'Change','% Change','Source','Note')
  $rows = @(); $flags = @(); $lastGroup = $null
  foreach ($o in @($data.overview)) {
    $v = $o.value; $p = $o.previous
    $chg = $null; $pct = $null
    if ((Test-Num $v) -and (Test-Num $p)) {
      $chg = [double]$v - [double]$p
      if ([double]$p -ne 0) { $pct = $chg / [double]$p }
    }
    $better = if ($o.better) { $o.better } elseif ($o.metric -match $lowerBetter) { 'lower' } else { 'higher' }
    $flag = 0
    if ($null -ne $chg -and $chg -ne 0) { $good = if ($better -eq 'lower') { $chg -lt 0 } else { $chg -gt 0 }; $flag = if ($good) { 1 } else { -1 } }
    $grp = if ($o.group -ne $lastGroup) { $o.group } else { '' }; $lastGroup = $o.group
    $vv = if ($null -eq $v -or "$v" -eq '') { 'Awaiting data' } else { $v }
    $pp = if ($null -eq $p -or "$p" -eq '') { '-' } else { $p }
    $rows += ,@($grp, $o.metric, $vv, $pp, $chg, $pct, $o.source, $o.note)
    $flags += $flag
  }
  $a = To2D $hdr $rows
  Write-Block $ws 4 1 $a
  Set-Header $ws 4 $hdr.Count
  $n = $rows.Count
  if ($n -gt 0) {
    $ws.Range("F5:F$(4+$n)").NumberFormat = '0.0%'
    $ws.Range("C5:E$(4+$n)").NumberFormat = '#,##0.##'
    for ($i = 0; $i -lt $n; $i++) {
      $rr = 5 + $i
      if ($rows[$i][1] -match 'Rate|CTR') { $ws.Range("C${rr}:E${rr}").NumberFormat = '0.00%' }
      if ($rows[$i][0]) { $ws.Range("A${rr}:H${rr}").Borders.Item(8).Weight = 2; $ws.Cells.Item($rr,1).Font.Bold = $true }
      if ($flags[$i] -eq 1) { $ws.Range("E${rr}:F${rr}").Interior.Color = $green }
      elseif ($flags[$i] -eq -1) { $ws.Range("E${rr}:F${rr}").Interior.Color = $red }
      if ($rows[$i][2] -eq 'Awaiting data') { $ws.Cells.Item($rr,3).Font.Color = 0x808080; $ws.Cells.Item($rr,3).Font.Italic = $true }
    }
  }
  $ws.Columns.Item(1).ColumnWidth = 34; $ws.Columns.Item(2).ColumnWidth = 44
  foreach ($c in 3..6) { $ws.Columns.Item($c).ColumnWidth = 14 }
  $ws.Columns.Item(7).ColumnWidth = 26; $ws.Columns.Item(8).ColumnWidth = 50
  if ($weekly) {
    $r = 6 + $n
    foreach ($s in @($data.summary)) { if ($s) { $ws.Cells.Item($r,1).Value2 = $bullet + ' ' + $s; $r++ } }
  }

  # Generic table sheets
  foreach ($s in @($data.sheets)) {
    if (-not $s) { continue }
    $ws = New-Sheet $s.name
    Set-Title $ws $s.name $(if ($s.title) { $s.title } else { $caption })
    $hdr = @($s.headers)
    if (@($s.rows).Count -eq 0) { $ws.Cells.Item(4,1).Value2 = 'No data this period.'; continue }
    $a = To2D $hdr @($s.rows)
    Write-Block $ws 4 1 $a
    Set-Header $ws 4 $hdr.Count
    $used = $ws.Range($ws.Cells.Item(4,1), $ws.Cells.Item(4 + @($s.rows).Count, $hdr.Count))
    $used.Columns.AutoFit() | Out-Null
    for ($j = 1; $j -le $hdr.Count; $j++) {
      if ($ws.Columns.Item($j).ColumnWidth -gt 70) { $ws.Columns.Item($j).ColumnWidth = 70 }
      if ($hdr[$j-1] -match 'CTR|%') { $ws.Range($ws.Cells.Item(5,$j), $ws.Cells.Item(4 + @($s.rows).Count, $j)).NumberFormat = '0.00%' }
    }
    $used.AutoFilter() | Out-Null
  }

  if (-not $weekly) {
    # GSC screenshots
    $ws = New-Sheet 'GSC Screenshots'
    Set-Title $ws 'GSC Performance screenshots' 'Drop .png/.jpg files into seo\_exports\<month>\<site>\screenshots\ and rebuild.'
    $top = 60.0
    if ($data.screenshotsDir -and (Test-Path $data.screenshotsDir)) {
      foreach ($img in Get-ChildItem $data.screenshotsDir -File | Where-Object { $_.Extension -match '\.(png|jpe?g)$' } | Sort-Object Name) {
        $ws.Cells.Item([int]($top / 15) + 1, 1).Value2 = $img.BaseName
        $pic = $ws.Shapes.AddPicture($img.FullName, $false, $true, 0, $top + 16, -1, -1)
        if ($pic.Width -gt 900) { $pic.LockAspectRatio = -1; $pic.Width = 900 }
        $top = $top + 16 + $pic.Height + 30
      }
    } else { $ws.Cells.Item(4,1).Value2 = 'No screenshots this month.' }

    # Improvements
    $ws = New-Sheet 'Improvements'
    Set-Title $ws "Errors and improvements this month - $($data.site)" 'P1 = fix this month (ranking/indexing risk) | P2 = fix this month if time | P3 = backlog. Carried items stay until a later crawl verifies them fixed.'
    $hdr = @('Priority','Area','URL / scope','Issue','Evidence','Fix','Owner','Effort','Status')
    $rows = @(); foreach ($i in @($data.improvements)) { if ($i) { $rows += ,@($i.priority,$i.area,$i.url,$i.issue,$i.evidence,$i.fix,$i.owner,$i.effort,$i.status) } }
    if ($rows.Count -gt 0) {
      $a = To2D $hdr $rows; Write-Block $ws 4 1 $a; Set-Header $ws 4 $hdr.Count
      $widths = 9,14,40,45,45,55,12,10,12
      for ($j = 0; $j -lt 9; $j++) { $ws.Columns.Item($j+1).ColumnWidth = $widths[$j] }
      $body = $ws.Range("A5:I$(4+$rows.Count)"); $body.WrapText = $true; $body.VerticalAlignment = -4160
      for ($k = 0; $k -lt $rows.Count; $k++) {
        $rr = 5 + $k
        switch ($rows[$k][0]) { 'P1' { $ws.Cells.Item($rr,1).Interior.Color = $red } 'P2' { $ws.Cells.Item($rr,1).Interior.Color = 0x9CEBFF } default { $ws.Cells.Item($rr,1).Interior.Color = $grey } }
      }
      $ws.PageSetup.Orientation = 2; $ws.PageSetup.Zoom = $false; $ws.PageSetup.FitToPagesWide = 1; $ws.PageSetup.FitToPagesTall = 1
    } else { $ws.Cells.Item(4,1).Value2 = 'No open items.' }
  }

  $wb.Worksheets.Item(1).Activate()
  $full = [System.IO.Path]::GetFullPath($OutFile)
  New-Item -ItemType Directory -Force (Split-Path $full) | Out-Null
  if (Test-Path $full) { Remove-Item $full -Force }
  $wb.SaveAs($full, 51)
  $wb.Close($false)
  "Saved $full ($sheetsMade sheets)"
}
finally {
  $xl.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
  [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
