---
name: utm-builder
description: "Builds UTM-tagged links that follow one naming convention and records every link in a UTM log so reports stay clean. Use when someone needs tracked links for a post, email, ad, webinar promotion or partner, when setting up the UTM convention, or when cleaning up messy source and medium values."
---

# UTM builder

## When to use

- Any link going out on a channel we want to measure: social posts, emails, ads, partner newsletters, community posts, QR codes.
- Setting up or revising the naming convention.
- A report shows duplicate or messy sources and mediums.

## Inputs

Ask for:
- Destination URL(s).
- Channel and placement for each link (for example company page post, employee post, email 2 of the sequence).
- The campaign it belongs to and its launch date.

Read `brand/channels.md` (allowed channels, and channels we do not use), `config/team.md` (webinar cadence and email sequence names) and `config/paths.md` (where the UTM log lives; if no path is set, propose `trackers/utm-log.csv` and flag it).

## Naming convention

All values lowercase, words joined with hyphens, no spaces, no special characters.

| Parameter | Rule | Examples |
|---|---|---|
| `utm_source` | The platform or sender | `linkedin`, `reddit`, `google`, `newsletter`, `partner-<name>` |
| `utm_medium` | The type of traffic | `organic-social`, `paid-social`, `cpc`, `email`, `community`, `referral`, `qr` |
| `utm_campaign` | `<yyyy-mm>-<campaign-slug>` | `2026-03-webinar-forecasting-basics` |
| `utm_content` | The placement or variant | `company-page`, `employee-advocacy`, `email-1-invite`, `email-2-day-before`, `ad-a` |
| `utm_term` | Paid search keyword or audience, only when useful | `planning-software`, `aud-finance-leaders` |

Keep the source and medium lists closed: adding a new value is a decision, recorded in the log's notes. Make sure the medium values map to the channel groups your analytics tool expects (for example `cpc` and `paid-social` land in paid channel groups, `email` in email). Check the tool's channel-group rules if unsure.

## Steps

1. Check the log for an existing campaign slug before creating a new one. Reuse it.
2. Build each link: add parameters to the destination URL. If the URL already has a `?`, append with `&`. Keep any `#anchor` at the very end.
3. Never tag internal links between our own pages; it resets the session source.
4. Shorten only after tagging, and log both the long and short link.
5. Append each link to the log.
6. Test one link per campaign: open it, check the real-time report shows the right source, medium and campaign.

## Output template

Links, ready to paste:
```
<placement>: <full tagged URL>
```

Log rows (CSV, header once):
```
date_created,owner,campaign,destination_url,utm_source,utm_medium,utm_campaign,utm_content,utm_term,full_url,short_url,notes
```

## Quality checks

- Every value lowercase and hyphenated; no spaces, no `%20`.
- Source and medium values come from the closed lists; no channel that `brand/channels.md` says we don't use.
- Campaign slug matches the log, so a campaign never has two spellings.
- LinkedIn's own "Clicks" metric counts all interactions; tagged sessions are the real click measure, so every LinkedIn link gets a tag.
