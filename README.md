# Fable

**Personalized bedtime stories for your kids — imagined together, told beautifully, private by design.**

Shipping as **Fable Bedtime** on the App Store (v1.0 in review, worldwide). Stories and UI in seven languages: English, norsk, Deutsch, español, français, italiano, and português do Brasil.

Fable is an iOS app that turns a child's name, interests, and a spark of an idea into a one-of-a-kind bedtime story, generated entirely on-device with Apple Intelligence. No accounts, no servers, no data leaving the phone. Just stories.

## Why Fable

- **Personal.** Stories star *your* child — their name, their dog, their favorite dinosaur, the thing they were scared of today.
- **Private.** Generation runs on-device via Apple's Foundation Models. Nothing is uploaded, ever. No account required.
- **Calm by design.** A warm, quiet reading experience built for the last 15 minutes of the day — large type, soft palette, no ads, no gamification.
- **Always works.** A curated story engine provides beautiful stories even on devices without Apple Intelligence.

## Business model

Free tier with 3 starter stories then one per week, and a **Fable+** auto-renewing subscription ($4.99/month, or $39.99/year with a 7-day free trial) for unlimited stories, story series, and a profile per child. Payments are handled entirely by the App Store via StoreKit 2; Family Sharing is on. Support and privacy policy live at [markusskov.github.io/Fable](https://markusskov.github.io/Fable/).

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
