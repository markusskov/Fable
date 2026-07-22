# ADR 0003: Two-tier story engine — on-device AI with a curated fallback

- **Status:** Accepted
- **Date:** 2026-07-22

## Context

FoundationModels availability is not guaranteed at runtime: the device may not support Apple Intelligence, the user may have it disabled, the model may not be downloaded yet, or a request may be refused by the model's safety layer. A bedtime app that fails at 8pm loses the family forever. Separately, generating stories for children demands strict content control.

## Decision

`StoryEngine` is a protocol with two conforming implementations behind a single façade:

1. **`ModelStoryEngine`** (FoundationModels): builds a structured prompt from the child profile + tonight's spark, uses `@Generable`-guided generation to receive a typed `GeneratedStory` (title, pages, moral), with instructions tuned for age-appropriate, calm, kind bedtime stories. Availability is checked via `SystemLanguageModel.default.availability` before use.
2. **`CuratedStoryEngine`**: a hand-written library of parameterized story templates (name, companion, setting, comfort object, fear-to-overcome slots) with enough combinatorial variation that repeats feel like "another story about…" rather than the same text. Ships in the app bundle as structured data. This is not a degraded mode — templates are edited to publishable quality.

The façade (`StoryProvider`) selects the engine per request: model if available, curated otherwise, and curated as automatic retry if a model request fails or is refused. The UI never knows which engine produced a story; the settings screen states it honestly.

## Content safety

- Model instructions constrain theme, tone, vocabulary to the child's age band; scary/violent/branded content is prohibited in instructions *and* post-checked by a lightweight denylist/heuristic pass before display.
- Any post-check failure silently falls back to the curated engine. No error states at bedtime.

## Consequences

- Curated templates are a real editorial investment and a permanent asset (they also become "seasonal collections" premium content later).
- Two engines means the story data model must be engine-agnostic from day one (`Story` is plain data; engines are producers).
- Testing: curated engine is fully deterministic under seeded RNG — unit-testable; model engine gets availability-gated integration tests that skip cleanly in CI.
