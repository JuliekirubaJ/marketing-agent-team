---
name: form-optimization
description: "Audits and redesigns lead, registration, demo and signup forms: which fields to keep, field order, labels, errors, progressive profiling, hidden tracking fields, consent and the thank-you step, plus a QA checklist for launch. Use when a form has high drop-off, when a new form is being built, or when sales asks for more fields."
---

# Form optimization

## When to use

- A form's start-to-submit rate is low, or the page converts poorly and the form is the suspect.
- A new registration, demo or signup form is being built.
- Someone wants to add fields and the cost needs weighing.

## Inputs

Ask for:
- The form (URL, screenshot or field list) and where it sits.
- Which fields sales, routing and reporting actually use, and which they could enrich later.
- Form views, starts and submits if the analytics capture them.
- Consent requirements for the regions you market to.

Read `brand/audiences.md` (who fills it in), `brand/voice-and-tone.md`, `config/team.md`, and the tracking plan if one exists.

## Steps

1. **Field inventory.** For each field record: required or optional, who uses it, what decision it drives, and whether it could be enriched or asked later. Fields nobody uses go.
2. **Cut to the minimum for the offer.** A webinar registration needs much less than a demo request. Ask for more only when the visitor gets more.
3. **Progressive profiling.** For known contacts, hide fields already on record and ask one new question instead.
4. **Order and grouping.** Easy fields first (name, work email), then company details, then qualifying questions. One column. Related fields together.
5. **Labels and help.** Visible labels above fields, not placeholder-only. Examples in help text where formats vary. Mark optional fields, not required ones, when most are required.
6. **Field types.** Dropdowns only for short, clear lists. Correct input types for email and phone so mobile keyboards fit. Don't force phone unless sales calls every lead.
7. **Errors.** Inline, specific, next to the field, and the form never wipes what the visitor typed.
8. **Hidden fields.** UTM source, medium, campaign, content and term; campaign or webinar ID; landing page URL. These feed attribution, so check they populate.
9. **Consent and privacy.** Consent wording and checkbox defaults that fit the regions you market to, plus a short privacy note and link.
10. **Button and thank-you step.** Button says what happens ("Save my seat", "Request a demo"). The thank-you page or message confirms, sets expectations (calendar invite, reply time) and offers one next step.
11. **QA before launch.** Submit test entries on desktop and mobile; check the analytics event fires once, the CRM record has the hidden fields, routing works, the confirmation email arrives.

## Output template

```
## Form review - <form> (<date>)
Current: <n> fields (<n> required)   Start rate: <x%>   Completion: <x%>

| Field | Required now | Used by | Decision | Keep / optional / remove / ask later |

### Proposed form (in order)
1. <label> - <type> - required? - help text

### Hidden fields
### Consent and privacy wording
### Button and thank-you copy
### Launch QA checklist
[ ] desktop submit [ ] mobile submit [ ] event fires once [ ] CRM fields populated [ ] routing [ ] confirmation email
```

## Quality checks

- Every removed field is cleared with whoever uses it; note who agreed.
- No claim in the form copy that isn't in `brand/claims-and-proof.md`.
- Wording is plain and polite; glossary terms exact.
- Rates come from real data with dates, or the review says it is heuristic only.
