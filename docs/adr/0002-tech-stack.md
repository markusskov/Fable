# ADR 0002: Tech stack and repository conventions

- **Status:** Accepted
- **Date:** 2026-07-22

## Decision

| Concern | Choice | Rationale |
| --- | --- | --- |
| UI | SwiftUI, iOS 26+ | Modern, fast to iterate, first-class with Swift 6 concurrency. |
| Language | Swift 6 (strict concurrency) | Senior-quality default in 2026; catches data races at compile time. |
| Story AI | FoundationModels framework (on-device) | Zero marginal cost, private, offline. See ADR 0003 for fallback. |
| Persistence | SwiftData | Native, sufficient for profiles + story library; CloudKit-ready later. |
| Payments | StoreKit 2 | Native subscriptions, transaction verification built in. |
| Project generation | XcodeGen (`project.yml` committed, `.xcodeproj` gitignored) | Reviewable diffs, no pbxproj merge conflicts, CI regenerates deterministically. |
| Tests | Swift Testing (`@Test`) + XCTest UI tests later | Swift Testing is the current-generation framework. |
| CI | GitHub Actions, macOS runner | Build + unit tests on every push and PR to `main`. |
| Formatting | `swift-format` via build of record; keep default style | Avoid bikeshedding; consistency over preference. |

## Repository conventions

- **Trunk-based:** `main` is always releasable. Feature work on short-lived `feat/…` branches, merged via PR once CI is green. Solo-with-agents still uses PRs: CI is the reviewer of record, and PR descriptions are the changelog.
- **Conventional commits** (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`) for a readable history and future changelog automation.
- **ADRs** in `docs/adr/` for any decision that would surprise a senior engineer reading the code cold.
- **Versioning:** semver-ish marketing versions (`1.0`, `1.1`), build number = CI run number once release automation exists.

## Consequences

- Anyone (human or agent) cloning the repo needs `xcodegen` (`brew install xcodegen`) before opening the project. Documented in README; CI installs it explicitly.
- SwiftData and FoundationModels pin us to current-OS APIs — deliberate, per ADR 0001.
