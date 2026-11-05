---
name: social-follower-weekly-check
description: Weekly Monday reminder asking the owner for this week's follower counts for each tracked social page, and how to record them once they reply
---

<!-- Suggested schedule: Mondays 09:00 local time. Cron: 0 9 * * 1 -->

This is a weekly reminder. Your only job on this run is to ask the owner (see `config/team.md`) for this week's follower counts. Do NOT try to update any file in this run: the owner hasn't given you the numbers yet, and this run cannot wait for a reply.

The pages to ask about are the sheet names in the follower tracker. Read them from `config/paths.md` / `brand/channels.md` (the tracked social pages). If neither lists them, ask for "each page you track".

Steps:
1. If a notification tool is available, send a short one: "Weekly check: social follower counts".
2. Post a chat message asking the owner to check each page's admin analytics (for LinkedIn: Page admin view > Analytics > Followers) and reply with the counts in a simple format, for example:
   `Company: 16600, Product: 5950`
   Mention that post counts for the week are optional, for example `Company: 16600 / 3 posts`.
3. Note that this feeds the follower tracker workbook named in `config/paths.md` (default `trackers/Social Media Followers.xlsx` under `$env:MARKETING_ROOT` or the repo root), one sheet per page.

When the owner DOES reply with the numbers (in a later message, possibly a different run), record them with:

```powershell
& "pipelines/social-tracking/update-follower-count.ps1" -Counts @{ '<Page A>' = <count>; '<Page B>' = <count> }
# optional post counts:
#   -Posts @{ '<Page A>' = <posts> }
# if a page name differs from its sheet name:
#   -SheetMap @{ '<Page A>' = '<Sheet name>' }
```

The script finds the next unfilled row on each sheet (the Date column is pre-filled for future weeks), writes the Followers value and the "% Growth WoW" formula `=(B{row}-B{prevRow})/B{row}*100` (the sheet's own convention), and refuses to overwrite a row that already has a value. It checks every page before writing anything. Details are in `pipelines/social-tracking/README.md`.

After running it, report the before/after follower counts and % growth it printed, and confirm the row date is this week's Monday. Don't claim success without running the script and reading its output.

If the script errors (for example "refusing to overwrite", "row does not exist" or "No sheet named"), stop and tell the owner exactly what it said. Don't patch the XML by hand.
