<!--
Feature Spec (one-pager) — PER PROJECT
Keep in the repo, e.g. docs/specs/{{slug}}.md. Write this BEFORE building — it's
the "do we agree on what this is" doc. Keep it to one page. When a real
architectural choice falls out of it, capture that separately as a decision record
(decision-record-template.md).
Style: no emojis. Monochrome. SF Symbol names noted in comments, not rendered.
Fill in every {{placeholder}}; delete any section you don't need.
-->

# {{feature name}}

**Date:** {{YYYY-MM-DD}} · **Status:** {{Idea / Drafting / Ready to build / Built}} · **Owner:** {{name}}

## Problem

<!-- SF Symbol: questionmark.circle -->
{{What's wrong or missing today, from the user's side. One or two sentences. No
solution yet.}}

## Who it's for

<!-- SF Symbol: person -->
{{The user and the moment they hit this — the trigger that makes them want it.}}

## Proposed behavior

<!-- SF Symbol: wand.and.stars -->
{{What the feature does, described as the user experiences it — the happy path,
step by step. Not implementation.}}

## Edge cases

<!-- SF Symbol: arrow.triangle.branch -->
- {{What happens when there's nothing yet (empty state).}}
- {{What happens on failure / no network / bad input.}}
- {{The awkward case you'd otherwise forget.}}

## Out of scope

<!-- SF Symbol: nosign -->
- {{What this explicitly does NOT do — to keep the build bounded.}}

## Success looks like

<!-- SF Symbol: target -->
{{How you'll know it worked — the observable outcome, not a metric dashboard.}}

## Open questions

<!-- SF Symbol: exclamationmark.bubble -->
- {{Anything undecided that blocks starting, or that you'll resolve while building.}}
