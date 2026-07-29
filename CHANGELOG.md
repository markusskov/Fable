# Changelog

All notable changes to Fable. Sections are generated from conventional
commits by `scripts/release.sh` — do not edit generated sections by hand;
fix the commit subjects before releasing instead.

<!-- insert: newest release below this line -->

## v1.1 (build 6) — 2026-07-29

### Features
- story cards — the whole story as one shareable image (v1.2 growth bet, shipped early) (#61)
- in-app review prompt, calm edition (Milestone 6) (#58)
- read-aloud narration with Personal Voice support (Milestone 5) (#55)
- iPad support via a reading-column layout (Milestone 5) (#54)
- cover art per story via ImagePlayground (Milestone 5) (#51)
- profile management, story deletion, and honest persistence (finding #6) (#44)
- curated series continuity + faster safety-gate matching (external review finding #5) (#42)
- in-app Privacy Policy and Terms links (review blocker #2) (#37)
- Brazilian Portuguese (pt-BR) — the launch sprint is complete (#32)
- Italian (it-IT) — fourth language of the launch sprint (#31)
- French (fr-FR) — third language of the launch sprint (#30)
- per-language yield measurement + structural goodnight fix — 8/8 all languages (#29)
- Spanish (es-ES) — second language of the launch sprint (#28)
- German (de-DE) — first language of the launch sprint (#27)
- Norwegian curated story templates (nb shelf) + language-aware defaults (#26)
- story language plumbing — request language, model gating, language-aware safety gate, curated fallback (#25)
- String Catalog infrastructure + Norwegian (nb) UI translations (#23)
- show the free week on the paywall (#22)

### Fixes
- catalog loads go through the StoreClient seam (#66)
- EULA link in every App Description (guideline 3.1.2 rejection) (#62)
- show the narration voice and where the warmer one lives (#56)
- no mid-read cover swap, and one cover per series (owner testing feedback) (#53)
- clock-jump forgiveness in the meter, and fence parent data in the prompt (#50)
- stop the curated shelves addressing every child as a boy (finding #7) (#49)
- localize the profile-deletion copy, and fix its English grammar (#47)
- App Store review blockers — privacy manifest, build 4, honest marketing (#45)
- money-path round two — operation truth, one paywall gate, listener lifecycle (#41)
- remove em dashes from all customer-facing copy (owner style rule) (#38)
- translate review-fix copy into all six languages (#36)
- money-path hardening from the external StoreKit review (#35)
- brace-strip parent-typed slot values — a child named {sound} could hijack template substitution nondeterministically (#33)

### Other
- Fable Bedtime is live — launch smoke test passed with a real purchase (#67)
- Approval record + v1.1 dossier with What's New ×7 (#65)
- Extensionless privacy link + catalog guard covers partial resolution (#64)
- Catalog test: known-issue stand-down when storekitd drops the config (#63)
- 13-inch iPad screenshot sets in all seven languages (#60)
- launch drafts — featuring pitch, press kit, blog posts, Show HN, support templates, first-day checklist (#59)
- Normalize model apostrophes; fix Norwegian genitives (#57)
- Seasonal collections: Summer Nights in seven languages (Milestone 5) (#52)
- measure App Store metadata limits, and fix the two fields over them (#48)
- v1.0 build 5 submitted for review
- stop hardcoding prices in the localized listings
- build 5
- screenshot captions for all seven languages
- correct the screenshot note, the ellipsis was deliberate
- record the screenshot review findings and the 2.3.2 decision
- capture every scene in all seven languages (#46)
- money path closed after fourteen adversarial review rounds
- Money-path round three: Apple's purchase order, one winning refresh, honest save handoff (#43)
- Own the story-generation task and guard its commit (external review finding #3) (#40)
- owner ask — enable branch protection on main (#39)
- PR #34 merged — safety fail-open closed after four review rounds
- Close the provider-wide safety fail-open (external review, blocker #1) (#34)
- round-two review closed in PR #34; denylist normalization done
- external review triage — ordered findings, release gate, accepted risks
- README catches up with reality — in review worldwide, seven languages, live pricing
- roadmap hygiene — clear completed ASC blocker and a stale duplicate line
- review follow-up (per-language model yield) + launch marketing milestone
- un-stale re-extracted paywall strings in Localizable.xcstrings
- record owner approval of Norwegian stories (PR #26 merged)
- guard Localizable.xcstrings (required languages, plurals, format specifiers) (#24)
- owner ask — skim the Norwegian UI copy from PR #23 (non-blocking)
- 48-hour language sprint scoped — nb first, then de/es/fr/it/pt-BR; CJK deferred
- no em dashes in the Norwegian store copy (owner style)
- Norwegian App Store metadata pack — pastes with v1.1, the version that speaks Norwegian
- localization becomes the active milestone — worldwide availability selected for launch
- SUBMITTED — 1.0 (build 3) + subscriptions Waiting for Review
- accessibility declared; trial verified live; submission checklist final
- localization starts with Norwegian — founder's family is the first market
- free trial moves to yearly-only (owner strategy, research-backed)
- TestFlight live (v1.0 build 2 via Xcode Cloud); Small Business Program enrolled
- Xcode Cloud post-clone hook — regenerate the gitignored xcodeproj

## v1.0 (build 2) — 2026-07-23

### Features
- store-ready App Store images from owner's framed Figma set
- release automation — version/build bump, changelog, GitHub Release workflow (#20)
- App Store screenshot set + reproducible capture lane (#19)
- onboarding polish — keyboard flow, optional-field copy, softer first-run handoff (#18)
- support site + privacy policy on GitHub Pages (#17)
- 'Close the storybook' on the end page (owner feedback) (#16)
- device signing + export-compliance exemption (#15)
- accessibility audit — Reduce Motion + VoiceOver fixes (#14)
- app icon — gold crescent over a sleeping night (#11)
- multiple child profiles (Fable+) (#10)
- story series — continuing adventures (Fable+) (#9)
- raise model yield — merge below-floor mid pages forward (#8)
- free-tier metering and the Fable+ paywall (#7)
- StoreKit 2 foundation for the Fable+ subscription (#4)
- reader polish — tap-to-turn pages, warmer theme, Dynamic Type audit (#3)
- Fable foundation — docs, curated story engine, UI shell, CI

### Fixes
- accept two-part versions — the store version string is '1.0'
- emit 6.7-inch (1284x2778) store screenshots — the size ASC actually accepts
- adopt replacement ASC product IDs (monthlyy/annualy) (#13)
- address 2026-07-22 review findings (#6)
- make the on-device generation test assert the real contract (#5)

### Other
- owner completed the ASC record — accessibility declaration + submission day remain
- frame 2 caption fixed — 'Or continue the story.'
- subs + privacy verified; queue accessibility audit and support site
- ASC record reviewed — correct; track remaining gaps (support URL, copyright, DSA trader, subs confirmation, privacy answers)
- App Store metadata pack — copy, keywords, review notes, privacy answers (#12)
- queue 2026-07-22 review findings (PRs #2-#5 code + UI review)
- Calmer model prompts, fuller pages, deeper content safety checks (#2)
- On-device story generation via FoundationModels (#1)
- record owner confirmations (Apple Developer active, naming at TestFlight)
- first commit
