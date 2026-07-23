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
- [x] Review findings 2026-07-22 (owner-requested review of PRs #2–#5, all verified live in simulator):
  - Written "The End" now forbidden in prompt and stripped in `repaginated`; safety gate requires a wind-down signal on the last page; prompt pins stories to the evening; scroll-edge softening on setup + tonight screens; `SubscriptionStore` cancels its updates task in `deinit`; pricing intent aligned at \$4.99/\$39.99 with 7-day intro offer to be configured at SKU-creation time (VISION updated)

## Milestone 2 — Monetization (v0.5, TestFlight)

- [x] StoreKit 2: Fable+ subscription (monthly/annual), StoreKit configuration file for local testing
  - Live purchase flows must be exercised from Xcode's Run action: under `xcodebuild`, the simulator's storekitd rejects `SKTestSession`'s attempt to install a test configuration (`SKInternalErrorDomain` 3) even for a minimal canonical file, so CI validates the config as data instead.
- [x] Free-tier metering (3 starter stories, 1/week after) + paywall screen (calm, honest copy)
  - Plan cards render only under Xcode's Run action (StoreKit config limitation, see above); verified logic in tests and the no-products state live.
- [x] Raise model yield: below-floor mid pages now merge forward in `repaginated` (word-preserving; pervasive skimpiness still rejects via page count/ceiling) + word-count hint in the `@Guide`. Sampled after: 4/4 first-attempt passes vs ~50% before.
- [x] Story series: continuing adventures with same characters (Fable+ feature)
  - `StorySeries` model + per-story recap (model-authored, moral fallback); series context in prompts; create-from-end-page, continue-from-Tonight. DEBUG launch arg `-fable-debug-plus` simulates Fable+ for simulator UI checks.
  - Navigation hardening: single Story destination at the stack root, path-append everywhere (value-links from pushed screens resolved unreliably).
- [x] Multiple child profiles (Fable+ feature)
  - Stable `ChildProfile.uuid` + AppStorage active-profile selection; stories/series scoped per child (nil = legacy, belongs to everyone); switcher menu on Tonight; add-child gated on Fable+ beyond the first.
- [x] App icon + brand pass (warm, storybook, not childish-clipart)
  - Rendered programmatically from the Theme.swift palette (`scripts/render-app-icon.swift`) — deterministic, re-renderable, code-reviewed. Gold crescent, quiet sparkles, sleeping hills.
- [ ] **BLOCKED ON OWNER — now the critical path:** App Store Connect app record, bundle ID registration, subscription SKUs, TestFlight (see docs/OWNER-ASKS.md)

## Milestone 3 — Ship (v1.0, App Store)

- [x] Accessibility audit for the ASC declaration (owner asked 2026-07-23): Reduce Motion now respected everywhere animated; VoiceOver pass fixed unlabeled setup fields and hid decorative icons (selection via traits). Declare in ASC: VoiceOver, Voice Control, Larger Text, Dark Interface, Sufficient Contrast, Reduced Motion. Do NOT declare: Differentiate Without Color Alone (theme-card selection is fill-only), Captions/Audio (n/a).
- [x] Support site + privacy policy page (GitHub Pages) → fills ASC Support URL and the required Privacy Policy URL
  - Static `site/` deployed via `pages.yml` workflow. Support: https://markusskov.github.io/Fable/ · Privacy: https://markusskov.github.io/Fable/privacy.html — owner pastes both into ASC (see OWNER-ASKS).
- [x] Onboarding flow (first-run: create profile → first story in under 60 seconds — audited 2026-07-23, verified fresh-install in simulator)
  - Polish shipped: name field auto-focuses with next/done submit chaining; name gets word autocapitalization + no autocorrect; companion/comfort labels now say they're optional (engines default to "a small brave fox" / "a soft warm blanket"); setup → Tonight hands over with a gentle crossfade (skipped under Reduce Motion)
- [x] Privacy nutrition label prep + App Review notes → docs/appstore/metadata.md
- [x] App Store page: description/keywords/subtitle done (docs/appstore/metadata.md); screenshots shipped 2026-07-23
  - 6.9" set (1320×2868) captured by a scripted UI-test lane (`scripts/capture-screenshots.sh` + `FableScreenshots` scheme, outside CI) → `docs/appstore/screenshots/6.9/`; rerun after UI changes
  - App pinned iPhone-only for v1 (`TARGETED_DEVICE_FAMILY = 1`): no iPad screenshot slot, no unpolished stretched layout in review; real iPad layout stays in Milestone 4
- [x] Release automation: version/build bump, changelog from conventional commits
  - `scripts/release.sh` (bump major/minor/patch/X.Y.Z, build-only bump, tag) writes project.yml + CHANGELOG.md and commits; pushing the tag triggers `release.yml`, which publishes a GitHub Release with that version's changelog section. CI dry-runs the script so it can't rot. First real run happens at submission time.
- [x] Submit for review — **submitted 2026-07-23 ~18:00**: iOS App 1.0 (build 3) + Fable Plus group + both subscriptions, all Waiting for Review. Manual release. While in review: no metadata edits, no new submissions; dev work continues on branches as usual.

## Milestone 4 — Localization (active — 1.0 in review with ALL countries selected for availability, so launch is worldwide-in-English from day one)

Three workstreams per language, in honesty-order (never ship a language whose stories read like translations):
- [ ] **nb-NO (first — the founder's market):**
  - [x] App UI: String Catalog infrastructure + Norwegian translations (all screens incl. paywall legal text)
    - `App/Resources/Localizable.xcstrings` (en source + nb, plural variations for meter/trial lines); plain-`String` call sites plumbed through `String(localized:)` / `LocalizedStringKey`. `SWIFT_EMIT_LOC_STRINGS` on, so `xcodebuild -exportLocalizations` verifies catalog coverage — rerun that check when adding UI strings. Verified live in simulator (`-AppleLanguages "(nb)"`): setup, Tonight (incl. meter plurals), reader (end page uses "Snipp, snapp, snute"), paywall incl. legal text; English re-verified untouched (screenshot UI tests still pass). Story content stays English until the story-language item lands.
  - [ ] Story language plumbing: `StoryRequest.language`, model instructions in-language, `SystemLanguageModel` language-support gating, curated fallback per language
  - [ ] Curated templates in Norwegian — editorial translation, owner (native speaker) reviews before merge
  - [ ] ASC metadata: paste docs/appstore/metadata-nb.md (ready) into the nb localization
  - [ ] Store images: English set stays as fallback; owner localizes Figma captions when ready (translations in metadata-nb.md)
- [ ] **48-hour language sprint (owner green-lit 2026-07-23), after nb-NO infra lands:** de-DE, es-ES, fr-FR, it-IT, pt-BR. Each gets all three app layers + a store pack (no em dashes, owner reviews nothing except nb; model-language gating protects story quality everywhere)
- [ ] CJK (ja/ko/zh) deferred deliberately: bedtime idiom and typography deserve more care than a sprint; revisit with country analytics after launch
- [ ] Model-language honesty check per locale: if Apple Intelligence can't write the language, that locale runs curated-only — same "never break bedtime" rule

## Milestone 5 — Grow (post-1.0)

- [ ] Illustrations via ImagePlayground (cover art per story)
- [ ] Seasonal collections (premium curated templates)
- [ ] iPad layout, then Mac Catalyst evaluation
- [ ] Story audio: AVSpeechSynthesizer narration with parental voice options
- [ ] Localization: start with **nb-NO** (the founder's family is the first market), then de-DE. Three layers with different effort: UI strings (String Catalog, mechanical), curated templates (real editorial translation — they must read like native bedtime prose, not translations), and model stories (gated on Apple Intelligence language support per device — probe `SystemLanguageModel` language availability and fall back to curated in-language when the model can't write it).

## Icebox / ideas

- Watch app: "wind-down" audio-only mode
- Sibling mode: one story, two heroes
- "Story sparks" widget: tonight's suggestion on the lock screen
