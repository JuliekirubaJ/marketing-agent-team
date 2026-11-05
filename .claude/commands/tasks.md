---
description: Personal marketing task assistant - review, add, update or plan tasks in the task tracker workbook
argument-hint: [request, e.g. "run my task review" | "mark 834 done" | "add webinar 17 Nov - <title>"]
---

Delegate this to the `marketing-task-assistant` agent. Pass the owner's request verbatim, plus today's date and the scratchpad path to use for dumps and ops files:

$ARGUMENTS

If no request was given, treat it as "Run my task review."

The tracker path comes from `config/paths.md` and the owner from `config/team.md`; the agent reads both. If no tracker exists yet, the agent offers to create one with `pipelines/task-tracker/task-tracker.ps1 -Action New`.

When the agent returns, relay its answer as-is: changes made first, then the review or decisions. If it lists decisions, wait for the owner's answers and send them back to the agent to apply.
