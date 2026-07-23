# Owner asks

Things only the repository owner can provide. Items move to *Done* when confirmed. Nothing here blocks current work unless marked.

## Open

1. **App Store Connect — remaining gaps** (record reviewed 2026-07-23; core setup confirmed correct: "Fable Bedtime", bundle `com.markusskov.fable`, Apple ID 6793714797, Lifestyle/Books, 4+, metadata pasted):
   - Support URL empty (required for review) → paste `https://markusskov.github.io/Fable/` (live as of 2026-07-23; ask Claude to move it if you'd rather use a custom domain)
     - Note: the site lists **markusskov@gmail.com** as the support/privacy contact. If you'd prefer an alias (e.g. iCloud Hide-My-Email or a dedicated address), say so and Claude will swap it.
   - Copyright field empty → `2026 Markus Skov`
   - DSA trader status is "non-trader" — with paid subscriptions the EU requires trader compliance (published contact info); either complete it or we exclude EU territories at launch. Owner decision.
   - ~~Confirm subscriptions~~ ✅ verified 2026-07-23: both SKUs (`…monthlyy`/`…annualy`), $4.99/$39.99, Family Sharing on both, free 1-week intro offers, reference names cleaned up
   - ~~App Privacy questionnaire~~ ✅ "Data Not Collected" set — remember to hit **Publish** on the App Privacy page
   - Privacy Policy URL (required before submission) → paste `https://markusskov.github.io/Fable/privacy.html` (live as of 2026-07-23)
   - App Accessibility section (audit shipped 2026-07-23): declare **VoiceOver, Voice Control, Larger Text, Dark Interface, Sufficient Contrast, Reduced Motion**; do NOT declare Differentiate Without Color Alone or Captions/Audio Descriptions
   - Screenshots ready in `docs/appstore/screenshots/6.9/` (upload order in docs/appstore/metadata.md → Screenshots). Claude will upload them with the TestFlight/ASC-API lane; if you're in ASC sooner, drag the six PNGs into the 6.9" iPhone slot in numbered order
   - Build upload is Claude's side (TestFlight lane next)
2. **Your framed screenshots in `docs/appstore/AppstoreImages/`** (found untracked 2026-07-23): they look great, but at 390×844 px they're too small for App Store Connect — the 6.9" slot only accepts 1320×2868. If you want this framed style on the store page, say so and Claude will rebuild the frames at full resolution from the scripted capture lane; otherwise the plain set in `docs/appstore/screenshots/6.9/` is upload-ready. Left untracked until you decide.

## Done

- **Apple Developer Program membership** — confirmed by owner 2026-07-22. ✅
- **App name** — owner decided 2026-07-22: revisit together at TestFlight time ("Fable" is likely taken; "Fable Bedtime" is the working candidate). ✅
- GitHub repository + authenticated `gh` CLI on the dev machine. ✅ (pre-existing)
- Xcode 26.6 + iOS 26 SDK + simulators. ✅ (pre-existing)
