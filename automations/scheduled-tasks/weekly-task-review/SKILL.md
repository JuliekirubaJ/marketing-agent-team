---
name: weekly-task-review
description: Monday morning read-only review of the owner's marketing task tracker - overdue, this week, next week, blocked / on hold, backlog, webinar actions, decisions
---

<!-- Suggested schedule: Mondays 09:30 local time. Cron: 30 9 * * 1 -->

Run the owner's weekly marketing task review. The owner is named in `config/team.md`.

Paths below are relative to the repo root. If `$env:MARKETING_ROOT` is set, the tracker and other working files live under that folder; the script resolves this itself.

1. Read `.claude/agents/operations/marketing-task-assistant.md` and follow it exactly. It defines the tracker, the helper script, the buckets and the output format. Also read `config/team.md` and `config/paths.md`.
2. Dump the latest tracker into a fresh temp folder:
   `& "pipelines/task-tracker/task-tracker.ps1" -Action Dump -OutDir "<a fresh temp folder>"`
   Build the review from `tasks.csv` and `webinars.csv` (and `videos.csv` / `creatives.csv` if present), using today's real date.
3. This is a read-only run. Do NOT apply any changes to the tracker. Rescheduling, status changes and webinar task-set generation are all presented as numbered Decisions Needed.
4. Output "Weekly Marketing Task Review - w/c <Monday date>" in the agent's format: Overdue, This Week, Next Week, Blocked / On Hold, Backlog, Upcoming Webinar Actions (including missing webinar task sets), Decisions Needed. Put the task `#` on every line. Keep it concise.
5. If a notification tool is available, send a short one: "Weekly task review ready: X overdue, Y due this week, Z decisions."

If the dump fails (tracker missing, locked, or refuses to open), say exactly what the script printed and stop. Don't try to read the workbook another way.
