<#
.SYNOPSIS
  Marketing task tracker helper (Excel COM). Keep this file plain ASCII.

.DESCRIPTION
  Actions:
    New   : creates a blank tracker workbook with the expected sheets, tables, columns and
            dropdown lists. Refuses to overwrite an existing file.
    Dump  : copies the tracker to -OutDir, opens the copy read-only and writes
            tasks.csv, webinars.csv and (if those sheets exist) creatives.csv and videos.csv.
    Apply : backs up the tracker, then applies the JSON ops in -OpsFile and saves.

  Ops (JSON array of objects, applied in order). Column names are the table headers:
    {"op":"add","fields":{"Requestor":"","Brand":"<BRAND>","Category":"Webinar","Task Name":"...",
       "Description":"","Priority":"2-High","Owner":"<OWNER>","Status":"Not Started",
       "Due Date":"2026-10-06","Notes":""}}
         -> appends a task; "#" = max+1 and "Request Date" = today unless given.
    {"op":"update","id":858,"fields":{"Status":"Done","Due Date":"2026-10-02"},"history":"text"}
         -> updates the task whose "#" = id. Status / Due Date changes and "history" are appended
            to Notes as a dated line; existing notes are never overwritten.
    {"op":"addWebinar","header":"13 Oct 2026 - Title","date":"2026-10-13","cell":"Not Started","skip":["Dry run (if needed)"]}
         -> adds a column to the Webinar Tasks matrix in chronological position and fills each activity cell.
    {"op":"setWebinarCell","header":"13 Oct 2026 - Title","activity":"Send replay emails","value":"Done"}
    {"op":"renumber","sheetRow":118,"oldId":117,"name":"<exact Task Name>","newId":988}
         -> fixes a duplicated "#". Targets the worksheet row (SheetRow in tasks.csv), checks that the row
            still holds oldId + name and that newId is unused. All renumber ops are validated first.
    {"op":"addCreativeRow","fields":{"Brand":"...","Priority":"High","Campaign / Webinar":"...",
       "Creative Requirement":"...","Creative Type":"LinkedIn Static","Owner":"<DESIGNER>",
       "Needed By":"2026-10-13","Status":"Not Started","Ref Link":"","Feedback / Notes":""}}
    {"op":"updateCreativeRow","requirement":"<exact Creative Requirement>","fields":{"Status":"Published"}}
    {"op":"addVideoRow","fields":{"Brand":"...","Type":"Video Production","Video Title":"...",
       "Requested By":"","Video Editor":"<EDITOR>","Start Date":"2026-10-13","Target Date":"2026-10-14",
       "Status":"Not Started","Comments":""}}
    {"op":"updateVideoRow","title":"<exact Video Title>","fields":{"Video Editor":"<EDITOR>","Status":"Done"}}
         -> add*Row copies formatting from the last visible non-empty row and reuses a trailing visible
            blank row if there is one. update*Row edits the single row whose key matches exactly
            (fails if 0 or 2+ match). Rows are never deleted.

  Edit modes for Apply:
    Window   (default) attaches to the workbook open in your own Excel window (opening it visibly if
             needed) and saves there. Required for co-authored, cloud-synced files: a headless
             read-write open of a synced, co-authored file can hang on an invisible prompt, and replacing
             the file on disk loses to the cloud copy.
    Headless opens the file in a hidden Excel, saves and closes. Use only for plain local files.

.EXAMPLE
  .\task-tracker.ps1 -Action New
  .\task-tracker.ps1 -Action Dump -OutDir "$env:TEMP\tracker-20261005-0930"
  .\task-tracker.ps1 -Action Apply -OpsFile "$env:TEMP\ops.json"
#>
param(
  [Parameter(Mandatory=$true)][ValidateSet('New','Dump','Apply')][string]$Action,
  [string]$Root,
  [string]$TrackerPath,
  [string]$OutDir,
  [string]$OpsFile,
  [string]$BackupDir,
  [int]$KeepBackups = 20,
  [ValidateSet('Window','Headless')][string]$EditMode = 'Window',
  [int]$MatrixStartYear = 0,
  [string]$ActivitiesFile,
  [string]$TaskSheet = 'Tasks',
  [string]$WebinarSheet = 'Webinar Tasks',
  [string]$CreativeSheet = 'Creatives',
  [string]$VideoSheet = 'Videos',
  [string]$ListsSheet = 'Lists'
)
$ErrorActionPreference = 'Stop'

# ---------------- Paths ----------------
if (-not $Root) { $Root = $env:MARKETING_ROOT }
if (-not $Root) { $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
if (-not $TrackerPath) { $TrackerPath = Join-Path $Root 'trackers\Task Tracker Marketing.xlsx' }
elseif (-not [System.IO.Path]::IsPathRooted($TrackerPath)) { $TrackerPath = Join-Path $Root $TrackerPath }
if (-not $BackupDir) { $BackupDir = Join-Path (Split-Path -Parent $TrackerPath) 'tracker-backups' }
if (-not $ActivitiesFile) { $ActivitiesFile = Join-Path $PSScriptRoot 'webinar-activities.csv' }
if ($MatrixStartYear -le 0) { $MatrixStartYear = (Get-Date).Year }

# ---------------- Schema ----------------
$TaskColumns     = @('#','Requestor','Request Date','Brand','Category','Task Name','Description','Priority','Owner','Status','Due Date','Notes')
$TaskDateColumns = @('Request Date','Due Date')
$NotesColumn     = 'Notes'
$CreativeColumns = @('Brand','Priority','Campaign / Webinar','Creative Requirement','Creative Type','Owner','Needed By','Status','Ref Link','Feedback / Notes','Final Link')
$VideoColumns    = @('Brand','Type','Video Title','Requested By','Video Editor','Start Date','Target Date','Status','Comments','Link')
$Lists = [ordered]@{
  'Brand'          = @('<BRAND>')
  'Category'       = @('Webinar','Website updates','Campaign','Conference and events','Socials','Content','Creative','SEO','Video Publishing')
  'Priority'       = @('1-Very High','2-High','3-Medium','4-Low')
  'Owner'          = @('<OWNER>')
  'Status'         = @('Not Started','WIP','On Hold','Done')
  'Creative Status'= @('Not Started','In Progress','Review','Approved','Published','On Hold')
  'Video Status'   = @('Not Started','In Progress','Review','Done')
}
$MonthNames = @{jan=1;feb=2;mar=3;apr=4;may=5;jun=6;jul=7;aug=8;sep=9;oct=10;nov=11;dec=12}

# ---------------- Helpers ----------------
function Open-Excel { $x = New-Object -ComObject Excel.Application; $x.Visible=$false; $x.DisplayAlerts=$false; $x.AskToUpdateLinks=$false; return $x }
function Close-Excel($x) { if ($x) { try { $x.Quit() } catch {}; [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($x) } }
function Cell-Text($v) { if ($null -eq $v) { return '' }; return ([string]$v).Trim() }
function Convert-DateCell($v) {
  if ($null -eq $v -or "$v" -eq '') { return '' }
  if ($v -is [double]) { return [DateTime]::FromOADate($v).ToString('yyyy-MM-dd') }
  return ([string]$v).Trim()
}
function Set-Value2($cell, $value) {
  # Late-bound write. Plain '.Value2 =' can fail with 'cannot cast Double to String' after other COM writes in the same process.
  [void]$cell.GetType().InvokeMember('Value2', [System.Reflection.BindingFlags]::SetProperty, $null, $cell, @(,$value))
}
function Test-DateColumn([string]$name) { return ($name -match 'Date' -or $name -eq 'Needed By') }

function Get-HeaderDate([string]$h) {
  # Accepts "13 Oct 2026 - Title", "2026-10-13 - Title", "13 Oct - Title", "9th sep - Title", "Sep 23 - Title".
  $s = $h.ToLower()
  $m = [regex]::Match($s, '^\s*(\d{4})-(\d{1,2})-(\d{1,2})')
  if ($m.Success) { return @{ Year=[int]$m.Groups[1].Value; Month=[int]$m.Groups[2].Value; Day=[int]$m.Groups[3].Value } }
  $m = [regex]::Match($s, '^\s*(\d{1,2})\s*(st|nd|rd|th)?\s*-?\s*([a-z]{3})[a-z]*\.?\s*-?\s*(\d{4})?')
  if ($m.Success) { $d=[int]$m.Groups[1].Value; $mon=$m.Groups[3].Value; $y=$m.Groups[4].Value }
  else {
    $m = [regex]::Match($s, '^\s*([a-z]{3})[a-z]*\.?\s*(\d{1,2})(st|nd|rd|th)?,?\s*(\d{4})?')
    if (-not $m.Success) { return $null }
    $mon=$m.Groups[1].Value; $d=[int]$m.Groups[2].Value; $y=$m.Groups[4].Value
  }
  if (-not $MonthNames.ContainsKey($mon)) { return $null }
  $year = 0; if ($y) { $year = [int]$y }
  return @{ Year=$year; Month=$MonthNames[$mon]; Day=$d }
}

function Get-WebinarDates($headers) {
  # Columns are chronological. A header with a year sets the year; without one, the year rolls
  # forward when the month goes backwards, starting from -MatrixStartYear.
  $year = $MatrixStartYear; $prevMonth = 0; $out = @()
  foreach ($h in $headers) {
    $p = Get-HeaderDate $h
    if ($p) {
      if ($p.Year -gt 0) { $year = $p.Year }
      elseif ($p.Month -lt $prevMonth) { $year++ }
      $prevMonth = $p.Month
      try { $out += (Get-Date -Year $year -Month $p.Month -Day $p.Day).ToString('yyyy-MM-dd') } catch { $out += '' }
    } else { $out += '' }
  }
  return ,$out
}

function Get-Table($wb, [string]$sheetName) {
  foreach ($ws in $wb.Worksheets) { if ($ws.Name -eq $sheetName) { if ($ws.ListObjects.Count -ge 1) { return $ws.ListObjects.Item(1) } } }
  return $null
}

function Export-TableCsv($lo, [string]$file) {
  $hdr = @(); foreach ($c in $lo.HeaderRowRange.Cells) { $hdr += (Cell-Text $c.Value2) }
  $list = New-Object System.Collections.Generic.List[object]
  if ($lo.DataBodyRange) {
    $data = $lo.DataBodyRange.Value2
    $rows = $data.GetUpperBound(0); $cols = $data.GetUpperBound(1)
    for ($r=1; $r -le $rows; $r++) {
      $o = [ordered]@{ SheetRow = $lo.DataBodyRange.Row + $r - 1 }
      $any = $false
      for ($c=1; $c -le $cols; $c++) {
        $name = $hdr[$c-1]; $v = $data[$r,$c]
        if (Test-DateColumn $name) { $o[$name] = Convert-DateCell $v } else { $o[$name] = Cell-Text $v }
        if ($o[$name] -ne '') { $any = $true }
      }
      if ($any) { $list.Add([pscustomobject]$o) }
    }
  }
  $list | Export-Csv -LiteralPath $file -NoTypeInformation -Encoding UTF8
  return $list.Count
}

# ---------------- New ----------------
if ($Action -eq 'New') {
  if (Test-Path -LiteralPath $TrackerPath) { throw "Tracker already exists: $TrackerPath. Nothing was changed." }
  if (-not (Test-Path -LiteralPath $ActivitiesFile)) { throw "Activities file not found: $ActivitiesFile" }
  $acts = @(Import-Csv -LiteralPath $ActivitiesFile | Where-Object { $_.MatrixRow -eq 'yes' })
  New-Item -ItemType Directory -Force (Split-Path -Parent $TrackerPath) | Out-Null
  $excel = Open-Excel
  try {
    $wb = $excel.Workbooks.Add()
    while ($wb.Worksheets.Count -lt 5) { [void]$wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
    $names = @($TaskSheet, $WebinarSheet, $CreativeSheet, $VideoSheet, $ListsSheet)
    for ($k=0; $k -lt 5; $k++) { $wb.Worksheets.Item($k+1).Name = $names[$k] }

    # Lists sheet + dynamic named ranges for dropdowns
    $wsL = $wb.Worksheets.Item($ListsSheet); $col = 1
    $rangeNames = @{}
    foreach ($key in $Lists.Keys) {
      $wsL.Cells.Item(1, $col).Value2 = $key
      $vals = $Lists[$key]
      for ($r=0; $r -lt $vals.Count; $r++) { $wsL.Cells.Item($r+2, $col).Value2 = [string]$vals[$r] }
      $letter = $wsL.Cells.Item(1, $col).Address($false, $false) -replace '\d',''
      $rn = 'List_' + ($key -replace '[^A-Za-z]','')
      [void]$wb.Names.Add($rn, "=OFFSET('$ListsSheet'!`$$letter`$2,0,0,MAX(1,COUNTA('$ListsSheet'!`$$letter`:`$$letter)-1),1)")
      $rangeNames[$key] = $rn
      $col++
    }
    $wsL.Rows.Item(1).Font.Bold = $true

    function New-Table($ws, [string[]]$cols, [string]$tableName) {
      for ($k=0; $k -lt $cols.Count; $k++) { $ws.Cells.Item(1, $k+1).Value2 = $cols[$k] }
      $rng = $ws.Range($ws.Cells.Item(1,1), $ws.Cells.Item(2, $cols.Count))
      $lo = $ws.ListObjects.Add(1, $rng, $null, 1)
      $lo.Name = $tableName
      return $lo
    }
    function Set-ListValidation($lo, [string]$colName, [string]$listName) {
      $v = $lo.ListColumns.Item($colName).DataBodyRange.Validation
      $v.Delete(); $v.Add(3, 1, 1, "=$listName"); $v.ShowError = $false
    }

    $lo = New-Table $wb.Worksheets.Item($TaskSheet) $TaskColumns 'TaskTable'
    foreach ($c in $TaskDateColumns) { $lo.ListColumns.Item($c).DataBodyRange.NumberFormat = 'd-mmm-yy' }
    foreach ($c in @('Brand','Category','Priority','Owner','Status')) { Set-ListValidation $lo $c $rangeNames[$c] }

    $wsW = $wb.Worksheets.Item($WebinarSheet)
    $wsW.Cells.Item(1,1).Value2 = 'Phase'; $wsW.Cells.Item(1,2).Value2 = 'Activity'
    $prev = ''; $r = 2
    foreach ($a in $acts) {
      if ($a.Phase -ne $prev) { $wsW.Cells.Item($r,1).Value2 = $a.Phase; $prev = $a.Phase }
      $wsW.Cells.Item($r,2).Value2 = $a.Activity; $r++
    }
    $lastRow = [Math]::Max(2, $r - 1)
    $lo2 = $wsW.ListObjects.Add(1, $wsW.Range($wsW.Cells.Item(1,1), $wsW.Cells.Item($lastRow,2)), $null, 1)
    $lo2.Name = 'WebinarMatrix'

    $lo3 = New-Table $wb.Worksheets.Item($CreativeSheet) $CreativeColumns 'CreativeTable'
    $lo3.ListColumns.Item('Needed By').DataBodyRange.NumberFormat = 'd-mmm'
    Set-ListValidation $lo3 'Status' $rangeNames['Creative Status']

    $lo4 = New-Table $wb.Worksheets.Item($VideoSheet) $VideoColumns 'VideoTable'
    foreach ($c in @('Start Date','Target Date')) { $lo4.ListColumns.Item($c).DataBodyRange.NumberFormat = 'd-mmm' }
    Set-ListValidation $lo4 'Status' $rangeNames['Video Status']

    foreach ($ws in $wb.Worksheets) { [void]$ws.UsedRange.Columns.AutoFit() }
    $wb.Worksheets.Item($TaskSheet).Activate()
    $wb.SaveAs($TrackerPath, 51)
    $wb.Close($false)
    "Created $TrackerPath with sheets: $($names -join ', ') ($($acts.Count) webinar activities)."
    "Next: edit the '$ListsSheet' sheet to set your brands and owners."
  } finally { Close-Excel $excel }
  return
}

if (-not (Test-Path -LiteralPath $TrackerPath)) { throw "Tracker not found: $TrackerPath. Create one with -Action New or pass -TrackerPath." }

# ---------------- Dump ----------------
if ($Action -eq 'Dump') {
  if (-not $OutDir) { throw 'Dump needs -OutDir (use a fresh folder each time)' }
  New-Item -ItemType Directory -Force $OutDir | Out-Null
  $tmp = Join-Path $OutDir 'tracker-snapshot.xlsx'
  Copy-Item -LiteralPath $TrackerPath -Destination $tmp -Force
  $excel = Open-Excel
  try {
    $wb = $excel.Workbooks.Open($tmp, 0, $true)
    $lo = Get-Table $wb $TaskSheet
    if (-not $lo) { throw "Sheet '$TaskSheet' with a table not found" }
    $nTasks = Export-TableCsv $lo (Join-Path $OutDir 'tasks.csv')

    $lo2 = Get-Table $wb $WebinarSheet
    $wl = New-Object System.Collections.Generic.List[object]
    $headers = @()
    if ($lo2) {
      $m = $lo2.Range.Value2
      $mr = $m.GetUpperBound(0); $mc = $m.GetUpperBound(1)
      for ($c=3; $c -le $mc; $c++) { $headers += (Cell-Text $m[1,$c]) }
      $dates = Get-WebinarDates $headers
      $phase = ''
      for ($r=2; $r -le $mr; $r++) {
        if ((Cell-Text $m[$r,1]) -ne '') { $phase = Cell-Text $m[$r,1] }
        for ($c=3; $c -le $mc; $c++) {
          $wl.Add([pscustomobject][ordered]@{ Webinar=$headers[$c-3]; WebinarDate=$dates[$c-3]; Phase=$phase; Activity=(Cell-Text $m[$r,2]); Value=(Cell-Text $m[$r,$c]) })
        }
      }
    }
    $wl | Export-Csv -LiteralPath (Join-Path $OutDir 'webinars.csv') -NoTypeInformation -Encoding UTF8

    $extra = @()
    $lo3 = Get-Table $wb $CreativeSheet
    if ($lo3) { $n = Export-TableCsv $lo3 (Join-Path $OutDir 'creatives.csv'); $extra += "$n creatives" }
    $lo4 = Get-Table $wb $VideoSheet
    if ($lo4) { $n = Export-TableCsv $lo4 (Join-Path $OutDir 'videos.csv'); $extra += "$n videos" }
    $wb.Close($false)
    "Dumped $nTasks tasks, $($headers.Count) webinars" + $(if ($extra) { ', ' + ($extra -join ', ') } else { '' }) + " to $OutDir (tracker last saved $((Get-Item -LiteralPath $TrackerPath).LastWriteTime))"
  } finally { Close-Excel $excel }
  return
}

# ---------------- Apply ----------------
if (-not $OpsFile) { throw 'Apply needs -OpsFile' }
$ops = [System.IO.File]::ReadAllText($OpsFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
if ($ops -isnot [System.Array]) { $ops = @($ops) }
$knownOps = @('add','update','addWebinar','setWebinarCell','renumber','addCreativeRow','updateCreativeRow','addVideoRow','updateVideoRow')
foreach ($op in $ops) { if ($knownOps -notcontains $op.op) { throw "Unknown op '$($op.op)'. Nothing was changed." } }

# Backup first, keep the newest $KeepBackups
New-Item -ItemType Directory -Force $BackupDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($TrackerPath)
$backupFile = Join-Path $BackupDir "$baseName $stamp.xlsx"
Copy-Item -LiteralPath $TrackerPath -Destination $backupFile -Force
Get-ChildItem -LiteralPath $BackupDir -Filter "$baseName *.xlsx" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $KeepBackups | Remove-Item -Force

$today = (Get-Date).Date
$todayTxt = $today.ToString('dd-MMM-yy')
$fileName = [System.IO.Path]::GetFileName($TrackerPath)

if (-not ('TrackerRot' -as [type])) {
Add-Type -TypeDefinition @'
using System; using System.Collections.Generic; using System.Runtime.InteropServices; using System.Runtime.InteropServices.ComTypes;
public static class TrackerRot {
  [DllImport("ole32.dll")] static extern int GetRunningObjectTable(int r, out IRunningObjectTable t);
  [DllImport("ole32.dll")] static extern int CreateBindCtx(int r, out IBindCtx c);
  public static List<object> Find(string suffix) {
    var res = new List<object>(); IRunningObjectTable rot; IEnumMoniker en; IBindCtx ctx;
    GetRunningObjectTable(0, out rot); CreateBindCtx(0, out ctx); rot.EnumRunning(out en);
    IMoniker[] m = new IMoniker[1];
    while (en.Next(1, m, IntPtr.Zero) == 0) {
      string name; try { m[0].GetDisplayName(ctx, null, out name); } catch { continue; }
      string n = Uri.UnescapeDataString(name ?? "").Replace('/', '\\');
      if (n.EndsWith(suffix, StringComparison.OrdinalIgnoreCase)) { object o; rot.GetObject(m[0], out o); res.Add(o); }
    }
    return res;
  }
}
'@
}
function Find-OpenTracker {
  # The Running Object Table lists each open workbook (local path or SharePoint URL) in whichever
  # Excel instance owns it. GetActiveObject can return a hidden, empty instance instead.
  foreach ($o in [TrackerRot]::Find('\' + $fileName)) { try { if ($o.Name -eq $fileName) { return $o } } catch {} }
  return $null
}

$wb = Find-OpenTracker
$ownExcel = $null
if ($EditMode -eq 'Window') {
  if (-not $wb) {
    Start-Process -FilePath $TrackerPath
    for ($k=0; $k -lt 45 -and -not $wb; $k++) { Start-Sleep -Seconds 2; $wb = Find-OpenTracker }
    if (-not $wb) { throw "Could not find '$fileName' open in Excel. Open the tracker in Excel and re-run. Nothing was changed." }
  }
} else {
  if ($wb) { throw "'$fileName' is open in Excel. Close it, or use -EditMode Window. Nothing was changed." }
  $ownExcel = Open-Excel
  $wb = $ownExcel.Workbooks.Open($TrackerPath)
}
if ($wb.ReadOnly) { if ($ownExcel) { Close-Excel $ownExcel }; throw 'The tracker opened read-only (Enable Editing / file lock). Nothing was changed.' }
$excel = $wb.Application
if (-not $ownExcel) { $excel.Interactive = $false }   # block clicks/typing for the few seconds the edits take
try {
  $lo = Get-Table $wb $TaskSheet
  if (-not $lo) { throw "Sheet '$TaskSheet' with a table not found" }
  $ws = $lo.Range.Worksheet
  $colIx = @{}; $i=1; foreach ($c in $lo.HeaderRowRange.Cells) { $colIx[(Cell-Text $c.Value2)] = $i; $i++ }

  function Set-Field($row, [string]$name, $val) {
    if (-not $colIx.ContainsKey($name)) { throw "Unknown column '$name' on '$TaskSheet'" }
    $cell = $ws.Cells.Item($row, $lo.Range.Column + $colIx[$name] - 1)
    if (($TaskDateColumns -contains $name) -and "$val" -ne '') {
      Set-Value2 $cell ([DateTime]::Parse("$val")).ToOADate(); $cell.NumberFormat = 'd-mmm-yy'
    } else { Set-Value2 $cell ([string]$val) }
  }
  function Get-Field($row, [string]$name) { return $ws.Cells.Item($row, $lo.Range.Column + $colIx[$name] - 1).Value2 }
  function Get-IdList {
    # Values of the "#" column in sheet order (index 0 = first data row).
    $out = New-Object System.Collections.ArrayList
    if ($lo.DataBodyRange) {
      $v = $lo.ListColumns.Item('#').DataBodyRange.Value2
      if ($v -is [System.Array]) { for ($k=1; $k -le $v.GetUpperBound(0); $k++) { $x = $v[$k,1]; [void]$out.Add($x) } }
      else { [void]$out.Add($v) }
    }
    return ,$out
  }
  function Find-RowById($id) {
    $ids = Get-IdList
    for ($k=0; $k -lt $ids.Count; $k++) { $v = $ids[$k]; if ("$v" -ne '' -and [double]$v -eq [double]$id) { return $lo.DataBodyRange.Row + $k } }
    return $null
  }
  function Get-NewTaskRow {
    # Reuse a fully blank last row (a new workbook starts with one); otherwise append.
    if ($lo.DataBodyRange) {
      $last = $lo.DataBodyRange.Rows.Item($lo.DataBodyRange.Rows.Count)
      if ($excel.WorksheetFunction.CountA($last) -eq 0) { return $last.Row }
    }
    return $lo.ListRows.Add().Range.Row
  }

  # Pre-flight: validate every renumber op before changing anything.
  $preIds = @{}
  foreach ($v in (Get-IdList)) { $n = 0; if ([double]::TryParse("$v", [ref]$n)) { $preIds[$n] = 1 } }
  foreach ($op in @($ops | Where-Object { $_.op -eq 'renumber' })) {
    $firstRow = $lo.DataBodyRange.Row; $lastRow = $firstRow + $lo.DataBodyRange.Rows.Count - 1
    $r = [int]$op.sheetRow
    if ($r -lt $firstRow -or $r -gt $lastRow) { throw "renumber: row $r is outside the table. Nothing was changed." }
    $cid = Get-Field $r '#'; $cname = Cell-Text (Get-Field $r 'Task Name')
    if ("$cid" -eq '' -or [double]$cid -ne [double]$op.oldId -or $cname -ne ([string]$op.name).Trim()) { throw "renumber: row $r is #$cid '$cname', expected #$($op.oldId) '$($op.name)'. Nothing was changed." }
    if ($preIds.ContainsKey([double]$op.newId)) { throw "renumber: #$($op.newId) is already in use. Nothing was changed." }
    $preIds[[double]$op.newId] = 1
  }

  function Copy-RowFormat($wsX, $src, $row, $c0, $ncol) {
    $wsX.Rows.Item($row).Hidden = $false; $wsX.Rows.Item($row).RowHeight = $wsX.Rows.Item($src).RowHeight
    for ($k=0; $k -lt $ncol; $k++) {
      $s = $wsX.Cells.Item($src, $c0 + $k); $d = $wsX.Cells.Item($row, $c0 + $k)
      $d.Font.Name = $s.Font.Name; $d.Font.Size = $s.Font.Size; $d.Font.Bold = $s.Font.Bold; $d.Font.Color = $s.Font.Color
      $d.Interior.ColorIndex = $s.Interior.ColorIndex; $d.WrapText = $s.WrapText; $d.NumberFormat = $s.NumberFormat
      $d.HorizontalAlignment = $s.HorizontalAlignment; $d.VerticalAlignment = $s.VerticalAlignment
    }
  }

  function Add-SheetRow([string]$sheetName, [string]$keyCol, $fields, [string]$dateFmt) {
    $t = Get-Table $wb $sheetName
    if (-not $t) { throw "Sheet '$sheetName' with a table not found" }
    $wsX = $t.Range.Worksheet
    $cix = @{}; $i=1; foreach ($c in $t.HeaderRowRange.Cells) { $cix[(Cell-Text $c.Value2)] = $i; $i++ }
    foreach ($p in $fields.PSObject.Properties) { if (-not $cix.ContainsKey($p.Name)) { throw "${sheetName}: unknown column '$($p.Name)'" } }
    $c0 = $t.Range.Column; $ncol = $t.ListColumns.Count
    $cK = $c0 + $cix[$keyCol] - 1
    $row = $null; $src = $null
    if ($t.DataBodyRange) {
      $first = $t.DataBodyRange.Row; $last = $first + $t.DataBodyRange.Rows.Count - 1
      for ($r = $last; $r -ge $first; $r--) {
        if (-not $wsX.Rows.Item($r).Hidden -and (Cell-Text $wsX.Cells.Item($r, $cK).Value2) -ne '') { $src = $r; break }
      }
      # Reuse the first visible, fully blank row after the source row (placeholder rows), never hidden ones.
      $start = $(if ($src) { $src + 1 } else { $first })
      for ($r = $start; $r -le $last -and -not $row; $r++) {
        $blank = ($excel.WorksheetFunction.CountA($wsX.Range($wsX.Cells.Item($r, $c0), $wsX.Cells.Item($r, $c0 + $ncol - 1))) -eq 0)
        if ($blank -and -not $wsX.Rows.Item($r).Hidden) { $row = $r }
      }
    }
    if (-not $row) { $row = $t.ListRows.Add().Range.Row }
    if ($src) { Copy-RowFormat $wsX $src $row $c0 $ncol }
    foreach ($p in $fields.PSObject.Properties) {
      $d = $wsX.Cells.Item($row, $c0 + $cix[$p.Name] - 1)
      if (Test-DateColumn $p.Name) {
        if ("$($p.Value)" -ne '') { Set-Value2 $d ([DateTime]::Parse("$($p.Value)")).ToOADate() }
        if ($d.NumberFormat -eq 'General') { $d.NumberFormat = $dateFmt }
      } else { Set-Value2 $d ([string]$p.Value) }
    }
    return "ADD ROW $row on '$sheetName'" + $(if ($src) { " (format from row $src)" } else { '' }) + ": $($fields.$keyCol)"
  }

  function Update-SheetRow([string]$sheetName, [string]$keyCol, [string]$key, $fields) {
    $t = Get-Table $wb $sheetName
    if (-not $t) { throw "Sheet '$sheetName' with a table not found" }
    $wsX = $t.Range.Worksheet
    $cix = @{}; $i=1; foreach ($c in $t.HeaderRowRange.Cells) { $cix[(Cell-Text $c.Value2)] = $i; $i++ }
    foreach ($p in $fields.PSObject.Properties) { if (-not $cix.ContainsKey($p.Name)) { throw "${sheetName}: unknown column '$($p.Name)'" } }
    $c0 = $t.Range.Column; $cK = $c0 + $cix[$keyCol] - 1
    $first = $t.DataBodyRange.Row; $last = $first + $t.DataBodyRange.Rows.Count - 1
    $hits = @(); for ($r = $first; $r -le $last; $r++) { if ((Cell-Text $wsX.Cells.Item($r, $cK).Value2) -eq $key.Trim()) { $hits += $r } }
    if ($hits.Count -ne 1) { throw "${sheetName}: '$key' matched $($hits.Count) rows (need exactly 1)" }
    $row = $hits[0]; $chg = @()
    foreach ($p in $fields.PSObject.Properties) {
      $d = $wsX.Cells.Item($row, $c0 + $cix[$p.Name] - 1); $old = $d.Text
      if (Test-DateColumn $p.Name) {
        if ("$($p.Value)" -ne '') { Set-Value2 $d ([DateTime]::Parse("$($p.Value)")).ToOADate() } else { Set-Value2 $d $null }
      } else { Set-Value2 $d ([string]$p.Value) }
      $chg += "$($p.Name): '$old' -> '$($d.Text)'"
    }
    return "UPDATE ROW $row on '$sheetName' [$key]: " + ($chg -join '; ')
  }

  function Get-MatrixHeaders($t) { $h = @(); for ($c=3; $c -le $t.ListColumns.Count; $c++) { $h += [string]$t.ListColumns.Item($c).Name }; return ,$h }

  $log = @()
  foreach ($op in $ops) {
    switch ($op.op) {
      'add' {
        $max = 0
        foreach ($v in (Get-IdList)) { $n=0; if ([double]::TryParse("$v", [ref]$n) -and $n -gt $max) { $max=$n } }
        $row = Get-NewTaskRow
        Set-Field $row '#' ([int]$max + 1)
        Set-Field $row 'Request Date' $today.ToString('yyyy-MM-dd')
        foreach ($p in $op.fields.PSObject.Properties) { Set-Field $row $p.Name $p.Value }
        $log += "ADD #$([int]$max+1): $($op.fields.'Task Name')"
      }
      'update' {
        $row = Find-RowById $op.id
        if (-not $row) { throw "Task #$($op.id) not found" }
        $changes = @()
        foreach ($p in $op.fields.PSObject.Properties) {
          if ($p.Name -eq $NotesColumn) { continue }
          $old = Get-Field $row $p.Name
          if (($TaskDateColumns -contains $p.Name) -and $old -is [double]) { $old = [DateTime]::FromOADate($old).ToString('dd-MMM-yy') }
          $newTxt = "$($p.Value)"
          if (($TaskDateColumns -contains $p.Name) -and $newTxt -ne '') { $newTxt = ([DateTime]::Parse($newTxt)).ToString('dd-MMM-yy') }
          if ("$old" -ne $newTxt) { $changes += "$($p.Name): '$old' -> '$newTxt'" }
          Set-Field $row $p.Name $p.Value
        }
        $hist = @()
        if ($op.history) { $hist += $op.history }
        $keyChanges = @($changes | Where-Object { $_ -like 'Status:*' -or $_ -like 'Due Date:*' })
        if ($keyChanges.Count -gt 0) { $hist += ($keyChanges -join '; ') }
        if ($op.fields.PSObject.Properties.Name -contains $NotesColumn) { $hist += [string]$op.fields.$NotesColumn }
        if ($hist.Count -gt 0) {
          $oldNotes = Cell-Text (Get-Field $row $NotesColumn)
          $line = "[$todayTxt] " + ($hist -join ' | ')
          $newNotes = if ($oldNotes) { "$oldNotes`n$line" } else { $line }
          Set-Field $row $NotesColumn $newNotes
        }
        $log += "UPDATE #$($op.id): " + ($changes -join '; ')
      }
      'addWebinar' {
        $lo2 = Get-Table $wb $WebinarSheet
        if (-not $lo2) { throw "Sheet '$WebinarSheet' with a table not found" }
        $headers = Get-MatrixHeaders $lo2
        if ($headers | Where-Object { $_.Trim() -eq $op.header.Trim() }) { $log += "SKIP addWebinar (exists): $($op.header)"; break }
        if (-not $op.date) { throw 'addWebinar needs "date" (yyyy-MM-dd)' }
        $dates = Get-WebinarDates $headers
        $newDate = ([DateTime]::Parse($op.date)).ToString('yyyy-MM-dd'); $pos = $lo2.ListColumns.Count + 1
        for ($k=0; $k -lt $headers.Count; $k++) { if ($dates[$k] -and $dates[$k] -gt $newDate) { $pos = $k + 3; break } }
        $col = $lo2.ListColumns.Add($pos); $col.Name = $op.header
        $acts = $lo2.ListColumns.Item(2).DataBodyRange.Value2
        for ($k=1; $k -le $acts.GetUpperBound(0); $k++) {
          $a = Cell-Text $acts[$k,1]
          if ($a -eq '' -or ($op.skip -and ($op.skip -contains $a))) { continue }
          Set-Value2 $col.DataBodyRange.Cells.Item($k,1) ([string]$op.cell)
        }
        $log += "ADD WEBINAR COLUMN at position ${pos}: $($op.header)"
      }
      'setWebinarCell' {
        $lo2 = Get-Table $wb $WebinarSheet
        if (-not $lo2) { throw "Sheet '$WebinarSheet' with a table not found" }
        $col = $null; for ($c=3; $c -le $lo2.ListColumns.Count; $c++) { if (([string]$lo2.ListColumns.Item($c).Name).Trim() -eq $op.header.Trim()) { $col = $lo2.ListColumns.Item($c) } }
        if (-not $col) { throw "Webinar column not found: $($op.header)" }
        $acts = $lo2.ListColumns.Item(2).DataBodyRange.Value2; $hit = $false
        for ($k=1; $k -le $acts.GetUpperBound(0); $k++) {
          if ((Cell-Text $acts[$k,1]) -eq $op.activity.Trim()) { Set-Value2 $col.DataBodyRange.Cells.Item($k,1) ([string]$op.value); $hit = $true }
        }
        if (-not $hit) { throw "Activity not found: $($op.activity)" }
        $log += "SET [$($op.header)] $($op.activity) = $($op.value)"
      }
      'renumber' {
        $row = [int]$op.sheetRow
        Set-Value2 $ws.Cells.Item($row, $lo.Range.Column + $colIx['#'] - 1) ([double]$op.newId)
        $oldNotes = Cell-Text (Get-Field $row $NotesColumn)
        $line = "[$todayTxt] Renumbered #$($op.oldId) -> #$($op.newId) (duplicate #)"
        Set-Field $row $NotesColumn $(if ($oldNotes) { "$oldNotes`n$line" } else { $line })
        $log += "RENUMBER row ${row}: #$($op.oldId) -> #$($op.newId) $($op.name)"
      }
      'addCreativeRow'    { $log += Add-SheetRow $CreativeSheet 'Creative Requirement' $op.fields 'd-mmm' }
      'updateCreativeRow' { $log += Update-SheetRow $CreativeSheet 'Creative Requirement' ([string]$op.requirement) $op.fields }
      'addVideoRow'       { $log += Add-SheetRow $VideoSheet 'Video Title' $op.fields 'd-mmm' }
      'updateVideoRow'    { $log += Update-SheetRow $VideoSheet 'Video Title' ([string]$op.title) $op.fields }
    }
  }
  $wb.Save()
  $log
  if ($ownExcel) { "Saved $TrackerPath. Backup: $backupFile" } else { "Saved in the open Excel window. Backup: $backupFile" }
} finally {
  if ($ownExcel) { try { $wb.Close($false) } catch {}; Close-Excel $ownExcel }
  else { try { $excel.Interactive = $true } catch {} }
}
