# ADR 0005: Seasonal collections — month windows, hemisphere by region, curated only

- **Status:** Accepted
- **Date:** 2026-07-28

## Context

Milestone 5's premium curated templates need a notion of "in season". Two
constraints shape the design: the privacy guardrail (no network, and no new
data collection — asking for location to decide it is summer would be
absurd), and the seven shipped languages, one of which (pt-BR) belongs
overwhelmingly to the southern hemisphere, where July is winter.

## Decision

**A collection is active by calendar month, with two windows.** Each
collection declares northern months and southern months (Summer Nights:
Jun–Aug north, Dec–Feb south). Which window applies comes from
`Locale.current.region` checked against a fixed table of southern-hemisphere
regions — data the OS already exposes and the app already implicitly uses
for language. No location permission, no new signal. A family whose region
is set wrong sees the collection in the wrong months; that is a cosmetic
miss, not a harm, and the table is trivially extendable.

**Collection stories are curated-only.** The premium promise is editorial
quality; a collection tap never rolls the model dice. `StoryRequest` carries
a `collectionID`, and the provider routes such requests straight to the
curated engine — through the same neutralization chokepoint and the same
output gate as every other path. An unknown or out-of-season id degrades
silently to the normal shelf: never break bedtime outranks merchandising.

**Every collection ships all seven languages at once.** The honesty rule for
shelves ("never ship a language whose stories read like translations")
extends to collections; a premium feature that speaks English to a German
family is broken merchandise. Language parity is enforced by test, not
review vigilance.

**The card is visible to every tier, marked Fable+.** Telling the story is
gated at the action (the same `whenSubscribed` flow as series continuation).
An honestly labelled card is how families learn the feature exists; hiding
it from free families would just move the discovery to the App Store
listing. No countdowns, no urgency copy — the season simply is.

## Consequences

- Season boundaries follow the device's local calendar; a family crossing
  the equator mid-trip sees the card flip. Correct, if slightly whimsical.
- Southern-hemisphere summer spans a year boundary (Dec → Feb), so windows
  are month sets, not ranges.
- Each new collection is a real editorial commitment: seven templates, each
  obeying its language's documented slot discipline, swept by the gate in
  tests like the standing shelves.
- Story rows need no new fields: a collection story is an ordinary story
  whose template happened to be seasonal. Series continuation from one flows
  through the normal theme shelves, carried by recaps like any series.
