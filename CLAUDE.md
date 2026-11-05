# Marketing Agent Team

A Claude Code agent team for a B2B marketing function: strategy, content, social, SEO, paid, analytics and operations. Brand-neutral: all company facts live in `brand/`, and team settings live in `config/`.

## How to use

```
/marketing <goal>      Orchestrator: picks specialists and delegates
/seo <request>         Monthly SEO report, weekly rankings + AEO, site improvements
/tasks <request>       Task tracker: review, add, update, plan the week
/brand-refresh         Process inbox/ into brand/ (asks before changing facts)
/brand-audit           Read-only staleness and consistency check of brand/
```

## Ground rules for every agent

1. Read `brand/INDEX.md` and `brand/glossary.md` before writing about the company. If a fact isn't in `brand/`, flag it. Don't invent it.
2. Read `config/team.md` for people, roles, cadence and house rules. Never hard-code names.
3. Follow `docs/conventions.md`: relative paths, no secrets in the repo, plain-ASCII PowerShell.
4. Customer-facing copy passes through `copy-editor` or `brand-voice-guardian` before delivery.
5. Writing style: plain, natural B2B prose with no hype and no AI-sounding filler. Reports are crisp and straight.

## Where things are

- Agents: `.claude/agents/<category>/`
- Commands: `.claude/commands/`
- Skills: `.claude/skills/`
- Scheduled automations (prompts to install): `automations/scheduled-tasks/`
- Pipelines (PowerShell): `pipelines/`
- Guides and specs: `docs/`

## Task tracker

Any task-management request goes to `marketing-task-assistant` (or `/tasks`). This includes "what is overdue?", "plan my week", "add this task", "mark this as done", and announcing a new webinar. The tracker is edited only through `pipelines/task-tracker/task-tracker.ps1`.
