# Marketing Agent Team for Claude Code

A complete B2B marketing team that runs inside [Claude Code](https://claude.com/claude-code). It has **36 specialist agents in 11 categories, 44 playbook skills and an orchestrator**, plus scheduled automations and PowerShell pipelines for SEO reporting, task tracking, creatives and video.

The repo is **brand-neutral**. You fill in your company's facts once in `brand/` and your team in `config/`, and every agent works from them. No agent invents product facts: anything that isn't in `brand/` gets flagged.

---

## Quick start

**Option A: install as a plugin.** You get the agents, skills and commands in any project.
```
/plugin marketplace add JuliekirubaJ/marketing-agent-team
/plugin install marketing-agent-team@marketing-agent-team
```
Agents read `brand/` and `config/` from your project folder, so copy those two template folders into the project first.

**Option B: clone and work inside the repo.** This also gives you the brand templates, pipelines and automations.
```bash
git clone https://github.com/JuliekirubaJ/marketing-agent-team.git
```

Then fill in `brand/` (start with `company.md`, `glossary.md`, `voice-and-tone.md` and `channels.md`) and `config/team.md`, and try:
```
/marketing Plan the promotion for our next webinar on <topic>
/marketing Write a battlecard against <competitor>
/tasks what is overdue?
/seo run the monthly report for <site-key>
```

Full setup, including pipelines, API keys and scheduled tasks, is in [SETUP.md](SETUP.md).

---

## Commands

| Command | What it does |
|---|---|
| `/marketing <goal>` | Orchestrator. Reads brand context, picks the right specialists, runs them in parallel or in sequence, and merges the result |
| `/seo <request>` | SEO and AI search: monthly report, weekly rankings + AEO, technical audits, content refreshes, AI-answer visibility |
| `/tasks <request>` | Task tracker: weekly review, add/update/move tasks, plan the week, new-webinar task sets |
| `/brand-refresh` | Turns files, URLs or pasted text in `inbox/` into updates to `brand/`. Asks before changing any fact |
| `/brand-audit` | Read-only check of `brand/`: stale files, deprecated terms, contradictions, broken references |

## Agents (36), by category

Each agent is a role. It lists the skills it uses and the agents it hands work to. Files are in `.claude/agents/<category>/`.

### Strategy
| Agent | Role |
|---|---|
| `marketing-planner` | Quarterly or annual plan, OKRs, budget split, capacity, campaign portfolio |
| `campaign-strategist` | Campaign plans (webinar-first), channel mix, audience targeting, timelines |
| `market-researcher` | Audience research, industry trends, TAM/SAM |
| `competitive-intel-analyst` | Competitor monitoring, teardowns, win/loss, facts for comparison pages |
| `product-marketer` | Positioning, messaging, GTM and launch plans, pricing narrative |

### Content
| Agent | Role |
|---|---|
| `content-writer` | Blogs, whitepapers, case studies, landing pages |
| `copy-editor` | Proofreading, tightening, glossary enforcement, claim flags |
| `brand-voice-guardian` | Voice and tone review, terminology, claim accuracy |
| `email-marketing-specialist` | Email copy: webinar sequences, nurture emails, subject lines |
| `creative-designer` | Creative briefs, deck outlines, visual direction |
| `video-producer` | Scripts, storyboards, product demo videos, shorts, webinar clips |

### Social and community
| Agent | Role |
|---|---|
| `linkedin-strategist` | LinkedIn analytics (export quirks handled), competitor activity, content direction |
| `reddit-strategist` | Listening in external communities, voice-of-customer language, seeding strategy |
| `social-media-expert` | LinkedIn and Reddit posts, calendars, employee advocacy, group seeding |
| `community-manager` | Owned community or forum: programming, champions, Q&A-to-content loop, health metrics |

### SEO and AI search
| Agent | Role |
|---|---|
| `seo-strategist` | Keyword research, clusters, content briefs |
| `website-seo-specialist` | Runs the SEO pipeline for every site in `config/sites.csv`: monthly report, weekly ranking + AEO report |
| `technical-seo-auditor` | Crawl, indexation, Core Web Vitals, schema, redirects, hreflang; prioritized fix tickets |
| `ai-search-optimizer` | AEO/GEO: visibility in ChatGPT, Perplexity, Gemini, AI Overviews and Copilot; llms.txt; plan for getting cited |
| `content-seo-specialist` | Content decay, refreshes, cannibalization, internal linking, topic clusters |

### Paid and performance
| Agent | Role |
|---|---|
| `paid-ads-manager` | Google Search and LinkedIn Ads copy, targeting, structure |
| `performance-marketer` | Funnel analysis, channel ROI, growth experiments |
| `cro-specialist` | Landing page, form and pricing page audits; A/B test design and readout |
| `abm-strategist` | Target account lists, tiering, account plays, matched audiences, intent signals |

### Events and webinars
| Agent | Role |
|---|---|
| `webinar-producer` | Runs each webinar from announcement to T+3: setup, speaker prep, run-of-show, replay package, companion page |
| `field-events-marketer` | Conferences, sponsorships, user groups: go/no-go and ROI, booth plan, follow-up |

### Lifecycle and customer
| Agent | Role |
|---|---|
| `lifecycle-marketer` | Nurture journeys, onboarding, re-engagement, lead scoring, list health |
| `customer-marketer` | Case studies, references, review-site programs, customer speakers, advocacy |

### Sales and partners
| Agent | Role |
|---|---|
| `sales-enablement-specialist` | Battlecards, one-pagers, talk tracks, objection handling, demo scripts, webinar lead handoff |
| `partner-marketer` | Co-marketing, marketplace listings, partner enablement kits, co-sell content |

### Brand and PR
| Agent | Role |
|---|---|
| `pr-comms-manager` | Press releases, announcement comms, media and analyst relations, awards, holding statements |

### Analytics
| Agent | Role |
|---|---|
| `analytics-reporter` | Webinar and channel KPI reports, post-mortems |
| `data-analyst` | Attribution, cohorts, segmentation, deep analysis |

### Operations
| Agent | Role |
|---|---|
| `marketing-ops-specialist` | UTM governance, CRM hygiene, lead routing, form and tracking QA, data dictionary |
| `marketing-task-assistant` | Owns the task tracker workbook: no duplicates, status from plain-language updates, weekly review, webinar task sets |
| `webinar-data-consolidator` | Merges raw webinar attendee, poll and Q&A exports into the master Excel report |

## Skills (44), by area

Each skill is a repeatable procedure with inputs, steps, an output template and quality checks. Files are in `.claude/skills/<name>/SKILL.md`.

| Area | Skills |
|---|---|
| Foundation | `brand-context`, `ai-prose-check` |
| Strategy and planning | `marketing-okrs`, `icp-persona-builder`, `messaging-house`, `launch-checklist`, `campaign-postmortem` |
| Competitive and sales | `competitor-teardown`, `battlecard`, `win-loss-analysis`, `comparison-page` |
| Content | `content-calendar`, `content-repurposing`, `case-study-interview`, `video-script` |
| SEO | `keyword-clustering`, `seo-content-brief`, `on-page-seo-checklist`, `schema-markup`, `internal-linking-audit`, `content-refresh`, `technical-seo-audit`, `site-migration-checklist` |
| AI search | `ai-search-visibility-check`, `llms-txt` |
| Conversion and testing | `landing-page-cro-audit`, `form-optimization`, `pricing-page-review`, `ab-test-design` |
| Webinars and events | `webinar-promotion-timeline`, `webinar-run-of-show`, `webinar-replay-package`, `webinar-snippets`, `event-roi-plan` |
| Lifecycle and email | `nurture-sequence-design`, `lead-scoring-model`, `email-deliverability-check` |
| ABM and partners | `abm-account-plan`, `co-marketing-brief`, `marketplace-listing-optimizer` |
| PR | `press-release`, `award-submission` |
| Marketing ops | `utm-builder`, `tracking-plan` |

Recommended third-party skills (install separately):
- [humanizer](https://github.com/blader/humanizer): removes AI-sounding patterns from prose (pairs with `ai-prose-check`)
- [marketingskills](https://github.com/coreyhaines31/marketingskills): general marketing skills by Corey Haines
- Remotion skills, for code-based video (need Node.js)

## Automations

Scheduled-task prompts are in `automations/scheduled-tasks/`. Install them as Claude Code scheduled tasks (see SETUP.md).

| Task | Suggested schedule | What it does |
|---|---|---|
| `weekly-task-review` | Mon 09:30 | Overdue, this week, next week, blocked, backlog, webinar actions, decisions needed |
| `social-follower-weekly-check` | Mon 09:00 | Asks for this week's follower counts and logs them to the tracker |
| `seo-monthly-report` | Last day of the month, 10:00 | Builds the monthly SEO workbook for each site |
| `seo-weekly-report` | Mon 10:00 | Weekly ranking + AEO workbook per site |

## Pipelines

PowerShell pipelines live in `pipelines/`, each with its own README.

| Pipeline | What it produces |
|---|---|
| `seo-reporting/` | Monthly and weekly Excel workbooks with an Improvements sheet, built from GA4, Search Console, URL Inspection, our own crawler, PageSpeed/CrUX and AEO checks. Spec: `PLAYBOOK.md` |
| `task-tracker/` | Creates and edits the task tracker workbook (Tasks, Webinar Tasks, Creatives, Videos), with a backup on every write. `webinar-activities.csv` defines the standard webinar task set |
| `social-tracking/` | Writes weekly follower counts straight into the tracker xlsx. Safe on synced and co-authored files |
| `creative-rendering/` | HTML/CSS creatives → PNG (1x/2x) and PDF through headless Edge, plus a batch generator that works from a CSV of briefs |
| `video-production/` | Animated product-demo MP4s built from PowerPoint animations over real screenshots, plus vertical shorts cut from webinar recordings |
| `docs-conversion/` | Markdown → styled .docx through Word, with tables, callouts and embedded images |

## Guides

`docs/` holds:
- the conventions, including the agent and skill format and the YAML rules
- the creative-rendering and video-production guides, with every COM trap found so far
- the motion-graphics style
- the webinar companion-page spec and the speaker checklist

## Quality checks

```powershell
.\scripts\validate.ps1        # frontmatter, name/folder match, nesting, plugin manifest, absolute paths
.\scripts\validate.ps1 -Fix   # also regenerates the agent list in .claude-plugin/plugin.json
```
Claude Code **silently skips** an agent or skill whose YAML frontmatter doesn't parse, such as an unquoted description that contains `: `. Run the validator before every push.

## Repo layout

```
.claude/
  agents/<category>/   36 specialist agents in 11 categories
  commands/            /marketing /seo /tasks /brand-refresh /brand-audit
  skills/<name>/       44 playbook skills
.claude-plugin/        plugin.json + marketplace.json (install as a plugin)
brand/                 YOUR company facts (templates to fill in)
config/                team.md, paths.md, sites.csv
automations/           scheduled-task prompts
pipelines/             PowerShell pipelines
scripts/validate.ps1   repo checks
docs/                  conventions, guides, specs
inbox/                 drop folder for /brand-refresh
```

## Requirements

- Claude Code (CLI or desktop app)
- For the pipelines: Windows, PowerShell 5.1, Microsoft Office (Excel, Word, PowerPoint) and Microsoft Edge. Node.js and Python are not needed.
- For SEO: a Google Cloud OAuth client with the Search Console and GA4 Data APIs enabled, and optionally PageSpeed, Ahrefs and Clicky keys.
