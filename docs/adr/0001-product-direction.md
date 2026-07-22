# ADR 0001: Product direction — personalized bedtime stories, iOS-first, subscription

- **Status:** Accepted
- **Date:** 2026-07-22

## Context

This repository has a single mandate: build a professional product that generates MRR, with full autonomy over product and technical choices. The development environment is a Mac (Apple M5, macOS 26.5) with Xcode 26.6, iOS 26 SDK (FoundationModels and ImagePlayground frameworks present), iOS simulators, and an authenticated GitHub account. There is no pre-existing hosting, payment, or email infrastructure.

## Options considered

1. **Web SaaS** (e.g., developer tooling, monitoring). Requires hosting, Stripe, a domain, transactional email, and ongoing marketing to a crowded audience — four external accounts before the first dollar, plus server opex.
2. **macOS utility with license sales.** Viable, but typically one-time purchases (weak MRR fit) and a brutal discovery problem outside the Mac App Store.
3. **iOS consumer subscription app.** The App Store is payments + distribution + tax handling in one; the only external dependency is an Apple Developer account. Recurring revenue is native to the platform.

## Decision

Build **Fable: personalized bedtime stories for kids**, iOS-first, monetized with a StoreKit 2 auto-renewing subscription (**Fable+**).

Key reasons:

- **Structural advantage, not just an idea:** Apple's on-device Foundation Models (iOS 26) allow truly private, zero-marginal-cost story generation. Cloud-based competitors pay per story and must upload children's personal details; we do neither. "Your child's data never leaves the phone" is a marketing claim competitors cannot copy.
- **Proven willingness to pay:** kids' story/audiobook apps are an established subscription category; parents pay for calm, screen-positive bedtime tools.
- **Matches the environment:** the entire build-test-ship loop (Xcode, simulators, TestFlight) runs locally on this machine. No infrastructure to stand up or pay for.
- **The name.** The repository is called Fable. Some decisions make themselves.

## Consequences

- Revenue requires the repository owner's Apple Developer Program membership for App Store Connect, TestFlight, and product setup (subscription SKUs). This is the single external ask.
- Minimum deployment target is iOS 26 to use FoundationModels. This narrows the initial addressable market to recent devices; mitigated by a curated fallback story engine (see ADR 0003) so the app still delights on any iOS 26 device without Apple Intelligence.
- Kids-adjacent category means App Review scrutiny on content safety and privacy. On-device generation with guardrails plus a curated fallback is our answer; the app targets the *parent* as the operator, not the child (affects App Store category and parental gate design).
- No backend means no server-side analytics; funnel measurement relies on App Store Connect metrics. Accepted trade-off for v1.
