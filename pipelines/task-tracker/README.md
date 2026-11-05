# Task tracker pipeline

`task-tracker.ps1` is the only way agents read or write the marketing task tracker workbook. It uses Excel COM from Windows PowerShell 5.1. No Python or Node.js needed.

The `marketing-task-assistant` agent and the `/tasks` command drive it. You can also run it by hand.

## Files

| File | Purpose |
|---|---|
| `task-tracker.ps1` | `New`, `Dump` and `Apply` actions |
| `webinar-activities.csv` | The standard webinar task set: matrix rows for `New`, and the task list the agent generates for each new webinar |

## Where the tracker lives

`-TrackerPath` if you pass it. Otherwise `<Root>\trackers\Task Tracker Marketing.xlsx`, where `<Root>` is `-Root`, then `$env:MARKETING_ROOT`, then the repo root. A relative `-TrackerPath` is resolved against `<Root>`. Keep the agreed location in `config/paths.md`.

Backups go to a `tracker-backups` folder next to the tracker (override with `-BackupDir`). The newest 20 are kept (`-KeepBackups`).

## Workbook layout

`-Action New` creates this layout. Each sheet holds one Excel table; the script finds tables by sheet name. Sheet names can be overridden with `-TaskSheet`, `-WebinarSheet`, `-CreativeSheet`, `-VideoSheet` and `-ListsSheet`, but column names are fixed.

### `Tasks`, one row per task

| Column | Notes |
|---|---|
| `#` | Unique ID. Set by `add` (max + 1). Never reused or renumbered, except by `renumber` to fix a duplicate. |
| `Requestor` | Who asked for it (optional) |
| `Request Date` | Set to today by `add` |
| `Brand` | Dropdown from `Lists` |
| `Category` | Dropdown from `Lists` |
| `Task Name` | Webinar tasks: `<Mon D> webinar - <Activity>` |
| `Description` | Free text. Webinar tasks: `<Phase>. Who: <Role>` |
| `Priority` | `1-Very High`, `2-High`, `3-Medium`, `4-Low` |
| `Owner` | Dropdown from `Lists` |
| `Status` | `Not Started`, `WIP`, `On Hold`, `Done` |
| `Due Date` | Real date, shown `d-mmm-yy` |
| `Notes` | History is appended as dated lines and never overwritten |

### `Webinar Tasks`, a matrix

Column A `Phase` (filled on the first row of each phase), column B `Activity`, then one column per webinar in date order. Header format: `13 Oct 2026 - <Title>`. Cells hold status. Headers without a year (`13 Oct - Title`, `Sep 23 - Title`) also work: the year starts at `-MatrixStartYear` (default: this year) and rolls forward when the month goes backwards.

### `Creatives`, the creative requirements list

`Brand | Priority | Campaign / Webinar | Creative Requirement | Creative Type | Owner | Needed By | Status | Ref Link | Feedback / Notes | Final Link`. `Creative Requirement` is the match key. `Needed By` is a real date (`d-mmm`). Statuses: `Not Started`, `In Progress`, `Review`, `Approved`, `Published`, `On Hold`.

### `Videos`, video production

`Brand | Type | Video Title | Requested By | Video Editor | Start Date | Target Date | Status | Comments | Link`. `Video Title` is the match key. Statuses: `Not Started`, `In Progress`, `Review`, `Done`. Each webinar gets three rows (recording T+1, summary clip T+2, snippets T+2).

### `Lists`

One column per dropdown: `Brand`, `Category`, `Priority`, `Owner`, `Status`, `Creative Status`, `Video Status`. Dropdowns use dynamic named ranges, so adding a value at the bottom of a column is enough. After `New`, replace `<BRAND>` and `<OWNER>` with your brands (from `brand/company.md`) and people (from `config/team.md`). The dropdowns warn but don't block other values, so legacy data still loads.

## Actions

### New: create a blank tracker

```powershell
.\pipelines\task-tracker\task-tracker.ps1 -Action New
.\pipelines\task-tracker\task-tracker.ps1 -Action New -TrackerPath "trackers\Team Tasks.xlsx"
```

Creates the five sheets above, with the webinar matrix rows taken from `webinar-activities.csv` (rows where `MatrixRow` = `yes`). It refuses to overwrite an existing file. Runs a hidden Excel and closes it.

### Dump: read-only snapshot to CSV

```powershell
.\pipelines\task-tracker\task-tracker.ps1 -Action Dump -OutDir "$env:TEMP\tracker-20261005-0930"
```

Copies the tracker into `-OutDir`, opens the copy read-only and writes:

| File | Columns |
|---|---|
| `tasks.csv` | `SheetRow` + all `Tasks` columns. Dates as `yyyy-MM-dd`. |
| `webinars.csv` | `Webinar, WebinarDate, Phase, Activity, Value`: one line per webinar x activity |
| `creatives.csv` | `SheetRow` + `Creatives` columns (if the sheet exists) |
| `videos.csv` | `SheetRow` + `Videos` columns (if the sheet exists) |

CSV files are UTF-8 with BOM; read them with `Import-Csv`. Use a fresh folder for every dump.

### Apply: change the tracker from a JSON ops file

```powershell
.\pipelines\task-tracker\task-tracker.ps1 -Action Apply -OpsFile "$env:TEMP\ops.json"
.\pipelines\task-tracker\task-tracker.ps1 -Action Apply -OpsFile "$env:TEMP\ops.json" -EditMode Headless
```

Order of work: check every op name and validate every `renumber` op, back up the file, open it, apply the ops in order, save, and print one log line per change. If an op fails, the script stops and nothing is saved by it. In `Window` mode, earlier edits stay unsaved in the open window, so close without saving or fix and re-run. The backup is always there.

**Edit modes**

- `Window` (default): attaches to the tracker open in your own Excel window (found through the Running Object Table, which also finds SharePoint URLs), opening it visibly if needed. Keyboard and mouse input is blocked for the few seconds the edits take, then the workbook is saved there and AutoSave / co-authoring syncs it. Use this for any shared, synced or co-authored file. A headless read-write open of such a file can hang on an invisible prompt, and copying an edited file over the synced path loses to the cloud version.
- `Headless`: opens a hidden Excel, saves and closes. Only for plain local files that are not open anywhere.

Never run two Applies at once, and never run Apply in the background.

**Ops**

```json
[
  {"op":"add","fields":{"Requestor":"","Brand":"<BRAND>","Category":"Webinar",
     "Task Name":"Oct 13 webinar - Add webinar to website","Description":"Planning & Setup. Who: Web / CMS",
     "Priority":"1-Very High","Owner":"<OWNER>","Status":"Not Started","Due Date":"2026-09-25",
     "Notes":"Webinar: 13 Oct 2026 - <Title>"}},

  {"op":"update","id":858,"fields":{"Status":"Done"},"history":"published"},

  {"op":"addWebinar","header":"13 Oct 2026 - <Title>","date":"2026-10-13",
     "cell":"Not Started","skip":["Dry run (if needed)"]},

  {"op":"setWebinarCell","header":"13 Oct 2026 - <Title>","activity":"Send replay emails","value":"Done"},

  {"op":"renumber","sheetRow":118,"oldId":117,"name":"<exact Task Name>","newId":988},

  {"op":"addCreativeRow","fields":{"Brand":"<BRAND>","Priority":"High","Campaign / Webinar":"13 Oct webinar",
     "Creative Requirement":"Webinar LinkedIn banner","Creative Type":"LinkedIn Static","Owner":"<DESIGNER>",
     "Needed By":"2026-09-22","Status":"Not Started"}},
  {"op":"updateCreativeRow","requirement":"Webinar LinkedIn banner","fields":{"Status":"Published"}},

  {"op":"addVideoRow","fields":{"Brand":"<BRAND>","Type":"Video Production",
     "Video Title":"Oct 13 <short title> webinar - recording","Video Editor":"<EDITOR>",
     "Start Date":"2026-10-13","Target Date":"2026-10-14","Status":"Not Started"}},
  {"op":"updateVideoRow","title":"Oct 13 <short title> webinar - recording","fields":{"Status":"Done"}}
]
```

| Op | What it does |
|---|---|
| `add` | Appends a task (reuses a fully blank last row). Sets `#` = max + 1 and `Request Date` = today. |
| `update` | Finds the task by `#`, sets the given fields. Status and Due Date changes, any `history` text and any `Notes` value are appended to Notes as `[dd-Mmm-yy] ...`. Existing notes are never overwritten. |
| `addWebinar` | Adds a matrix column in date order and fills every activity cell with `cell`, except the activities in `skip`. Skips (and logs) if the header already exists. Needs `date`. |
| `setWebinarCell` | Sets one matrix cell by exact header and activity name. |
| `renumber` | Fixes a duplicated `#` on one worksheet row (`SheetRow` from `tasks.csv`). Checks that the row still holds `oldId` + `name` and that `newId` is free, then appends a note. All renumber ops are checked before anything changes. |
| `addCreativeRow` / `addVideoRow` | Adds a row, copying formatting from the last visible non-empty row. Reuses the first visible blank row after it, if any. Hidden placeholder rows are never touched. Date columns are written as real dates. |
| `updateCreativeRow` / `updateVideoRow` | Edits the single row whose key (`Creative Requirement` / `Video Title`) matches exactly. Fails on 0 or 2+ matches. |

Rows are never deleted by the script.

## webinar-activities.csv

`Phase, Activity, DueOffset, Role, MatrixRow, Optional`

- `DueOffset`: working days from the webinar date T (negative = before). The agent moves weekend dates to the Friday before (pre-webinar) or the Monday after (post-webinar).
- `Role`: who does the work, matched to a person in `config/team.md` (Owner, Designer, Web / CMS, Speaker, Video Editor).
- `MatrixRow`: `yes` = row in the `Webinar Tasks` matrix; `no` = task row only (for example the companion page).
- `Optional`: `yes` = created only when asked (the dry run).

Edit the CSV to match your process, for example to swap channel campaigns for the channels in `brand/channels.md`. Keep it plain ASCII. Existing trackers keep their matrix rows; add new activities to the matrix by hand.

## Known pitfalls

- Some labelled workbooks refuse COM opens (generic `0x800A03EC`). If `Dump` fails that way, open the file once in Excel and re-save, or remove the sensitivity label.
- If Excel crashes mid-run, check Task Manager for leftover hidden `EXCEL.EXE` processes; they lock the file.
- Keep this script plain ASCII. PowerShell 5.1 mis-reads non-ASCII characters in BOM-less UTF-8 files.
