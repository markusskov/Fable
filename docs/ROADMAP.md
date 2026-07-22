# Roadmap

Working agreement: items move top-to-bottom through **Next → In progress → Done**. Autonomous sessions pick the top unchecked item in *Next*, branch, build, test, PR, merge, then update this file. Keep this file honest — it is the single source of truth for what happens next.

## Milestone 1 — Foundation (v0.1, internal)

- [x] Founding docs: vision, ADRs 0001–0003, roadmap, CLAUDE.md
- [x] XcodeGen project scaffold, Swift 6, iOS 26 target, CI on GitHub Actions
- [x] Core domain: `ChildProfile`, `Story`, `StoryTheme` models + SwiftData persistence
- [x] `CuratedStoryEngine` with first 3 story templates + seeded-RNG unit tests
- [x] Minimal but polished UI shell: profile setup → tonight's story flow → reader
- [x] `ModelStoryEngine` on FoundationModels with `@Generable` guided output + availability gating
- [x] Content post-check v1 (structural checks + denylist) with silent fallback wiring
- [x] Model prompt tuning: calmer tone and fuller pages (observed 1-sentence "very excited" pages); deepen content checks (age heuristics, richer patterns)
- [x] Reader polish: page-turn experience, warm theme, Dynamic Type audit
- [ ] Review findings 2026-07-22 (owner-requested review of PRs #2–#5, all verified live in simulator):
  - Model sometimes writes "The End." inside the final page, duplicating the reader's own end marker — forbid in prompt and strip in `repaginated` (or a sibling cleanup pass)
  - Safety gate's last-page rule is name-presence only; observed a passing story whose ending never winds down ("continued to explore and discover new places"). Enforce a sleep signal (goodnight/sleep-word set) on the last page to match what the prompt already demands
  - Prompt nudge: stories should live at dusk/evening — observed "One sunny afternoon" opening
  - Cosmetic: profile-setup scroll collides with the status-bar clock (no scroll-edge treatment)
  - Hygiene: cancel `SubscriptionStore.updatesTask` in `deinit`; `.storekit` yearly price (39.99) diverges from VISION intent (~29.99) and no intro offer configured — resolve deliberately when creating real SKUs in App Store Connect

## Milestone 2 — Monetization (v0.5, TestFlight)

- [x] StoreKit 2: Fable+ subscription (monthly/annual), StoreKit configuration file for local testing
  - Live purchase flows must be exercised from Xcode's Run action: under `xcodebuild`, the simulator's storekitd rejects `SKTestSession`'s attempt to install a test configuration (`SKInternalErrorDomain` 3) even for a minimal canonical file, so CI validates the config as data instead.
- [ ] Free-tier metering (3 starter stories, 1/week after) + paywall screen (calm, honest copy)
- [ ] Story series: continuing adventures with same characters (Fable+ feature)
- [ ] Multiple child profiles (Fable+ feature)
- [ ] App icon + brand pass (warm, storybook, not childish-clipart)
- [ ] **BLOCKED ON OWNER:** Apple Developer account details → App Store Connect app record, bundle ID registration, subscription products, TestFlight

## Milestone 3 — Ship (v1.0, App Store)

- [ ] Onboarding flow (first-run: create profile → first story in under 60 seconds)
- [ ] Privacy nutrition label prep + App Review notes (kids-adjacent positioning, parental gate)
- [ ] App Store page: screenshots, description, keywords (ASO pass)
- [ ] Release automation: version/build bump, changelog from conventional commits
- [ ] Submit for review

## Milestone 4 — Grow (post-1.0)

- [ ] Illustrations via ImagePlayground (cover art per story)
- [ ] Seasonal collections (premium curated templates)
- [ ] iPad layout, then Mac Catalyst evaluation
- [ ] Story audio: AVSpeechSynthesizer narration with parental voice options
- [ ] Localization: start with da-DK + de-DE (small markets, low competition, owner locale advantage)

## Icebox / ideas

- Watch app: "wind-down" audio-only mode
- Sibling mode: one story, two heroes
- "Story sparks" widget: tonight's suggestion on the lock screen
