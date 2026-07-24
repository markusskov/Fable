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
- [x] App Store Connect record, subscription SKUs, TestFlight — owner completed 2026-07-23

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
    - Catalog guarded by `LocalizationCatalogTests` (required-language coverage, plural categories, format-specifier parity). Each new locale PR appends its code to `requiredLanguages` — that is the sprint's completeness gate.
  - [x] Story language plumbing: `StoryRequest.language`, model instructions in-language, `SystemLanguageModel` language-support gating, curated fallback per language
    - `StoryLanguage` (en/nb; sprint languages append as cases) resolved from `Locale.preferredLanguages`; model engine refuses unsupported languages via `SystemLanguageModel.supportedLanguages` (silent curated fallback, never an error); `ContentSafetyCheck` is language-aware — denylist is en ∪ nb (code-switched scary words still caught), sleep signals are nb-only for nb (an English "goodnight" on a bokmål page rejects); curated shelves per language, empty nb shelf falls back to English honestly (`StoryContent.language` stamps what was served). nb safety vocab + directive on the owner skim list (OWNER-ASKS #2).
  - [x] Curated templates in Norwegian — editorial translation, owner (native speaker) reviews before merge
    - All three templates retold in bokmål (not literal translations) on the nb shelf; pool phrases chosen for grammatical agreement at every slot site; no dashes in nb prose (owner copy style, test-enforced). Blank companion/comfort now get language-aware defaults («en liten modig rev» / «et mykt og varmt teppe»). `NorwegianShelfTests` sweeps every theme × age band × 25 seeds through the nb safety gate. Owner (native speaker) tried the app in Norwegian and approved 2026-07-23; merged as PR #26.
  - [ ] ASC metadata: paste docs/appstore/metadata-nb.md (ready) into the nb localization
  - [ ] Store images: English set stays as fallback; owner localizes Figma captions when ready (translations in metadata-nb.md)
- [ ] **48-hour language sprint (owner green-lit 2026-07-23), after nb-NO infra lands:** de-DE ✅ (#27), es-ES ✅ (#28), fr-FR ✅ (evening session 2026-07-23: full catalog with French typography incl. narrow no-break spaces, three-template shelf with contraction-safe {setting} frames and uniformly feminine pronoun-referenced treasure pools, fr gate vocabulary with homonym care: bête/nulle/battre/cri excluded, "Cric, crac" end marker, store pack metadata-fr.md); it-IT ✅ (same session: full catalog, three-template shelf with transitive/verso-oltre {setting} frames, malvagio-not-cattivo homonym line, 'E qui la storia si addormenta' end marker, metadata-it.md); pt-BR ✅ (same session: full catalog in the Brazilian register with diminutives, three-template shelf with até/transitive {setting} frames, mata/burro/atirar/tiro homonym care, 'E aqui a história vai dormir' end marker, metadata-pt-BR.md). **SPRINT COMPLETE: six languages (en, nb, de, es, fr, it, pt-BR UI+stories+store packs) a day ahead of schedule.** v1.1 ships them together with the localized ASC metadata
  - [x] de-DE shipped 2026-07-23: UI catalog (all 74 translatable keys), `StoryLanguage.german` + bokmål-style model directive, German safety vocab (note: en denylist words "die"/"dies"/"war" are exempted for German — they are the article, "this", and "was"; `GermanShelfTests` + false-friend tests guard it), three templates retold in German with case discipline (dative-baked {setting} pools, nominative-only {companion}/{comfort} sites, mid-sentence-only defaults), store pack in docs/appstore/metadata-de.md. Verified live in simulator (`-AppleLanguages "(de)"`): setup, Tonight incl. meter plurals, full curated story with spliced defaults, end page («Ende gut, alles gut» / «Träum süß»), paywall incl. legal text.
  - [x] es-ES shipped 2026-07-23: UI catalog (all 74 translatable keys), `StoryLanguage.spanish` + "tú" model directive, Spanish safety vocab (checked: the en denylist has no Spanish false friends, so the union applies unfiltered — test-asserted; homonyms "mata", "golpe", and the chillar family deliberately absent), three templates retold in Spanish with contraction and gender discipline ({setting} pools bake the article behind non-contracting prepositions hacia/hasta/por/en/tras, structurally tested; no adjective ever agrees with a slot; {treasure} uniformly feminine per template or referred to by a fixed epithet), end page «Y colorín colorado, este cuento se ha acabado», store pack in docs/appstore/metadata-es.md. Verified live in simulator (`-AppleLanguages "(es)"`): setup, Tonight incl. meter plural, full curated story with spliced defaults, end page, paywall incl. legal text.
  - [ ] fr-FR (next session), then it-IT, pt-BR — same recipe; watch for each language's own en-denylist false friends and agreement discipline (fr liaison/elision at slot sites, e.g. "de {setting}" eliding to "d'"; it articulated prepositions "al/della" like Spanish's "al/del"; pt contractions "no/na/do/da")
- [x] Measure model pass-rate per language + fix what it found (2026-07-23 evening session):
  - `measuresYieldPerLanguage()` harness (env-gated, `TEST_RUNNER_FABLE_MEASURE_YIELD=1`) printed per-language pass rates and rejection histograms. Baseline: en 5–7/8, nb 4–5/8, de 3–5/8, es 2–4/8; dominant failures were ending discipline (missing name / missing wind-down), NOT length bounds.
  - Fixes, in order of impact: (1) `GeneratedStory.goodnight` — a dedicated guided field for the final goodnight-by-name sentence, appended to the last page only when the model's own ending fails the gate's contract (`ContentSafetyCheck.endingSatisfied`, so engine and gate share one definition); (2) StoryProvider gives the model 2 attempts before curated fallback (unavailability skips the retry); (3) missing plural/perfect sleep-word forms added (es "acurrucaron"-class preterites, nb "sovet"/"hvilet").
  - After: **8/8 in all four languages** in one full measurement run. Re-measure whenever prompts or the gate change.
- [ ] CJK (ja/ko/zh) deferred deliberately: bedtime idiom and typography deserve more care than a sprint; revisit with country analytics after launch
- [x] Model-language honesty check per locale: if Apple Intelligence can't write the language, that locale runs curated-only — same "never break bedtime" rule
  - Mechanism shipped with the language plumbing (`ModelStoryEngine.supportsLanguage` gate); each sprint language gets it for free by existing as a `StoryLanguage` case. One nuance: "curated-only" serves the *English* shelf until that language's curated templates land — honest fallback beats machine-translated prose.

## Milestone 4.5 — External review findings (Codex Sol Ultra, 2026-07-24) — release gate for public launch

Verdict after verification: overwhelmingly correct. Fix order follows the reviewer's, with two paths already closed. **1.0 (build 3) contains findings 1–2, so even if Apple approves it, the Release button stays unpressed until a fixed build is approved.**

- [x] **1. Provider-wide safety fail-open (BLOCKER)** — MERGED as b9948ef (PR #34) after four adversarial rounds, the last commit authored by the external reviewer and reviewed/verified by us (207 tests). Scope grew to include: input-boundary validation + canonical storage, Unicode/confusable/default-ignorable matching, split matching policies (deny-words fold diacritics, sleep signals exact), quarantine of unstamped legacy stories/series (hidden, not deleted), Story(telling:) as the only persistence path, and every fallback depth deterministically forced in tests. Policy decisions recorded in-code: ambiguous names (Mori/Lucho) fail closed; the floor is English by design. Round one: neutralize at the provider chokepoint, re-gate curated, gate the recap. Round two (Codex Sol Ultra found the deeper breaches): (a) hostile names reached the reader CHROME ("A story for Monster") because persistence used raw profile.name — fixed at the input boundary (profile-form validation across all languages + save() neutralization) and by returning an effective heroName; (b) "Nova!!!!" forced the floor which then failed its own gate — fixed by name sanitation (strip non-name chars) + a floor that names its constant safe hero; (c) articled generics broke five languages' grammar — replaced with proper-name endearments; (d) Unicode homoglyph/zero-width/NBSP bypasses (pulled forward from #9) — NFKC normalization before every match; (e) tests made deterministic via engine injection, reader-chrome-aware, per-language. 181 tests.
  - Follow-up done: the three profile-form validation strings AND PR #35's five paywall strings (store notes + Try again) translated into nb/de/es/fr/it/pt-BR — all under `LocalizationCatalogTests` coverage now.
- [x] **2. In-app Privacy Policy + Terms links (BLOCKER, legal)** — paywall footer + a minimal settings/about surface linking the live site pages and Apple's standard EULA. (Metadata-side URLs are already in ASC; the in-app requirement is the gap.)
  - Shipped: `AboutView` sheet (info button on Tonight) with the privacy promise, version line, and Support / Privacy Policy / Terms rows; paywall footer gained Privacy Policy + Terms links under Restore. `FableLinks` is the single source for the three URLs, pinned by `FableLinksTests`; all five new strings translated into the six catalog languages. Verified live in simulator (nb + en): sheet, footer, and the privacy link opening the live site. The about sheet is the seed for #6's settings surface.
- [ ] **3. Generation task lifecycle** — owned, cancellable task; series episode number re-read at commit time; don't push a stale profile's reader over the active one. (The meter double-spend half was fixed in PR #35: the household-wide reservation ledger claims the credit synchronously at tap time.)
- [x] **4. StoreKit entitlement lifecycle** — PR #35, from the 2026-07-24 external money-path review (2 P1, 1 concurrency risk, 3 P2, all verified then fixed): billing-grace families keep Fable+ (membership in currentEntitlements IS the access decision; the local expiry re-check was the lockout, and a test had encoded it); latest-wins refresh generation so a stale entitlement snapshot can never overwrite a refund or hide an approval; injectable StoreClient boundary with deterministic tests for grace, refund-mid-refresh, update-stream approval (Ask to Buy) and revocation, and restore outcomes; honest paywall outcomes (pending/offline/nothing-to-restore each get a calm line, auto-dismiss whenever entitlement arrives — this covers pending→success and the cold-start paywall flash); catalog retry on foreground and on paywall open; genuinely idempotent start(); the yearly free week modeled in the local StoreKit config. Deliberately not added: an expiry timer (foreground + update-stream refresh cover it without a clock to defend).
- [ ] **5. Curated series continuity** — episode-aware curated framing (gated recap as "previously on", same characters, episode title) or stop selling continuation where it can't be delivered. Honesty either way.
- [ ] **6. Explicit persistence + profile management** — modelContext.save() with error surfacing at profile/story/series commits; edit + delete profiles (delete rules rethought: deleting a child must not globalize their stories); story deletion; a settings surface (also hosts #2's links, subscription management, transparency about which engine told a story).
- [ ] **7. Editorial pass on fr/it/pt-BR prose** — apply the reviewer's concrete fixes (gender-neutral endings replacing fatigué/stanco/bem coberto + petit marin family; restructure de/di/nas costas + slot contractions; de-calque flagged phrases; pt-BR guillemets → curly quotes; age-band diminutive density). Their suggested lines are good — take them.
- [ ] **8. Meter robustness** — clamp future-dated stories to now (clock-jump forgiveness); document the 604800s week as intentional.
- [x] **9. Denylist normalization** — done inside PR #34 round two (NFKC-fold + strip format/zero-width + collapse NBSP before every match). Layered-defense framing stays documented.
- [ ] **10. Prompt hygiene** — move the child's name out of instruction position into delimited user data in the prompt.
- Accepted risks, documented: third-language code-switching detection (no on-device semantic classifier; layered mitigations), reinstall-loses-library (privacy trade-off — to be communicated in-app), nil-profile legacy visibility until #6's migration.

## Milestone 5 — Grow (post-1.0)

- [ ] Illustrations via ImagePlayground (cover art per story)
- [ ] Seasonal collections (premium curated templates)
- [ ] iPad layout, then Mac Catalyst evaluation
- [ ] Story audio: AVSpeechSynthesizer narration with parental voice options

## Milestone 6 — Launch marketing (starts when 1.0 is approved; no paid spend until LTV data)

- [ ] Apple featuring nomination (App Store Connect → Featuring): the pitch writes itself — on-device Foundation Models, one-line privacy label, Family Sharing, calm design. Submit with v1.1's multilingual release as the hook. Claude drafts, owner submits.
- [ ] Press kit page on the site (icon, screenshots, fact sheet, founder line) + pitch emails to Apple-ecosystem press (MacStories, 9to5Mac) and parenting-tech press. Claude drafts; owner sends.
- [ ] Norway beachhead with v1.1: Norwegian store page goes live, owner's network + Norwegian parenting communities; shallow local charts make early visibility realistic.
- [ ] Show HN + dev-story blog posts on the site ("an AI bedtime app with no server", "the safety gate") — the on-device architecture is genuinely interesting to that audience. Timed with v1.1.
- [ ] In-app review prompt, calm edition: SKStoreReviewController after a delight moment (e.g. closing the storybook on a re-read), never during first-run or generation, hard-capped frequency.
- [ ] Story cards (v1.2 growth bet): export a finished story as a beautifully typeset shareable image — organic family-group-chat distribution with zero servers, on brand.
- [ ] Apple Search Ads: only after 30+ days of trial/LTV data, brand + high-intent exact terms.
- [ ] Measurement stays ASC-only (impressions → page views → installs → trials → paid): the no-tracking promise holds; it's enough to steer ASO and featuring.

## Icebox / ideas

- Watch app: "wind-down" audio-only mode
- Sibling mode: one story, two heroes
- "Story sparks" widget: tonight's suggestion on the lock screen
