# Owner asks

Things only the repository owner can provide. Items move to *Done* when confirmed. Nothing here blocks current work unless marked.

## Open

1. **App Store Connect — remaining gaps** (record reviewed 2026-07-23; core setup confirmed correct: "Fable Bedtime", bundle `com.markusskov.fable`, Apple ID 6793714797, Lifestyle/Books, 4+, metadata pasted):
   - Support URL empty (required for review) — Claude will stand up a support page unless you have a domain preference
   - Copyright field empty → `2026 Markus Skov`
   - DSA trader status is "non-trader" — with paid subscriptions the EU requires trader compliance (published contact info); either complete it or we exclude EU territories at launch. Owner decision.
   - **Confirm subscriptions**: Monetization → Subscriptions needs group "Fable Plus" with `com.markusskov.fable.plus.monthly` ($4.99/mo) and `com.markusskov.fable.plus.annual` ($39.99/yr), both Family Shareable, 7-day free intro offer each — not visible in the shared captures
   - App Privacy questionnaire: answer "Data Not Collected" everywhere (docs/appstore/metadata.md)
   - Screenshots + build upload are Claude's side (TestFlight lane next)

## Done

- **Apple Developer Program membership** — confirmed by owner 2026-07-22. ✅
- **App name** — owner decided 2026-07-22: revisit together at TestFlight time ("Fable" is likely taken; "Fable Bedtime" is the working candidate). ✅
- GitHub repository + authenticated `gh` CLI on the dev machine. ✅ (pre-existing)
- Xcode 26.6 + iOS 26 SDK + simulators. ✅ (pre-existing)
