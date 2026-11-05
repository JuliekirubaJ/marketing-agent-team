---
name: schema-markup
description: "Writes and validates JSON-LD structured data from templates for Organization, SoftwareApplication, Article, FAQPage, Event, VideoObject and BreadcrumbList. Use when a page needs schema, when rich results or entity facts look wrong, or when checking existing markup against the visible content."
---

# Schema markup (JSON-LD)

## When to use

- A new page needs structured data, or a template is being built.
- Validation errors appear in URL Inspection (`gsc\url-inspection.csv`, rich-result columns) or `aeo-health.json`.
- AI answers or knowledge panels get entity facts wrong.

## Inputs

- The page URL or draft and its type.
- `brand/company.md`: legal name, logo URL, official profile and marketplace URLs for `sameAs`.
- `brand/glossary.md` for product names; `brand/claims-and-proof.md` for any rating or number.
- For events and webinars: date, time with timezone (see `config/team.md`), registration URL.

## Steps

1. Pick the type from what the page really is. One main entity per page, plus BreadcrumbList.
2. Fill the template below with values from `brand/` and the page. Leave out any property you can't source rather than guessing.
3. Check every value is visible on the page or true of the entity. Markup that describes content the page doesn't show is a policy risk.
4. Use absolute URLs, ISO 8601 dates with timezone offsets, and the same `@id` for the organization everywhere (`https://<domain>/#organization`).
5. Validate with the Schema.org validator and Google's Rich Results Test (ask the owner to run it if you can't), then re-check URL Inspection after release.

## Templates

```json
{"@context":"https://schema.org","@type":"Organization","@id":"https://<DOMAIN>/#organization",
 "name":"<COMPANY>","url":"https://<DOMAIN>/","logo":"https://<DOMAIN>/<LOGO_PATH>",
 "description":"<ONE_SENTENCE_FROM_brand/company.md>",
 "sameAs":["<OFFICIAL_PROFILE_URL>","<MARKETPLACE_LISTING_URL>"]}
```

```json
{"@context":"https://schema.org","@type":"SoftwareApplication","name":"<PRODUCT>",
 "applicationCategory":"BusinessApplication","operatingSystem":"<PLATFORM_OR_Web>",
 "description":"<APPROVED_DESCRIPTION>","url":"https://<DOMAIN>/<PRODUCT_PATH>/",
 "publisher":{"@id":"https://<DOMAIN>/#organization"},
 "offers":{"@type":"Offer","price":"<PRICE_OR_0>","priceCurrency":"<CURRENCY>","url":"<PRICING_URL>"},
 "sameAs":["<MARKETPLACE_LISTING_URL>"]}
```
Add `aggregateRating` only with a real, current source named in `brand/claims-and-proof.md`.

```json
{"@context":"https://schema.org","@type":"Article","headline":"<TITLE_UNDER_110_CHARS>",
 "description":"<META_DESCRIPTION>","image":"https://<DOMAIN>/<IMAGE>",
 "datePublished":"<YYYY-MM-DDThh:mm:ss+hh:mm>","dateModified":"<YYYY-MM-DDThh:mm:ss+hh:mm>",
 "author":{"@type":"Person","name":"<AUTHOR>","url":"<AUTHOR_PAGE>"},
 "publisher":{"@id":"https://<DOMAIN>/#organization"},
 "mainEntityOfPage":"https://<DOMAIN>/<PATH>/"}
```

```json
{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[
 {"@type":"Question","name":"<QUESTION_AS_SHOWN>",
  "acceptedAnswer":{"@type":"Answer","text":"<ANSWER_AS_SHOWN>"}}]}
```

```json
{"@context":"https://schema.org","@type":"Event","name":"<EVENT_TITLE>",
 "startDate":"<YYYY-MM-DDThh:mm:ss+hh:mm>","endDate":"<YYYY-MM-DDThh:mm:ss+hh:mm>",
 "eventAttendanceMode":"https://schema.org/OnlineEventAttendanceMode",
 "eventStatus":"https://schema.org/EventScheduled",
 "location":{"@type":"VirtualLocation","url":"<REGISTRATION_URL>"},
 "description":"<SUMMARY>","image":"https://<DOMAIN>/<IMAGE>",
 "organizer":{"@id":"https://<DOMAIN>/#organization"},
 "offers":{"@type":"Offer","price":"0","priceCurrency":"<CURRENCY>","url":"<REGISTRATION_URL>","availability":"https://schema.org/InStock"}}
```
After the event, switch the page to VideoObject for the recording, or remove Event markup.

```json
{"@context":"https://schema.org","@type":"VideoObject","name":"<VIDEO_TITLE>",
 "description":"<SUMMARY>","thumbnailUrl":"https://<DOMAIN>/<THUMB>",
 "uploadDate":"<YYYY-MM-DDThh:mm:ss+hh:mm>","duration":"PT<MM>M<SS>S",
 "contentUrl":"<VIDEO_FILE_URL>","embedUrl":"<EMBED_URL>"}
```

```json
{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[
 {"@type":"ListItem","position":1,"name":"Home","item":"https://<DOMAIN>/"},
 {"@type":"ListItem","position":2,"name":"<SECTION>","item":"https://<DOMAIN>/<SECTION>/"},
 {"@type":"ListItem","position":3,"name":"<PAGE>"}]}
```

## Output template

```
## Schema: <URL>
Type(s): <...> | Values sourced from: <brand files, page>
<JSON-LD block ready to paste in a <script type="application/ld+json"> tag>
Not included (no source): <properties left out>
Validation: <passed / to run by owner>
```

## Quality checks

- FAQPage only where the questions and answers are visible on the page, word for word.
- No ratings, prices or awards that aren't in `brand/claims-and-proof.md`.
- Names follow `brand/glossary.md` and match the visible H1 and the organization's other profiles.
- Valid JSON: no trailing commas, straight quotes.
