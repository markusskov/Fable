# Owner asks

Things only the repository owner can provide. Items move to *Done* when confirmed. Nothing here blocks current work unless marked.

## Open

1. **App Store Connect setup — NOW BLOCKING (all Milestone 2 features are done, 2026-07-23).** In App Store Connect / developer.apple.com, please:
   - Register bundle ID `com.markusskov.fable` (say if you prefer another prefix)
   - Create the app record — working name **"Fable Bedtime"** (final name decided together; plain "Fable" is likely taken)
   - Create a subscription group "Fable Plus" with two auto-renewing SKUs: `com.markusskov.fable.plus.monthly` ($4.99/month) and `com.markusskov.fable.plus.annual` ($39.99/year), both Family Shareable, each with a 7-day free introductory offer
   - Confirm banking/tax forms are complete (required before paid subscriptions go live)
   - Once the app record exists, I need the app's Apple ID / team ID visible in the project so I can set up signing + a TestFlight upload lane
   Everything on the code side (entitlements, StoreKit config, metadata text, screenshots) I will prepare.

## Done

- **Apple Developer Program membership** — confirmed by owner 2026-07-22. ✅
- **App name** — owner decided 2026-07-22: revisit together at TestFlight time ("Fable" is likely taken; "Fable Bedtime" is the working candidate). ✅
- GitHub repository + authenticated `gh` CLI on the dev machine. ✅ (pre-existing)
- Xcode 26.6 + iOS 26 SDK + simulators. ✅ (pre-existing)
