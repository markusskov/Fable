# Owner asks

Things only the repository owner can provide. Items move to *Done* when confirmed. Nothing here blocks current work unless marked.

## Open

1. **Norwegian UI copy — skim when you have 10 minutes (not blocking).** PR #23 shipped the full nb-NO UI translation. As the native speaker, skim the app in Norwegian (Settings → Fable → Language, or run from Xcode with `-AppleLanguages "(nb)"`) and flag anything that reads off. Deliberate calls to sanity-check: "The End" → «Snipp, snapp, snute»; Storybook → «Eventyrbok»; theme prompt reads «Hva skal kveldens historie handle om?». Story text itself is still English — that plumbing is the next roadmap item.
2. **Norwegian story-safety vocabulary — skim when you skim the UI copy (not blocking).** Story-language plumbing landed: when a device runs in Norwegian and Apple Intelligence supports it, model stories are written in bokmål and judged by Norwegian safety vocabularies. As the native speaker, skim the two lists in `App/Sources/StoryEngine/ContentSafetyCheck.swift` (`norwegianDeniedWords`, `norwegianSleepSignals`) and the bokmål directive in `App/Sources/StoryEngine/StoryLanguage.swift`. Deliberate calls to sanity-check: homonyms «dør»/«redde»/«kjempe» are NOT denied (false positives on door/rescue/giant); «redd» IS denied; a Norwegian story must wind down with Norwegian sleep words — an English "goodnight" ending is rejected on purpose.
3. **Norwegian curated stories — your review gates the merge (BLOCKING that PR only).** The three curated templates now exist in bokmål (`App/Sources/StoryEngine/Curated/TemplateLibrary.swift`, the `*Nb` templates) as editorial retellings, per the roadmap this ships only after you, as the native speaker, read them. Fastest check: read the three `pages` arrays aloud as if at bedtime, they must sound like Norwegian bedtime prose, not translation. Also skim the slot pools (settings/sounds/treasures) and the two `moralVariants` each. Approve by commenting/merging the PR, or leave line comments and the next session applies them. Note: intentionally no dashes anywhere in the Norwegian prose (your copy rule).
4. **Submission day — everything else is done.** Attach build 3 to version 1.0, ensure the submission's item list includes BOTH Fable+ subscriptions (stage them via Add for Review on the group page first), set release to **Manual**, press Add for Review. Trial verified live on TestFlight (yearly-only, 7 days) 2026-07-23.

## Done

- **App Accessibility declaration** — completed by owner 2026-07-23 (six features per the audit). ✅
- **Free trial strategy** — yearly-only per owner (research-backed); verified live in build 3: "7 days free, then 499 kr/år", monthly plain. ✅

- **TestFlight live** — 2026-07-23: v1.0 (build 2) built by Xcode Cloud from `main`, processed, installable on the owner's device. ✅
- **App Store Small Business Program** — owner enrolled 2026-07-23: 15% commission on Fable+ instead of 30%. ✅
- **ASC record complete** — owner confirmed 2026-07-23: DSA trader status fixed, Copyright set, Support URL + Privacy Policy URL set and published, App Privacy "Data Not Collected" published, subscriptions verified ($4.99/$39.99, Family Sharing, 1-week free trials), framed screenshots (6.7", 1284×2778) uploaded. ✅
- **Apple Developer Program membership** — confirmed by owner 2026-07-22. ✅
- **App name** — owner decided 2026-07-22: revisit together at TestFlight time ("Fable" is likely taken; "Fable Bedtime" is the working candidate). ✅
- GitHub repository + authenticated `gh` CLI on the dev machine. ✅ (pre-existing)
- Xcode 26.6 + iOS 26 SDK + simulators. ✅ (pre-existing)
