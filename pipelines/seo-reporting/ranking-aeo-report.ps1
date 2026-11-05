<#
.SYNOPSIS
  Weekly "Ranking & AEO Report": one workbook for every site in config\sites.csv, in a long-running
  tracker layout (one keyword row per term, one "Rank <Mon d>" column added per week).

  Workbook: <root>\seo\reports\ranking-aeo-report.xlsx (created on the first run).
  Sheets:   Overview | "<site> keywords" (one per site) | Organic Detail | AEO - Prompts | AEO - AI Traffic

  Each run:
    1. Adds any keyword from keywords.csv that is not yet on its site's keyword sheet.
    2. Pulls Search Console average position for every keyword on the keyword sheets
       (exact query match, one week, plus the last 28 days) -> seo\_exports\weekly\<label>\<site>\gsc\TrackedRanks.csv
    3. Adds (or overwrites, on a rerun) the "Rank <Mon d>" column on each keyword sheet.
    4. Rebuilds Overview, Organic Detail, AEO - Prompts and AEO - AI Traffic from the data the
       weekly run already wrote (seo\rankings\aeo-history.csv, aeo-focus.csv, ga4-ai-*.csv).

  Rank = Search Console average position for the week, rounded. "N/A" = position above 100.
  "No data" = no impressions for that exact query that week. If you paste in older rank columns
  from manual / third-party checks, note the method break: do not compare across it.

.PARAMETER ExcludeAiPaths
  Landing-path prefixes to report separately in AI traffic (e.g. '/careers/'). Job pages can take
  most AI-assistant sessions on a company site; report the buyer-relevant number without them.

.EXAMPLE
  .\ranking-aeo-report.ps1 -Label 2026-10-05 -From 2026-09-28 -To 2026-10-04 -ExcludeAiPaths '/careers/'
#>
param(
  [Parameter(Mandatory)][string]$Label,
  [Parameter(Mandatory)][string]$From,
  [Parameter(Mandatory)][string]$To,
  [ValidateSet('final','all')][string]$DataState = 'final',
  [string[]]$ExcludeAiPaths = @(),
  [switch]$SkipFetch,
  [string]$Root,
  [string]$OutFile
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'seo-common.ps1')
$Data = Get-SeoDataDir $Root
$Rank = Join-Path $Data 'rankings'
$Master = if ($OutFile) { [IO.Path]::GetFullPath($OutFile) } else { Join-Path $Data 'reports\ranking-aeo-report.xlsx' }
New-Item -ItemType Directory -Force (Split-Path $Master), $Rank | Out-Null
$Exp = Join-Path $Data "_exports\weekly\$Label"
$inv = [Globalization.CultureInfo]::InvariantCulture
$colHdr = 'Rank ' + ([datetime]::ParseExact($Label, 'yyyy-MM-dd', $inv)).ToString('MMM d', $inv)
$weekTxt = ([datetime]::ParseExact($From, 'yyyy-MM-dd', $inv)).ToString('MMM d', $inv) + ' - ' + ([datetime]::ParseExact($To, 'yyyy-MM-dd', $inv)).ToString('MMM d, yyyy', $inv)

$siteCfg = @{}; $siteKeys = @()
foreach ($s in Get-SeoSites $Root) { $siteCfg[$s.key] = Get-SeoSite $Root $s.key; $siteKeys += $s.key }
$Sheets = @(foreach ($k in $siteKeys) { $n = "$k keywords"; @{ name = $n.Substring(0, [Math]::Min(31, $n.Length)); site = $k; title = $k } })

function Norm([string]$s) { (($s -replace '\s+', ' ').Trim()).ToLowerInvariant() }
function NormUrl([string]$u) { if (-not $u) { return '' }; ((($u.Trim() -replace '^https?://(www\.)?', '') -replace '[#?].*$', '') -replace '/+$', '').ToLowerInvariant() }
function Rx([string]$s) { [regex]::Replace($s, '[\\.+*?()|\[\]{}^$]', { param($m) '\' + $m.Value }) }
function RGB($r, $g, $b) { $r + 256 * $g + 65536 * $b }
$GREEN = RGB 198 239 206; $RED = RGB 255 199 206; $BLUE = RGB 221 235 247; $HDR = RGB 31 58 90; $WHITE = RGB 255 255 255

$xl = New-Object -ComObject Excel.Application; $xl.Visible = $false; $xl.DisplayAlerts = $false; $xl.ScreenUpdating = $false
$wb = $null
try {
  # Work on a local TEMP copy: opening straight from a cloud-synced folder can leave
  # Excel busy (RPC_E_CALL_REJECTED). If that still happens, close only the hidden Excel this run started.
  $Work = Join-Path $env:TEMP ("ranking-aeo-" + [guid]::NewGuid().ToString("N") + ".xlsx")
  $xl.AskToUpdateLinks = $false; $xl.EnableEvents = $false
  if (Test-Path $Master) { Copy-Item $Master $Work; $wb = $xl.Workbooks.Open($Work, 0, $false); Start-Sleep -Seconds 2 }
  else {
    $wb = $xl.Workbooks.Add()
    while ($wb.Worksheets.Count -gt 1) { $wb.Worksheets.Item($wb.Worksheets.Count).Delete() }
    $wb.Worksheets.Item(1).Name = 'Overview'
    $wb.SaveAs($Work, 51)
    "Creating $Master"
  }
  function Get-Sheet([string]$n) { foreach ($s in $wb.Worksheets) { if ($s.Name -eq $n) { return $s } }; $null }
  function Write-Grid($ws, [int]$r0, [int]$c0, $rows) {
    if (-not $rows -or $rows.Count -eq 0) { return }
    $nc = ($rows | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
    $a = New-Object 'object[,]' $rows.Count, $nc
    # PSObject-wrapped values in an object[,] make COM fail (out of memory): unwrap every cell
    for ($i = 0; $i -lt $rows.Count; $i++) { for ($j = 0; $j -lt $rows[$i].Count; $j++) { $v = $rows[$i][$j]; if ($v -is [psobject]) { $v = $v.psobject.BaseObject }; $a[$i, $j] = $v } }
    $ws.Range($ws.Cells.Item($r0, $c0), $ws.Cells.Item($r0 + $rows.Count - 1, $c0 + $nc - 1)).Value2 = $a
  }
  function Style-Header($rng) { $rng.Font.Bold = $true; $rng.Font.Color = $WHITE; $rng.Interior.Color = $HDR; $rng.WrapText = $true; $rng.VerticalAlignment = -4108 }

  # ---- keyword sheets: one per site; add tracked keywords that are not on the sheet yet ----
  $kwFile = Get-SeoListFile $Root 'keywords.csv'
  $tracked = if (Test-Path $kwFile) { @(Import-Csv $kwFile) } else { @() }
  if (-not (Get-Sheet 'Overview')) { $o = $wb.Worksheets.Add($wb.Worksheets.Item(1)); $o.Name = 'Overview' }
  $prevSheet = Get-Sheet 'Overview'
  foreach ($cfg in $Sheets) {
    $ws = Get-Sheet $cfg.name
    if (-not $ws) {
      $ws = $wb.Worksheets.Add([Reflection.Missing]::Value, $prevSheet); $ws.Name = $cfg.name
      Write-Grid $ws 1 1 @(, @('Keywords', 'URL'))
      Style-Header $ws.Range('A1:B1'); $ws.Columns.Item(1).ColumnWidth = 40; $ws.Columns.Item(2).ColumnWidth = 55
    }
    $prevSheet = $ws
    $have = @{}; $v = $ws.UsedRange.Value2
    if ($v -is [array]) { for ($i = 2; $i -le $v.GetLength(0); $i++) { if ("$($v[$i,1])") { $have[(Norm "$($v[$i,1])")] = 1 } } }
    $last = $ws.Cells.Item($ws.Rows.Count, 1).End(-4162).Row
    $add = @($tracked | Where-Object { $_.site -eq $cfg.site -and $_.keyword -and -not $have[(Norm $_.keyword)] })
    if ($add.Count) { Write-Grid $ws ($last + 1) 1 @($add | ForEach-Object { , @($_.keyword, $_.target_url) }); "Added $($add.Count) tracked keywords to '$($cfg.name)'" }
  }

  # ---- read keywords per sheet ----
  $kwBySite = @{}; foreach ($k in $siteKeys) { $kwBySite[$k] = @{} }
  foreach ($cfg in $Sheets) {
    $ws = Get-Sheet $cfg.name; $v = $ws.UsedRange.Value2
    $cfg.nrows = $v.GetLength(0); $cfg.ncols = $v.GetLength(1)
    $cfg.urlCol = 2; for ($j = 1; $j -le $cfg.ncols; $j++) { if ("$($v[1,$j])".Trim() -in 'URL', 'Url') { $cfg.urlCol = $j; break } }
    $cfg.rows = @(for ($i = 2; $i -le $cfg.nrows; $i++) { if ("$($v[$i,1])".Trim()) { [pscustomobject]@{ r = $i; kw = "$($v[$i,1])".Trim(); url = "$($v[$i,$cfg.urlCol])".Trim() } } })
    foreach ($row in $cfg.rows) { $kwBySite[$cfg.site][(Norm $row.kw)] = 1 }
  }

  # ---- Search Console: exact-query positions ----
  $data = @{}; $hdrs = $null
  foreach ($site in $siteKeys) {
    $out = Join-Path $Exp "$site\gsc\TrackedRanks.csv"
    $data[$site] = @{}
    if ($SkipFetch -and (Test-Path $out)) { foreach ($r in Import-Csv $out) { $data[$site][$r.Keyword] = $r }; continue }
    $kws = @($kwBySite[$site].Keys)
    if (-not $kws.Count) { "GSC $site : no keywords on the sheet"; continue }
    if (-not $hdrs) { . (Join-Path $PSScriptRoot 'google-auth.ps1') -Action Lib; $hdrs = @{ Authorization = "Bearer $(Get-GoogleAccessToken)" } }
    $u = "https://www.googleapis.com/webmasters/v3/sites/$([uri]::EscapeDataString($siteCfg[$site].GscProperty))/searchAnalytics/query"
    $pageRx = $siteCfg[$site].PageRegex
    $chunks = @(); $cur = @()
    foreach ($k in $kws) { $cur += (Rx $k); if ((($cur -join '|').Length) -gt 1500) { $chunks += , $cur; $cur = @() } }
    if ($cur.Count) { $chunks += , $cur }
    $pos = @{}; $pages = @{}; $pos28 = @{}
    $from28 = ([datetime]::ParseExact($To, 'yyyy-MM-dd', $inv)).AddDays(-27).ToString('yyyy-MM-dd')
    foreach ($c in $chunks) {
      $qf = @{ dimension = 'query'; operator = 'includingRegex'; expression = '^(?:' + ($c -join '|') + ')$' }
      $b28 = @{ startDate = $from28; endDate = $To; dimensions = @('query'); rowLimit = 25000; dataState = $DataState; dimensionFilterGroups = @(@{ filters = @($qf) }) } | ConvertTo-Json -Depth 8
      foreach ($row in @((Invoke-RestMethod -Method Post -Uri $u -Headers $hdrs -ContentType 'application/json' -Body $b28).rows)) { if ($row) { $pos28[(Norm $row.keys[0])] = $row } }
      foreach ($dims in (@(, @('query')) + @(, @('query', 'page')))) {
        $f = @($qf); if ($pageRx -and $dims -contains 'page') { $f += @{ dimension = 'page'; operator = 'includingRegex'; expression = $pageRx } }
        $body = @{ startDate = $From; endDate = $To; dimensions = $dims; rowLimit = 25000; dataState = $DataState; dimensionFilterGroups = @(@{ filters = $f }) } | ConvertTo-Json -Depth 8
        $r = Invoke-RestMethod -Method Post -Uri $u -Headers $hdrs -ContentType 'application/json' -Body $body
        foreach ($row in @($r.rows)) {
          if (-not $row) { continue }
          $q = Norm $row.keys[0]
          if ($dims.Count -eq 1) { $pos[$q] = $row }
          else { if (-not $pages[$q]) { $pages[$q] = @() }; $pages[$q] += [pscustomobject]@{ page = $row.keys[1]; impr = [double]$row.impressions; pos = [double]$row.position } }
        }
      }
    }
    $rows = foreach ($k in $kws) {
      $p = $pos[$k]; $pg = @($pages[$k] | Sort-Object impr -Descending)
      $top = if ($pg.Count) { $pg[0] } else { $null }
      $others = if ($top) { @($pg | Select-Object -Skip 1 | Where-Object { $_.impr -ge [math]::Max(1, 0.1 * $top.impr) } | ForEach-Object { "$($_.page) ($($_.impr))" }) -join '; ' } else { '' }
      [pscustomobject]@{ Keyword = $k; Position = $(if ($p) { [math]::Round([double]$p.position, 2) } else { '' }); Impressions = $(if ($p) { $p.impressions } else { 0 }); Clicks = $(if ($p) { $p.clicks } else { 0 }); Position28d = $(if ($pos28[$k]) { [math]::Round([double]$pos28[$k].position, 2) } else { '' }); Impressions28d = $(if ($pos28[$k]) { $pos28[$k].impressions } else { 0 }); TopUrl = $(if ($top) { $top.page } else { '' }); OtherUrls = $others }
    }
    New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
    @($rows) | Export-Csv $out -NoTypeInformation -Encoding UTF8
    foreach ($r in $rows) { $data[$site][$r.Keyword] = $r }
    "GSC $site : $(@($rows | Where-Object { $_.Position -ne '' }).Count) of $($kws.Count) keywords had impressions ($DataState, $From..$To)"
  }

  # ---- write the weekly Rank column on each keyword sheet ----
  $detail = @(); $summary = @()
  foreach ($cfg in $Sheets) {
    $ws = Get-Sheet $cfg.name
    if (-not $cfg.rows.Count) { $summary += [pscustomobject]@{ Report = $cfg.title; Site = $cfg.site; Prev = ''; Counts = [ordered]@{ Tracked = 0; Constant = 0; Improved = 0; Drop = 0; New = 0; Quiet = 0; NotRanking = 0; Top10 = 0 } }; continue }
    $hv = $ws.Range($ws.Cells.Item(1, 1), $ws.Cells.Item(1, $cfg.ncols + 1)).Value2
    $rankCols = @(); $col = 0
    for ($j = 1; $j -le $cfg.ncols; $j++) { $h = "$($hv[1,$j])".Trim(); if ($h -match '^Rank\s+\S') { $rankCols += $j; if (($h -replace '\s+', ' ') -eq $colHdr) { $col = $j } } }
    if (-not $col) {
      $col = if ($rankCols.Count) { $rankCols[-1] + 1 } else { $cfg.urlCol + 1 }
      if ($col -le $cfg.ncols) { $ws.Columns.Item($col).Insert(-4161, 0) | Out-Null }
      $ws.Cells.Item(1, $col).Value2 = $colHdr
      if (-not $rankCols.Count) { Style-Header $ws.Cells.Item(1, $col) } else { $ws.Cells.Item(1, $rankCols[-1]).Copy($ws.Cells.Item(1, $col)) | Out-Null; $ws.Cells.Item(1, $col).Value2 = $colHdr }
      $ws.Columns.Item($col).ColumnWidth = 11
    }
    $prevCol = @($rankCols | Where-Object { $_ -lt $col })[-1]
    $prevHdr = if ($prevCol) { "$($ws.Cells.Item(1,$prevCol).Value2)".Trim() } else { '' }
    $lastRow = [math]::Max(2, ($cfg.rows | ForEach-Object { $_.r } | Measure-Object -Maximum).Maximum)
    $ws.Range($ws.Cells.Item(2, $col), $ws.Cells.Item($lastRow, $col)).Interior.ColorIndex = -4142
    # no if-expression here: it would flatten the 2-D Value2 array
    $prevVals = $null; if ($prevCol) { $prevVals = $ws.Range($ws.Cells.Item(1, $prevCol), $ws.Cells.Item($lastRow, $prevCol)).Value2 }
    $cnt = [ordered]@{ Tracked = 0; Constant = 0; Improved = 0; Drop = 0; New = 0; Quiet = 0; NotRanking = 0; Top10 = 0 }
    foreach ($row in $cfg.rows) {
      $d = $data[$cfg.site][(Norm $row.kw)]
      $p = if ($d -and "$($d.Position)" -ne '') { [double]$d.Position } else { $null }
      $rk = if ($null -ne $p -and $p -le 100) { [int][math]::Round($p, [MidpointRounding]::AwayFromZero) } elseif ($null -ne $p) { 'N/A' } else { 'No data' }
      $prev = if ($prevVals) { "$($prevVals.GetValue($row.r, 1))".Trim() } else { '' }
      $pn = 0.0; $prevNum = [double]::TryParse($prev, [ref]$pn)
      $p28 = if ($d -and "$($d.Position28d)" -ne '') { [double]$d.Position28d } else { $null }
      $status = if ($rk -is [string] -and $null -ne $p28 -and $p28 -le 100) { 'No impressions this week' } elseif ($rk -is [string]) { 'No Google data (28 days)' } elseif (-not $prevNum) { 'New' } elseif (($pn - $rk) -ge 3) { 'Improved' } elseif (($rk - $pn) -ge 3) { 'Drop' } else { 'Constant' }
      $chg = if ($rk -isnot [string] -and $prevNum) { $pn - $rk } else { '' }
      # separate assignment statements: the COM binder caches the first value type per call site,
      # so one line that writes both numbers and strings throws a cast error
      $cell = $ws.Cells.Item($row.r, $col)
      if ($rk -is [string]) { $cell.Value2 = [string]$rk } else { $cell.Value2 = [double]$rk }
      $cell.HorizontalAlignment = -4108
      switch ($status) { 'Improved' { $cell.Interior.Color = $GREEN } 'Drop' { $cell.Interior.Color = $RED } 'New' { $cell.Interior.Color = $BLUE } }
      $cnt.Tracked++; switch ($status) { 'Constant' { $cnt.Constant++ } 'Improved' { $cnt.Improved++ } 'Drop' { $cnt.Drop++ } 'New' { $cnt.New++ } 'No impressions this week' { $cnt.Quiet++ } default { $cnt.NotRanking++ } }
      if ($rk -isnot [string] -and $rk -le 10) { $cnt.Top10++ }
      $match = if (-not $row.url) { 'No target URL' } elseif (-not $d -or -not $d.TopUrl) { '' } elseif ((NormUrl $row.url) -eq (NormUrl $d.TopUrl)) { 'Yes' } else { 'No' }
      $detail += , @($cfg.title, $row.kw, $row.url, $prev, $rk, $(if ($null -ne $p) { $p } else { '' }), $(if ($null -ne $p28) { $p28 } else { '' }), $chg, $status, $(if ($d) { $d.TopUrl } else { '' }), $match, $(if ($d) { [double]$d.Impressions } else { 0 }), $(if ($d) { [double]$d.Clicks } else { 0 }), $(if ($d) { $d.OtherUrls } else { '' }))
    }
    $summary += [pscustomobject]@{ Report = $cfg.title; Site = $cfg.site; Prev = $prevHdr; Counts = $cnt }
  }

  # ---- Organic Detail ----
  foreach ($n in 'Organic Detail', 'AEO - Prompts', 'AEO - AI Traffic') { $s = Get-Sheet $n; if ($s) { $s.Delete() } }
  $od = $wb.Worksheets.Add([Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count)); $od.Name = 'Organic Detail'
  $hdrRow = @('Site', 'Keyword', 'Target URL', 'Previous rank', "$colHdr", 'GSC avg position (week)', 'GSC avg position (last 28 days)', 'Change (+ = up)', 'Status', 'Ranking URL (GSC, most impressions)', 'URL match', 'Impressions', 'Clicks', 'Other URLs ranking (>=10% of top URL impressions)')
  Write-Grid $od 1 1 (@(, $hdrRow) + $detail)
  Style-Header $od.Range('A1:N1'); $od.Rows.Item(1).RowHeight = 32
  $ws_ = @(12, 38, 45, 11, 11, 11, 13, 11, 22, 55, 12, 11, 9, 60); for ($j = 0; $j -lt 14; $j++) { $od.Columns.Item($j + 1).ColumnWidth = $ws_[$j] }
  $od.Range('A1:N1').AutoFilter() | Out-Null
  $od.Activate(); $xl.ActiveWindow.SplitRow = 1; $xl.ActiveWindow.SplitColumn = 2; $xl.ActiveWindow.FreezePanes = $true

  # ---- AEO - Prompts ----
  $histFile = Join-Path $Rank 'aeo-history.csv'
  $hist = if (Test-Path $histFile) { @(Import-Csv $histFile) } else { @() }
  $focus = @{}; $focusFile = Get-SeoListFile $Root 'aeo-focus.csv'
  if (Test-Path $focusFile) { foreach ($f in Import-Csv $focusFile) { $focus["$($f.site)|$($f.prompt)"] = $f } }
  $aeoRows = @(); $aeoSum = @()
  $aeoSites = @($hist | ForEach-Object { $_.site } | Sort-Object -Unique)
  foreach ($brand in $aeoSites) {
    $now = @($hist | Where-Object { $_.site -eq $brand -and $_.date -eq $Label })
    $prevDate = @($hist | Where-Object { $_.site -eq $brand -and $_.date -lt $Label } | ForEach-Object { $_.date } | Sort-Object -Unique)[-1]
    $prev = @{}; foreach ($h in $hist | Where-Object { $_.site -eq $brand -and $_.date -eq $prevDate }) { $prev[$h.prompt] = $h }
    $gain = 0; $lost = 0
    foreach ($h in $now | Sort-Object @{ e = { $_.appears -ne 'Y' } }, @{ e = { if ($_.position) { [int]$_.position } else { 99 } } }) {
      $p = $prev[$h.prompt]; $f = $focus["$brand|$($h.prompt)"]
      $chg = if (-not $p) { 'New prompt' } elseif ($p.appears -ne 'Y' -and $h.appears -eq 'Y') { $gain++; 'Gained' } elseif ($p.appears -eq 'Y' -and $h.appears -ne 'Y') { $lost++; 'Lost' } elseif ($h.appears -eq 'Y' -and $p.position -and $h.position -and [int]$h.position -lt [int]$p.position) { "Up ($($p.position) -> $($h.position))" } elseif ($h.appears -eq 'Y' -and $p.position -and $h.position -and [int]$h.position -gt [int]$p.position) { "Down ($($p.position) -> $($h.position))" } else { 'No change' }
      $aeoRows += , @($brand, $h.prompt, $(if ($h.appears -eq 'Y') { 'Shown' } else { 'Not shown' }), $h.position, $h.url, $(if ($p) { $(if ($p.appears -eq 'Y') { "Shown #$($p.position)" } else { 'Not shown' }) } else { '' }), $chg, $h.competitors, $h.top_domains, $(if ($f) { $f.priority } else { '' }), $(if ($f) { $f.focus } else { '' }), $(if ($f) { $f.page_to_work_on } else { '' }))
    }
    $aeoSum += [pscustomobject]@{ Brand = $brand; Prompts = $now.Count; Shown = @($now | Where-Object { $_.appears -eq 'Y' }).Count; Gained = $gain; Lost = $lost; PrevDate = $prevDate }
  }
  $ap = $wb.Worksheets.Add([Reflection.Missing]::Value, $od); $ap.Name = 'AEO - Prompts'
  Write-Grid $ap 1 1 @(, @("AEO - AI answers (web-search proxy, run for week label $Label). 'Shown' = one of our domains appears in the top 10 web results an AI assistant would draw on for this prompt. Not captured assistant output."))
  $ap.Range('A1').Font.Italic = $true
  Write-Grid $ap 2 1 (@(, @('Site', 'Prompt', 'Shown now?', 'Position', 'Our URL shown', 'Last week', 'Change vs last week', 'Competitors shown', 'Top domains', 'Priority', 'What to focus on', 'Page to work on')) + $aeoRows)
  Style-Header $ap.Range('A2:L2'); $ap.Rows.Item(2).RowHeight = 30
  $wd = @(22, 40, 11, 9, 50, 13, 18, 40, 40, 10, 70, 50); for ($j = 0; $j -lt 12; $j++) { $ap.Columns.Item($j + 1).ColumnWidth = $wd[$j] }
  if ($aeoRows.Count) {
    $ap.Range("A3:L$($aeoRows.Count + 2)").WrapText = $true; $ap.Range("A3:L$($aeoRows.Count + 2)").VerticalAlignment = -4160
    for ($i = 0; $i -lt $aeoRows.Count; $i++) {
      $c = $ap.Cells.Item($i + 3, 3); $c.Interior.Color = $(if ($aeoRows[$i][2] -eq 'Shown') { $GREEN } else { $RED })
      $pc = $ap.Cells.Item($i + 3, 10); switch ($aeoRows[$i][9]) { 'High' { $pc.Interior.Color = $RED } 'Medium' { $pc.Interior.Color = (RGB 255 235 156) } 'Defend' { $pc.Interior.Color = $BLUE } }
    }
  }
  $ap.Range("A2:L2").AutoFilter() | Out-Null
  $ap.Activate(); $xl.ActiveWindow.SplitRow = 2; $xl.ActiveWindow.SplitColumn = 2; $xl.ActiveWindow.FreezePanes = $true

  # ---- AEO - AI Traffic (GA4 AI Assistant channel) ----
  $weeklyDir = Split-Path $Exp
  $prevLabel = $null
  if (Test-Path $weeklyDir) { $prevLabel = @(Get-ChildItem $weeklyDir -Directory | Where-Object { $_.Name -lt $Label } | Sort-Object Name | ForEach-Object { $_.Name })[-1] }
  $tr = @(); $aiTot = @{}
  foreach ($site in $siteKeys) {
    $cur = @{}; $old = @{}
    $f1 = Join-Path $Exp "$site\ga4-ai-sources.csv"; if (Test-Path $f1) { foreach ($r in Import-Csv $f1) { $cur[$r.sessionSource] = [int]$r.sessions } }
    if ($prevLabel) { $f2 = Join-Path $weeklyDir "$prevLabel\$site\ga4-ai-sources.csv"; if (Test-Path $f2) { foreach ($r in Import-Csv $f2) { $old[$r.sessionSource] = [int]$r.sessions } } }
    $srcs = @(@($cur.Keys) + @($old.Keys) | Sort-Object -Unique | Sort-Object { - [int]$cur[$_] })
    foreach ($s in $srcs) { $tr += , @($site, $s, [int]$cur[$s], [int]$old[$s], ([int]$cur[$s] - [int]$old[$s])) }
    $t1 = [int]($cur.Values | Measure-Object -Sum).Sum; $t0 = [int]($old.Values | Measure-Object -Sum).Sum
    $tr += , @($site, 'All assistants', $t1, $t0, ($t1 - $t0))
    $aiTot[$site] = @($t1, $t0)
    if ($ExcludeAiPaths.Count) {
      $ex = @(0, 0); $i = 0
      foreach ($lbl in @($Label, $prevLabel)) {
        if ($lbl) {
          $f3 = Join-Path $weeklyDir "$lbl\$site\ga4-ai-landing.csv"
          if (Test-Path $f3) { $ex[$i] = [int](@(Import-Csv $f3 | Where-Object { $lp = $_.landingPagePlusQueryString; @($ExcludeAiPaths | Where-Object { $lp -like "$_*" }).Count } | Measure-Object sessions -Sum).Sum) }
        }
        $i++
      }
      $exLbl = 'All assistants excl. ' + ($ExcludeAiPaths -join ', ')
      $tr += , @($site, $exLbl, ($t1 - $ex[0]), ($t0 - $ex[1]), (($t1 - $ex[0]) - ($t0 - $ex[1])))
      $aiTot["$site|excl"] = @(($t1 - $ex[0]), ($t0 - $ex[1]))
    }
  }
  $at = $wb.Worksheets.Add([Reflection.Missing]::Value, $ap); $at.Name = 'AEO - AI Traffic'
  Write-Grid $at 1 1 (@(, @('Site', 'Assistant (GA4 session source)', "Sessions $weekTxt", "Sessions prior week ($prevLabel)", 'Change')) + $tr)
  Style-Header $at.Range('A1:E1'); $at.Rows.Item(1).RowHeight = 30
  $wd = @(12, 34, 16, 18, 10); for ($j = 0; $j -lt 5; $j++) { $at.Columns.Item($j + 1).ColumnWidth = $wd[$j] }
  for ($i = 0; $i -lt $tr.Count; $i++) { if ($tr[$i][1] -like 'All assistants*') { $at.Rows.Item($i + 2).Font.Bold = $true } }

  # ---- Overview ----
  $ov = Get-Sheet 'Overview'; $ov.Cells.Clear() | Out-Null
  $ov.Cells.Item(1, 1).Value2 = "Ranking & AEO Report - week $weekTxt (label $Label)"; $ov.Cells.Item(1, 1).Font.Size = 14; $ov.Cells.Item(1, 1).Font.Bold = $true
  $ov.Cells.Item(3, 1).Value2 = 'Organic keyword ranking'; $ov.Cells.Item(3, 1).Font.Bold = $true
  $orow = @(, @('Keyword Ranking Report', 'Site', 'Keywords tracked', 'Constantly Ranking Keywords', 'Keyword Rank improved', 'Keyword Drop', 'New / re-entered', 'Ranks, but no impressions this week', 'No Google data in 28 days (no searches, or not in top 100)', 'In top 10', 'Compared with'))
  foreach ($s in $summary) { $c = $s.Counts; $orow += , @("$($s.Report) Keyword Ranking Report", $s.Site, $c.Tracked, $c.Constant, $c.Improved, $c.Drop, $c.New, $c.Quiet, $c.NotRanking, $c.Top10, $(if ($s.Prev) { $s.Prev } else { 'first week' })) }
  Write-Grid $ov 4 1 $orow; Style-Header $ov.Range('A4:K4'); $ov.Rows.Item(4).RowHeight = 45
  $r0 = 5 + $orow.Count
  $ov.Cells.Item($r0, 1).Value2 = 'AEO - AI answers (web-search proxy)'; $ov.Cells.Item($r0, 1).Font.Bold = $true
  $arow = @(, @('AEO Report', 'Site', 'Prompts tracked', 'Prompts where we are shown', 'Not shown', 'Gained vs last week', 'Lost vs last week', 'AI-assistant sessions (GA4)', 'Prior week', 'Compared with'))
  foreach ($a in $aeoSum) {
    $sess = if ($aiTot.ContainsKey($a.Brand)) { $aiTot[$a.Brand] } else { @('', '') }
    $arow += , @("$($a.Brand) AEO Report", $a.Brand, $a.Prompts, $a.Shown, ($a.Prompts - $a.Shown), $a.Gained, $a.Lost, $sess[0], $sess[1], $(if ($a.PrevDate) { "week of $($a.PrevDate)" } else { 'first week' }))
  }
  foreach ($site in $siteKeys) { if ($aiTot.ContainsKey("$site|excl")) { $arow += , @("  $site AI sessions excl. $($ExcludeAiPaths -join ', ')", $site, '', '', '', '', '', $aiTot["$site|excl"][0], $aiTot["$site|excl"][1], $(if ($prevLabel) { "week of $prevLabel" } else { 'first week' })) } }
  Write-Grid $ov ($r0 + 1) 1 $arow; Style-Header $ov.Range("A$($r0+1):J$($r0+1)"); $ov.Rows.Item($r0 + 1).RowHeight = 45
  $n0 = $r0 + 2 + $arow.Count
  $notes = @(
    "How to read this",
    "- $colHdr = Google Search Console average position for $weekTxt, exact-match query, rounded (dataState=$DataState). 'No data' = no Search Console impressions for that exact query this week. N/A = average position above 100.",
    "- Many long-tail keywords get no searches in a given week. A keyword with no impressions this week but a position over the last 28 days is counted as 'Ranks, but no impressions this week', not as not ranking. Organic Detail shows the 28-day position.",
    "- Search Console only records a position when someone searches the term. A long-tail term that ranked #1 in a manual check can show No data simply because nobody searched it; it is not necessarily lost.",
    "- If older rank columns came from manual or third-party rank checks, they use a different method from Search Console average position. Do not compare across that break.",
    "- Constantly ranking = moved fewer than 3 places vs the previous column. Improved / Drop = moved 3+ places. New = no rank last time, ranks now. Cell colours on the keyword sheets: green improved, red drop, blue new.",
    "- Organic Detail lists every keyword with its ranking URL and whether it matches the target URL.",
    "- AEO - Prompts lists every AI prompt, whether we are shown now, the change vs last week, and what to focus on. AEO - AI Traffic is GA4's AI Assistant channel by source."
  )
  Write-Grid $ov $n0 1 @($notes | ForEach-Object { , @($_) }); $ov.Cells.Item($n0, 1).Font.Bold = $true
  $wd = @(40, 12, 11, 14, 12, 11, 12, 14, 18, 10, 14); for ($j = 0; $j -lt 11; $j++) { $ov.Columns.Item($j + 1).ColumnWidth = $wd[$j] }
  $ov.Range("C5:K$($r0+1+$arow.Count)").HorizontalAlignment = -4108

  $ov.Activate(); $ov.Range('A1').Select() | Out-Null
  $xl.ScreenUpdating = $true
  $wb.Save(); $wb.Close($false) | Out-Null; $wb = $null
  Copy-Item $Work $Master -Force; Remove-Item $Work -Force
  "Saved $Master"
  $summary | ForEach-Object { "{0,-14} tracked {1,3} | constant {2,3} | improved {3,3} | drop {4,3} | new {5,3} | quiet {9,3} | not ranking {6,3} | top10 {7,3} | vs {8}" -f $_.Report, $_.Counts.Tracked, $_.Counts.Constant, $_.Counts.Improved, $_.Counts.Drop, $_.Counts.New, $_.Counts.NotRanking, $_.Counts.Top10, $_.Prev, $_.Counts.Quiet }
  $aeoSum | ForEach-Object { "AEO {0,-15} shown {1}/{2} | gained {3} | lost {4} | vs {5}" -f $_.Brand, $_.Shown, $_.Prompts, $_.Gained, $_.Lost, $_.PrevDate }
} finally {
  if ($wb) { $wb.Close($false) | Out-Null }
  $xl.Quit() | Out-Null; [Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
}
