---
name: tracking-plan
description: "Writes a tracking plan: the events, parameters, conversions and CRM fields a site, campaign or test needs, where each fires, and how to QA it in the analytics tool and tag manager. Use when launching a new page, form, campaign or A/B test, when setting up or auditing analytics events and key conversions, or when reports disagree about what counts as a conversion."
---

# Tracking plan

## When to use

- A new site section, landing page, form, webinar flow or A/B test needs measurement.
- Analytics events are inconsistent, duplicated or undocumented.
- Teams argue about what a "lead" or "conversion" means.

## Inputs

Ask for:
- The business questions the data must answer (for example "which channel brings registrants who attend?").
- The pages, forms and flows in scope.
- The tools in use: analytics, tag manager, CRM, marketing automation, webinar platform.
- Existing event names, if any (export or screenshot).

Read `config/sites.csv` (sites and analytics properties), `brand/channels.md`, `config/team.md` (funnel stages, email sequence) and the data dictionary if one exists (see `config/paths.md`).

## Steps

1. **Start from questions, not tags.** List the questions, then the metric that answers each, then the event that produces the metric. Drop events no question needs.
2. **Naming.** Lowercase `snake_case`, verb or object then action (`form_submit`, `webinar_register`, `video_progress`). Prefer the analytics tool's recommended event names when one fits (for example `generate_lead`, `sign_up`) so built-in reports work.
3. **Parameters.** For each event list the parameters and allowed values: `form_id`, `form_name`, `webinar_id`, `cta_text`, `cta_location`, `content_type`, `variant`. Register custom parameters as custom dimensions if they will be reported.
4. **Conversions.** Mark only the few events that mean real progress (registration, demo request, trial start, purchase) as key events or conversions. Page views and scrolls are not conversions.
5. **Trigger and source.** For each event say exactly where it fires: tag manager trigger (form submit, click, history change, custom data-layer push) or server-side or platform integration. Prefer a data-layer push from the form's success callback over a thank-you page view.
6. **CRM mapping.** Which events create or update records, which hidden fields (UTMs, campaign ID) carry over, which lifecycle stage changes.
7. **Consent.** Note which tags wait for consent, and how consent mode or the banner affects counts.
8. **QA plan.** For each event: the test action, where to see it (tag manager preview, analytics debug or real-time view, CRM record), and the expected parameters. Record pass or fail with the date.
9. **Owner and change log.** Who approves new events; date every change.

## Output template

```
## Tracking plan - <scope> (v<n>, <date>)
Questions this answers: 1. ... 2. ...

| Event | Description | Trigger / source | Parameters (allowed values) | Conversion? | CRM effect | Owner |

### Conversions and definitions
### Consent behaviour
### QA log
| Event | Test action | Where checked | Expected | Result | Date |
### Change log
```

## Quality checks

- Each event answers a named question; no orphan events.
- One event per real action: no double counting from both a click trigger and a submit trigger.
- Names follow the convention; no mixed case.
- No invented property IDs or tool names: take them from `config/sites.csv` or ask.
