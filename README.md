# Fable

**Personalized bedtime stories for your kids — imagined together, told beautifully, private by design.**

Fable is an iOS app that turns a child's name, interests, and a spark of an idea into a one-of-a-kind bedtime story, generated entirely on-device with Apple Intelligence. No accounts, no servers, no data leaving the phone. Just stories.

## Why Fable

- **Personal.** Stories star *your* child — their name, their dog, their favorite dinosaur, the thing they were scared of today.
- **Private.** Generation runs on-device via Apple's Foundation Models. Nothing is uploaded, ever. No account required.
- **Calm by design.** A warm, quiet reading experience built for the last 15 minutes of the day — large type, soft palette, no ads, no gamification.
- **Always works.** A curated story engine provides beautiful stories even on devices without Apple Intelligence.

## Business model

Free tier with a limited number of stories, and a **Fable+** auto-renewing subscription (monthly / annual, family-priced) for unlimited stories, story series, and premium themes. Payments are handled entirely by the App Store via StoreKit 2.

## Repository layout

| Path | Purpose |
| --- | --- |
| `App/` | Xcode app source (SwiftUI, iOS 26+) |
| `project.yml` | XcodeGen project definition — the `.xcodeproj` is generated, never committed |
| `docs/` | Vision, roadmap, and architecture decision records |
| `CLAUDE.md` | Working agreement for autonomous development sessions |
| `.github/workflows/` | CI (build + tests on every push/PR) |

## Development

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project Fable.xcodeproj -scheme Fable -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build test
```

See [docs/ROADMAP.md](docs/ROADMAP.md) for what's next and [docs/adr/](docs/adr/) for why things are the way they are.
