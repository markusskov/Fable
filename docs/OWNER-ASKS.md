# Owner asks

Things only the repository owner can provide. Items move to *Done* when confirmed. Nothing here blocks current work unless marked.

## Open

1. **Norwegian story-safety vocabulary — skim when you have 10 minutes (not blocking).** Story-language plumbing landed: when a device runs in Norwegian and Apple Intelligence supports it, model stories are written in bokmål and judged by Norwegian safety vocabularies. As the native speaker, skim the two lists in `App/Sources/StoryEngine/ContentSafetyCheck.swift` (`norwegianDeniedWords`, `norwegianSleepSignals`) and the bokmål directive in `App/Sources/StoryEngine/StoryLanguage.swift`. Deliberate calls to sanity-check: homonyms «dør»/«redde»/«kjempe» are NOT denied (false positives on door/rescue/giant); «redd» IS denied; a Norwegian story must wind down with Norwegian sleep words — an English "goodnight" ending is rejected on purpose.
2. **SUBMISSION DAY — the App Store Connect work, in order.** Build 3 was withdrawn (it predated the safety fixes and had no in-app legal links). Everything on the code side for a replacement is done: build number is now **4**, the privacy manifest ships, and the listing text below is corrected. What is left is yours.

   **a. Screenshots (your Figma set).** Two changes, then re-export:
   - **Guideline 2.3.2 wording.** Screenshot 02 currently promises "A new story every night" and continuing stories as if they were free. They are Fable+ only. Change that caption to **"With Fable+: a new story every night"** and the series caption to **"Continue adventures with Fable+"**. Apple rejects listings that show premium capability without saying it needs a purchase.
   - **No transparency.** Every current file in `docs/appstore/store-ready/` carried an alpha channel, which ASC refuses. That is fixed in the repo now, and `scripts/prepare-store-images.sh` flattens automatically and fails loudly if any file still has alpha. Re-run it after you export, and upload from `store-ready/6.7/`.

   **b. Listing text.** Copy fresh from `docs/appstore/metadata.md` (promotional text, description, and App Review notes all changed). The promotional text now marks Fable+, the description no longer hardcodes $4.99/$39.99 (metadata follows *language*, not storefront, so a US price could reach a Norwegian wallet), and the absolute "nothing ever leaves the phone" is now the accurate "Fable never sends or collects".

   **c. Verify the subscription package** before pressing submit. The repo cannot see ASC, so please confirm each:
   - Both product IDs are **Ready for Review** and attached to *this* submission's item list (stage them via Add for Review on the group page first).
   - Both sit in group `21654001` at the same level.
   - `...plus.monthlyy` has **no** introductory offer; `...plus.annualy` has **one 7-day free trial**.
   - Family Sharing on for both; territories as intended.
   - Each product has a review screenshot and a customer-facing localization.

   **d. Paste the App Review notes** from `docs/appstore/metadata.md`. They now tell the reviewer exactly how to reach the paywall (profile button, upper left, then "Add a child"), because a fresh install has three starter stories and the meter will not surface it on its own. They also state that the trial is annual-only, which the old note got wrong.

   **e. Upload build 4**, set release to **Manual**, press Add for Review. Leave withdrawn build 3 unselected.

3. **Keywords — your call, 1 minute.** Current: `bedtime,story,stories,kids,sleep,children,fairy tale,night,calm,toddler,storytime,ai`. The external audit suggests dropping bare `kids`/`children`/`toddler` to reduce any chance a reviewer reads the app as belonging in the Kids Category (which would then require a parental gate before the paywall and external links). My read: the risk is low, because the Kids Category is opt-in and our listing is explicitly parent-directed, and those are high-intent search terms worth real installs. **Recommendation: keep them.** If you would rather take zero risk, use `bedtime,story,stories,sleep,fairy tale,night,calm,storytime,read aloud,family,parents,ai` instead.
3. **Branch protection on `main` — 2 minutes, not blocking.** `main` has no protection rules, so `gh pr merge --auto` merges the moment a PR is mergeable instead of waiting for CI (observed on PR #38, 2026-07-24; the change was fully tested locally, and post-merge CI passed, so nothing shipped broken). To make "merged after CI is green" enforced rather than discipline: GitHub → Settings → Branches → Add branch ruleset for `main`, require status checks "Build & test (iOS Simulator)" and "Release script (dry run)". Or say the word and a session runs the equivalent `gh api` call. Until then, sessions merge only after watching CI finish.

## Done

- **Norwegian curated stories review** — owner tried the app in Norwegian and approved 2026-07-23; PR #26 merged. ✅
- **Norwegian UI copy skim** — covered by the same Norwegian walkthrough 2026-07-23. ✅
- **App Accessibility declaration** — completed by owner 2026-07-23 (six features per the audit). ✅
- **Free trial strategy** — yearly-only per owner (research-backed); verified live in build 3: "7 days free, then 499 kr/år", monthly plain. ✅

- **TestFlight live** — 2026-07-23: v1.0 (build 2) built by Xcode Cloud from `main`, processed, installable on the owner's device. ✅
- **App Store Small Business Program** — owner enrolled 2026-07-23: 15% commission on Fable+ instead of 30%. ✅
- **ASC record complete** — owner confirmed 2026-07-23: DSA trader status fixed, Copyright set, Support URL + Privacy Policy URL set and published, App Privacy "Data Not Collected" published, subscriptions verified ($4.99/$39.99, Family Sharing, 1-week free trials), framed screenshots (6.7", 1284×2778) uploaded. ✅
- **Apple Developer Program membership** — confirmed by owner 2026-07-22. ✅
- **App name** — owner decided 2026-07-22: revisit together at TestFlight time ("Fable" is likely taken; "Fable Bedtime" is the working candidate). ✅
- GitHub repository + authenticated `gh` CLI on the dev machine. ✅ (pre-existing)
- Xcode 26.6 + iOS 26 SDK + simulators. ✅ (pre-existing)
