---
name: ai-prose-check
description: "Finds and rewrites writing that sounds machine-generated: inflated vocabulary, stock openers and closers, forced groups of three, 'not X but Y' constructions, dash overuse, vague praise and filler, while keeping facts, glossary terms and approved claims intact. Use on any draft before review or publishing, especially blog posts, emails, social posts, community replies and voiceover."
---

# AI prose check

## When to use

- Any draft before it goes to copy-editor or brand-voice-guardian.
- A reviewer says a piece "sounds like AI" or "sounds templated".
- Community posts and replies, where readers spot generic writing quickly.

This skill works alongside the optional third-party `humanizer` skill if it is installed. Use either one; if both run, run this one last so the brand checks below have the final say.

## Inputs

- The draft and its channel.
- Read `brand/voice-and-tone.md` (words to avoid, tone), `brand/glossary.md` and `brand/claims-and-proof.md`.

## Steps

1. **Read it as the target reader.** Mark every sentence that adds no information.
2. **Scan for the patterns below** and fix each one by saying the specific thing plainly.

   | Pattern | Example | Fix |
   |---|---|---|
   | Inflated words | delve, leverage, robust, seamless, unlock, elevate, landscape, realm, game-changer, cutting-edge, empower | Use the plain word, or cut |
   | Stock openers | "In today's fast-paced world...", "Have you ever wondered..." | Start with the point |
   | Stock closers | "In conclusion...", "The future is bright", "Ultimately..." | End on the last useful fact or the CTA |
   | Negative parallelism | "It's not just a tool, it's a revolution" | State what it does |
   | Forced threes | "faster, smarter and better" | Keep only the items you can back up |
   | Significance claims | "plays a pivotal role", "a testament to" | Say what happened |
   | Vague attribution | "experts say", "studies show" | Name the source or drop it |
   | Dash and colon overuse | several em dashes per paragraph | Use full stops and commas |
   | Rhetorical Q&A | "The result? Faster plans." | Write the sentence normally |
   | Hedge stacks | "may potentially help to" | One verb, one claim |
   | Emoji and bold sprinkling | bold on every other phrase | Bold only what a skimmer must see |
   | Uniform rhythm | every sentence the same length | Vary length; allow short sentences |

3. **Keep what must stay.** Do not change glossary terms, product names, approved claims and their caveats, quotes, numbers, links or legal wording.
4. **Check the claims did not grow.** A rewrite must not make a claim stronger than `brand/claims-and-proof.md` allows.
5. **Read aloud.** If a sentence would sound odd said to a colleague, rewrite it.

## Output template

```
## AI prose check - <piece> (<date>)
Verdict: <reads naturally | light edits | needs rewrite>

### Changes
| Original | Revised | Pattern |

### Revised draft
<full text>

### Left unchanged on purpose
<terms, claims or quotes kept as-is>
```

## Quality checks

- Meaning, facts and claims are unchanged; glossary terms exact.
- No new claims, numbers or names introduced.
- Plain B2B narration, no exaggeration, no replacement buzzwords.
- The revised text is not longer than the original unless clarity needed it.
