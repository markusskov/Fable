# ADR 0004: Cover art via ImagePlayground, prompted only from app-controlled vocabulary

- **Status:** Accepted
- **Date:** 2026-07-28

## Context

Milestone 5 adds an illustrated cover per story. The only image generator that
satisfies the privacy guardrail (no network calls, no analytics, on-device
only) is Apple's ImagePlayground framework, which shares the story engine's
availability caveats: the device may not support Apple Intelligence, the model
may not be downloaded, or generation may fail or be refused.

Images create a safety problem our existing gate cannot answer.
`ContentSafetyCheck` judges text; there is no on-device way to judge pixels
with anything like the same confidence. Whatever ships must not depend on a
post-check we cannot build.

## Decision

**Image prompts are built exclusively from app-controlled vocabulary.** The
prompt is a hand-written scene description keyed by `StoryTheme` (a closed
enum), with a small set of variants per theme. Nothing a parent typed — child
name, companion, comfort object — and nothing the model wrote — title, prose,
recap — ever reaches an image prompt. The compiler enforces this: the prompt
function's only inputs are the theme and a variant index.

What that buys, in order of importance:

1. **Input-side safety is total.** The entire prompt space is enumerable and
   reviewed in the repository, like the curated story shelves. There is no
   injection surface and nothing to neutralize.
2. **Output-side safety reduces to Apple's own generation policy** applied to
   benign, editorial prompts. ImagePlayground's animation/illustration styles
   are deliberately non-photorealistic and carry Apple's content refusals.
   This is the same trust boundary the story engine already stands on —
   FoundationModels' safety layer — except here the input is not merely
   neutralized but constant.
3. **No likeness questions.** A cover cannot depict the child because the
   generator never learns anything about them.

The cost: covers illustrate the *mood*, not tonight's particular story. A
space story gets a moonlit-sky cover, not a portrait of its named comet. For
a bedtime brand built on calm sameness, that is an acceptable — arguably
correct — trade.

## Mechanics

- Generation starts only after the story is committed and the reader pushed;
  it never gates the bedtime flow. Success attaches the image to
  `Story.coverArt` (external storage) and saves quietly. Any failure —
  unsupported device, model not downloaded, refusal, error mid-stream —
  leaves the field nil and the UI on its existing emoji emblem. Silence is
  the fallback, per "never break bedtime".
- One attempt per story, no retry loop: cover art is garnish, and background
  image generation is battery-expensive.
- The reader's title page decides its emblem once, at open: the cover if it
  is already painted, the emoji otherwise — never a mid-read swap. A cover
  that finishes while the family reads greets them on the next open instead
  (owner feedback 2026-07-28: the swap-in read as a glitch).
- Series episodes inherit the earliest painted episode's cover — one visual
  identity per adventure. A freshly painted episode cover rolled a
  near-identical scene anyway, because prompts are theme-keyed; the
  story-aware alternative is exactly what this ADR rules out.
- Covers are for every tier. The free week's story gets the same cover a
  Fable+ story gets; the paywall sells stories, not their jackets.
- Stories persisted before this feature simply have no cover; no backfill
  pass. Their emblem rendering is unchanged.

## Consequences

- `ImageCreator` cannot run in CI (no Apple Intelligence on simulators
  there), so the engine sits behind an injectable protocol like the story
  engines; studio logic is tested with fakes, and the real engine stays a
  thin, availability-gated shell.
- Adding a theme now means also authoring its cover scenes; a compile-time
  switch makes forgetting impossible.
- If a future feature wants story-specific art, it must first solve image
  post-checking; this ADR is the marker that the constraint was deliberate.
