# Social follower tracking

`update-follower-count.ps1` logs each week's follower counts for your social pages (for example a company page and a product page) into a tracker workbook, one sheet per page.

The weekly reminder lives in `automations/scheduled-tasks/social-follower-weekly-check/`.

## Workbook layout

Default path: `<Root>\trackers\Social Media Followers.xlsx`, where `<Root>` is `-Root`, then `$env:MARKETING_ROOT`, then the repo root (see `config/paths.md`). Override with `-TrackerPath`.

One sheet per page, named after the page. Row 1 holds headers; data starts at row 2.

| Column | Content |
|---|---|
| A | Date: Monday of each week. Pre-fill it weeks or months ahead. |
| B | Followers |
| C | % Growth WoW: `=(B{row}-B{prevRow})/B{row}*100` |
| D | Posts that week (optional) |

Column C divides by the current week, not the previous one. That is the convention of the tracker this was built for, and the script keeps it so old and new rows stay comparable. Change both the sheet and the script if you want the usual `/B{prevRow}`.

To start a new tracker: create the sheets in Excel, pre-fill column A with Mondays, and enter the first week's follower count in B2 by hand. The script needs at least one existing value to compare against.

## Usage

```powershell
# Several pages at once
.\pipelines\social-tracking\update-follower-count.ps1 -Counts @{ 'Company' = 16600; 'Product' = 5950 }

# With post counts
.\pipelines\social-tracking\update-follower-count.ps1 -Counts @{ 'Company' = 16600; 'Product' = 5950 } -Posts @{ 'Company' = 3 }

# One page
.\pipelines\social-tracking\update-follower-count.ps1 -Page 'Company' -Count 16600 -PostCount 3

# Page name differs from the sheet name
.\pipelines\social-tracking\update-follower-count.ps1 -Counts @{ 'Company' = 16600 } -SheetMap @{ 'Company' = 'Corporate page' }

# Preview only
.\pipelines\social-tracking\update-follower-count.ps1 -Counts @{ 'Company' = 16600 } -WhatIf
```

Output, one line per page:

```
Company: row 86 | 16494 to 16600 followers (+0.64 pct WoW)
```

## How it works and why

- It finds the last row with a Followers value and writes into the next row: B, C (formula plus a matching cached value, so it shows correctly without a recalc) and, if given, D. Cell styles are copied from the previous filled row.
- **It never overwrites.** If the next row already has a value in B, C or D, it stops. Re-running after a successful write simply moves on to the following week's row, so check the date in the output.
- If the next row does not exist (column A not pre-filled that far), it stops. Pass `-AddMissingRow` to create the row with the Monday of the current week.
- All pages are checked before anything is written. An unknown sheet name or a refused row means nothing changes.
- It edits the `.xlsx` as a zip archive and rewrites only the worksheet parts it changes; sheet names are mapped to parts through `xl/workbook.xml`. Styles, shared strings, other sheets and data connections stay byte-for-byte untouched. This is on purpose: Excel COM can hang on a workbook with live data connections (an invisible "data connection" prompt it can't dismiss), and labelled files can refuse COM opens.
- Close the workbook in Excel before running, and let a synced copy finish syncing. The script needs exclusive write access to the file.

## Where the numbers come from

LinkedIn: Page admin view > Analytics > Followers (total followers). Use the same source and the same day each week, so week-on-week changes mean something.
