---
name: email-deliverability-check
description: "Checks whether emails are reaching the inbox: authentication records, list health, recent list changes, complaint and bounce rates, content and sending patterns, and gives a ranked fix list. Use when open rates drop suddenly, before adding a new segment to a list, before a large send, or as a quarterly health check."
---

# Email deliverability check

## When to use

- Open or click rates dropped sharply between two sends.
- A new segment (win-back, event list, imported contacts) is about to be added.
- A large or unusual send is planned.
- Quarterly, as routine.

## Inputs

Ask for: the sending domain, the email platform, the last 8-12 sends with sent, delivered, bounced, opened, clicked, unsubscribed and complaint counts, and any list or segment changes in the same period (dates and sizes).

Read: `config/team.md` (cadence, standard sequence).

## Steps

1. **Look for a list change first.** Line up the metric drop with list changes. If a cold, win-back or imported segment was added to the main list in that window, that is the most likely cause. A large unengaged block lowers the open rate on its own, and can push mailbox providers to filter the whole list, engaged contacts included.
2. **Authentication.** Confirm SPF, DKIM and DMARC records exist and pass for the sending domain, and that the From domain aligns. Note a DMARC policy of none as a gap to tighten.
3. **Rates per send.** Hard bounces above about 2%, complaints above about 0.1% or a rising unsubscribe rate are warning signs. Mark these as common industry guide levels, not hard rules.
4. **Engagement mix.** Share of the list with no open or click in 90 and 180 days.
5. **Sending pattern.** Volume spikes, several webinar invites in one week to the same contacts, new sending domain or IP without warm-up.
6. **Content.** Heavy images with little text, link shorteners, many links, spammy subject lines, missing plain-text part, missing unsubscribe link.
7. **Open tracking caveat.** Privacy features in some mail apps pre-load images and inflate opens. Use clicks and replies as the more reliable signal.
8. **Rank fixes** by likely impact and effort.

## Output template

```
# Deliverability check: <domain>, <period>
Verdict: healthy | at risk | problem

## What changed
<dated list changes and metric moves side by side>

## Findings
| Area | Finding | Evidence | Severity |

## Fixes (ranked)
1. <fix> (owner role, effort)

## Segments to separate or warm
<segment, size, proposed warm-up: low volume, best content, merge only openers and clickers>
```

## Quality checks

- Every finding cites a number or a record, not a hunch.
- Guide thresholds are labelled as guides.
- A content problem is only blamed after list changes and authentication are ruled out.
- Report straight: no "process gap" claim without evidence.
