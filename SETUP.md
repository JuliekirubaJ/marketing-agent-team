# Setup

## 1. Get the repo

```bash
git clone <repo-url> marketing-agent-team
```

Open the folder in Claude Code. The agents, commands and skills in `.claude/` load automatically.

## 2. Fill in brand context and team settings

| File | Minimum to fill in |
|---|---|
| `brand/company.md` | Company, products, what you are not |
| `brand/glossary.md` | Product names and deprecated terms |
| `brand/voice-and-tone.md` | Voice, words to avoid |
| `brand/channels.md` | Channels used and not used, communities, tracked LinkedIn pages, standing resource links |
| `brand/claims-and-proof.md` | Every number you allow in public content |
| `config/team.md` | Owner, team roles, webinar cadence |
| `config/paths.md` | Where trackers, campaigns, webinars and creatives live |

Shortcut: put existing material (decks, transcripts, positioning docs) in `inbox/` and run `/brand-refresh`. It proposes the brand file updates and waits for your approval.

Brand files may be confidential. If the repo is shared outside the company, keep your filled-in `brand/` in a private fork or a separate private repo.

## 3. Point to your working folder

Working data (trackers, campaigns, exports) stays out of git. Set the root once:

```powershell
[Environment]::SetEnvironmentVariable('MARKETING_ROOT', 'D:\Marketing', 'User')
```

If it isn't set, the scripts use the repo folder.

## 4. Pipelines (optional, Windows)

Each pipeline has a README with the details.

- **Task tracker**: create a blank tracker, then let `/tasks` manage it:
  ```powershell
  .\pipelines\task-tracker\task-tracker.ps1 -Action New
  ```
- **SEO reporting**: add your sites to `config/sites.csv`, then follow `pipelines/seo-reporting/README.md` for Google OAuth. Secrets go in `%USERPROFILE%\.marketing-agent-team\` (`google-client.json`, `keys.json`), never in the repo.
- **Creatives, video and docs** need only Office and Edge.

## 5. Scheduled automations

In the Claude desktop app, create a scheduled task for each folder in `automations/scheduled-tasks/`: paste the SKILL.md prompt and use the suggested schedule at the top of the file. From the CLI, ask Claude: "create a scheduled task from automations/scheduled-tasks/weekly-task-review/SKILL.md".

## 6. Recommended extras

- `humanizer` skill: https://github.com/blader/humanizer
- `marketingskills`: https://github.com/coreyhaines31/marketingskills
- Connectors (MCP) for the tools your team uses, such as Ahrefs, HubSpot, Google Analytics or Slack.

## Contributing

Follow `docs/conventions.md`: no brand names, no absolute paths, no secrets, plain-ASCII PowerShell. Before you push, run a quick check:

```bash
grep -rniE "C:\\\\Users|@yourcompany\.com|api[_-]?key\s*=" . --exclude-dir=.git
```
