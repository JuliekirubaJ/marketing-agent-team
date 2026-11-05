# Repo conventions

Every agent, command, skill, automation and pipeline in this repo follows these rules. The repo is **brand-neutral**: it holds no company, product, customer, person or site names.

## 1. Brand context lives in `brand/`, never in agents

Agents never hard-code product facts. They read the brand context files, with paths relative to the repo root:

| File | Holds |
|---|---|
| `brand/INDEX.md` | Map of the brand files. Read this first. |
| `brand/company.md` | Company, products, mission, proof points, customers that may be named |
| `brand/glossary.md` | Canonical terms, banned/deprecated terms, capitalisation rules |
| `brand/voice-and-tone.md` | Voice, tone, style rules, words to avoid |
| `brand/positioning.md` | Positioning, messaging pillars, approved taglines, value props |
| `brand/competitors.md` | Competitor list, differentiators, pricing comparisons (with caveats) |
| `brand/audiences.md` | Personas, ICP, job titles, pain points |
| `brand/claims-and-proof.md` | Approved numbers and claims, with the caveat each one needs |
| `brand/source-authority.md` | Which source wins when sources conflict |
| `brand/channels.md` | Channels in use and channels NOT used, plus communities, groups and subreddits |
| `brand/sources/` | Raw source material (transcripts, docs) |
| `inbox/` | Drop folder processed by `/brand-refresh` |

If a fact is not in `brand/`, agents flag it for verification. They never invent it.

## 2. Team and pipeline settings live in `config/`

| File | Holds |
|---|---|
| `config/team.md` | Owner name, team members and roles, timezone, webinar cadence, standard email sequence, key folders |
| `config/sites.csv` | Websites tracked by the SEO pipeline: `key,domain,ga4_property,gsc_property,clicky_site_id,notes` |
| `config/paths.md` | Where working files live (task tracker, webinar folders, creatives, exports) |

Agents say "the owner (see `config/team.md`)", not a person's name.

## 3. Paths

- No absolute user paths anywhere: no `C:\Users\...` and no OneDrive or SharePoint paths.
- In agents, commands and skills: paths are relative to the repo root (`brand/glossary.md`, `pipelines/seo-reporting/...`).
- In PowerShell scripts: take a `-Root` parameter that defaults to `$env:MARKETING_ROOT`, then to the repo root resolved from `$PSScriptRoot`. Take any other location (tracker file, output folder) as a parameter with a sensible default under the root.
- Secrets (API keys, OAuth tokens) live outside the repo, in `%USERPROFILE%\.marketing-agent-team\`. Scripts read them from there and never print them.

## 4. Placeholders

Where a value must be filled in, use `<ANGLE_BRACKET_PLACEHOLDERS>` in docs and templates, for example `<COMPANY>` or `<PRODUCT>`. Do not use them inside agent logic: point to the brand file instead.

## 5. Agent file format

Claude Code subagent markdown, with frontmatter `name`, `description`, `tools` (and `model` if the original had one). The description says what the agent does and when to use it, with no brand names. Keep the original agent's process, checklists, output formats and hard-won rules. Strip only the brand-specific facts, and turn them into "read X from brand/…" instructions. When an original rule encoded a lesson (for example "the LinkedIn export's Clicks column counts all interactions, not link clicks"), keep the lesson.

## 6. Platform

The pipelines target Windows, PowerShell 5.1, Microsoft Office (Excel, Word and PowerPoint through COM) and Microsoft Edge (headless rendering). Node.js and Python are not required. Keep script string literals plain ASCII, because PowerShell 5.1 mis-reads non-ASCII characters in UTF-8 files that have no BOM.

## 7. Agents are roles, skills are procedures

- **Agent** = a role with judgement (who). Agents live in `.claude/agents/<category>/<name>.md`. Subfolders are fine: Claude Code scans `.claude/agents/` recursively.
- **Skill** = a repeatable procedure (how). Skills live one level deep: `.claude/skills/<skill-name>/SKILL.md`. Nested skill folders are NOT discovered.
- Every agent lists, in a "Skills I use" section, the 3-6 skills it relies on, and names the agents it hands off to and receives from.

### Frontmatter must be valid YAML

Claude Code silently skips an agent or skill whose frontmatter does not parse. Rules:
- Wrap `description` in double quotes whenever it contains `: `, `#`, or starts with `[`, `{`, `"`, `'`, `>`, `|`, `*`, `&`, `!`, `%` or `@`. When in doubt, quote it, and escape any inner double quotes as `\"`.
- Line 1 is `---`. `name` (kebab-case, same as the file or folder name) and `description` are required.

### Skill format (keep each skill to roughly 1-2 pages)

```
---
name: <skill-name>
description: "<what it does>. Use when <triggers>."
---

# <Title>

## When to use
## Inputs            (what to ask the user for, and which brand/ and config/ files to read)
## Steps             (numbered, concrete)
## Output template   (the exact structure to return)
## Quality checks    (glossary terms, claims checked against brand/claims-and-proof.md, plain prose, no invented numbers)
```

Write all text from scratch. Do not copy text from other repositories, even MIT-licensed ones.
