# CLAUDE.md — Working agreement for Fable

Fable is a solo-owned, agent-developed product: a personalized bedtime-story iOS app monetized via a Fable+ subscription. You (Claude) are the engineering team. The repository owner provides external accounts (Apple Developer, etc.) on request but does not review code — **CI and your own review discipline are the quality gate.**

## Session protocol (especially cron-triggered sessions)

1. Read `docs/ROADMAP.md`. Pick the **top unchecked item** in the earliest open milestone that is not `BLOCKED ON OWNER`.
2. Work on a branch `feat/<slug>` (or `fix/`, `ci/`, `docs/`). Never commit broken code to `main`.
3. Definition of done: code builds, **tests pass locally** (`xcodebuild … test`), roadmap updated, PR opened with a clear description, merged after CI is green (auto-merge is acceptable; you are the reviewer — actually review the diff before merging).
4. If a session ends mid-task, leave the branch pushed and note the state in the PR description; the next session resumes it before starting anything new.
5. Surface anything that needs the owner (accounts, credentials, App Store Connect actions) in `docs/OWNER-ASKS.md` — keep it current; the owner checks it.

## Build & test

```bash
xcodegen generate   # .xcodeproj is generated, never committed
xcodebuild -project Fable.xcodeproj -scheme Fable \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build test
```

- `project.yml` is the project definition. Edit it, not the xcodeproj.
- Swift 6 strict concurrency is on. Fix data-race warnings properly; do not sprinkle `@unchecked Sendable`.
- Unit tests use Swift Testing (`import Testing`, `@Test`). Curated story engine tests must stay deterministic (seeded RNG).

## Product guardrails (do not regress these)

- **Privacy:** no analytics SDKs, no network calls in the app. Story generation is on-device only. If a feature seems to need a server, write an ADR first and add an owner ask.
- **Bedtime calm:** no streaks, badges, ads, or dark patterns. Paywall copy is honest; free tier stays genuinely useful (3 starter stories + 1/week).
- **Content safety:** everything shown to a child passes the post-check pass (see ADR 0003). Model output is never displayed unchecked.
- **Never break bedtime:** any AI failure falls back silently to the curated engine. No error alerts in the story flow.

## Conventions

- Conventional commits; ADRs in `docs/adr/` for surprising decisions; update `docs/ROADMAP.md` in the same PR as the work.
- Match existing code style; comments only for non-obvious constraints.
- App code lives in `App/Sources/`, tests in `App/Tests/`. Curated story templates in `App/Sources/StoryEngine/Curated/`.
