# Marketing Agent Team for Claude Code

A complete B2B marketing team that runs inside [Claude Code](https://claude.com/claude-code). It has 19 specialist agents, an orchestrator, scheduled automations, and PowerShell pipelines for SEO reporting, task tracking, creatives and video.

The repo is **brand-neutral**. You fill in your company's facts once in `brand/` and your team in `config/`, and every agent works from them.

---

## Quick start

1. Clone the repo and open the folder in Claude Code.
2. Fill in `brand/` (start with `company.md`, `glossary.md`, `voice-and-tone.md`, `channels.md`) and `config/team.md`.
3. Try it:
   ```
   /marketing Plan the promotion for our next webinar on <topic>
   /marketing Write a LinkedIn post announcing <feature>
   /tasks what is overdue?
   /seo run the monthly report for <site-key>
   ```

Full setup, including pipelines, API keys and scheduled tasks, is in [SETUP.md](SETUP.md).

---

## Commands

| Command | What it does |
|---|---|
| `/marketing <goal>` | Orchestrator. Reads brand context, picks the right specialists, runs them in parallel or in sequence, and merges the result |
| `/seo <request>` | SEO, AEO and GEO: monthly report, weekly rankings and AI-answer check, page and site improvements |
| `/tasks <request>` | Task tracker: weekly review, add/update/move tasks, plan the week, new-webinar task sets |
| `/brand-refresh` | Turns files, URLs or pasted text in `inbox/` into updates to `brand/`. Asks before changing any fact |
| `/brand-audit` | Read-only check of `brand/`: stale files, deprecated terms, contradictions, broken references |

## Agents, by category

All agents are in `.claude/agents/<category>/`.

### Strategy
| Agent | Role |
|---|---|
| `campaign-strategist` | Campaign plans (webinar-first), channel mix, audience targeting, timelines |
| `market-researcher` | Competitor intel, audience research, industry trends, TAM/SAM |
| `product-marketer` | Positioning, messaging, GTM and launch plans, sales enablement |

### Content
| Agent | Role |
|---|---|
| `content-writer` | Blogs, whitepapers, case studies, landing pages |
| `copy-editor` | Proofreading, tightening, glossary enforcement, claim flags |
| `brand-voice-guardian` | Voice and tone review, terminology, claim accuracy |
| `email-marketing-specialist` | Webinar email sequences (invite, 1-day-to-go, day-of, follow-up), nurture flows |
| `creative-designer` | Creative briefs, deck outlines, visual direction |

### Social and community
| Agent | Role |
|---|---|
| `linkedin-strategist` | LinkedIn analytics (with export quirks handled), competitor activity, content direction |
| `reddit-strategist` | Community listening, voice-of-customer language, pain points, seeding strategy |
| `social-media-expert` | LinkedIn and Reddit posts, calendars, employee advocacy, group seeding |

### SEO
| Agent | Role |
|---|---|
| `seo-strategist` | Keyword research, clusters, content briefs |
| `website-seo-specialist` | Runs the SEO pipeline for every site in `config/sites.csv`: monthly report, weekly ranking and AEO report, technical and on-page fixes, AI-answer visibility |

### Paid and performance
| Agent | Role |
|---|---|
| `paid-ads-manager` | Google Search and LinkedIn Ads copy, targeting, structure |
| `performance-marketer` | Funnel analysis, CRO, growth experiments |

### Analytics
| Agent | Role |
|---|---|
| `analytics-reporter` | Webinar and channel KPI reports, post-mortems |
| `data-analyst` | Attribution, cohorts, segmentation, deep analysis |

### Operations
| Agent | Role |
|---|---|
| `marketing-task-assistant` | Owns the task tracker workbook: no duplicates, status from plain-language updates, weekly review, auto-generated webinar task sets |
| `webinar-data-consolidator` | Merges raw webinar attendee, poll and Q&A exports into the master Excel report without breaking formulas or formatting |

## Skills

| Skill | What it does |
|---|---|
| `brand-context` | Entry point that loads the glossary and brand index before any company-related work |
| `webinar-snippets` | Turns a webinar recording and transcript into 5–10 standalone short-video snippets with exact timestamps, cut notes and an outro |

Recommended third-party skills (install separately):
- [humanizer](https://github.com/blader/humanizer): removes AI-sounding patterns from prose
- [marketingskills](https://github.com/coreyhaines31/marketingskills): 40+ general marketing skills by Corey Haines
- Remotion skills, for code-based video (needs Node.js)

## Automations

Scheduled-task prompts are in `automations/scheduled-tasks/`. Install them as Claude Code scheduled tasks (see SETUP.md).

| Task | Suggested schedule | What it does |
|---|---|---|
| `weekly-task-review` | Mon 09:30 | Overdue, this week, next week, blocked, backlog, webinar actions, decisions needed |
| `social-follower-weekly-check` | Mon 09:00 | Asks for this week's follower counts and logs them to the tracker |
| `seo-monthly-report` | Last day of the month, 10:00 | Builds the monthly SEO workbook for each site |
| `seo-weekly-report` | Mon 10:00 | Weekly ranking + AEO workbook per site |

## Pipelines

PowerShell pipelines in `pipelines/`, each with its own README.

| Pipeline | What it produces |
|---|---|
| `seo-reporting/` | GA4, Search Console, URL Inspection, our own crawler, PageSpeed/CrUX, AEO checks → monthly and weekly Excel workbooks with an Improvements sheet. Spec: `PLAYBOOK.md` |
| `task-tracker/` | Creates and edits the task tracker workbook (Tasks, Webinar Tasks, Creatives, Videos), with a backup on every write. `webinar-activities.csv` defines the standard webinar task set |
| `social-tracking/` | Writes weekly follower counts straight into the tracker xlsx. Safe on synced and co-authored files |
| `creative-rendering/` | HTML/CSS creatives → PNG (1x/2x) and PDF via headless Edge, plus a batch generator from a CSV of briefs |
| `video-production/` | Animated product-demo MP4s built from PowerPoint animations over real screenshots, plus vertical shorts cut from webinar recordings |
| `docs-conversion/` | Markdown → styled .docx through Word, with tables, callouts and embedded images |

## Guides

`docs/` holds the conventions, creative-rendering and video-production guides (including every COM trap found so far), the motion-graphics style, the webinar companion-page spec and the speaker checklist.

## Repo layout

```
.claude/
  agents/<category>/   19 specialist agents
  commands/            /marketing /seo /tasks /brand-refresh /brand-audit
  skills/              brand-context, webinar-snippets
brand/                 YOUR company facts (templates; fill in)
config/                team.md, paths.md, sites.csv
automations/           scheduled-task prompts
pipelines/             PowerShell pipelines
docs/                  conventions, guides, specs
inbox/                 drop folder for /brand-refresh
```

## Requirements

- Claude Code (CLI or desktop app)
- For the pipelines: Windows, PowerShell 5.1, Microsoft Office (Excel, Word, PowerPoint) and Microsoft Edge. Node.js and Python are not needed.
- For SEO: a Google Cloud OAuth client with the Search Console and GA4 Data APIs enabled, and optionally PageSpeed, Ahrefs and Clicky keys.
