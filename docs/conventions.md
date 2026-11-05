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
