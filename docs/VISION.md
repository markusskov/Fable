# Vision

## The one-liner

Fable makes the last fifteen minutes of a child's day magical: a bedtime story that stars *them*, invented fresh every night, told in a calm and beautiful reading experience — with absolute privacy, because everything happens on the device.

## The customer

Parents of children roughly aged 2–9 who:

- want a bedtime ritual that isn't a glowing YouTube feed,
- run out of story ideas (or energy) at 8pm,
- are increasingly privacy-anxious about apps aimed at their kids,
- already pay for subscriptions when the value is obvious (audiobook apps, kids' learning apps).

## Why now

Apple shipped on-device generative models (Foundation Models framework, iOS 26). For the first time, a story app can honestly say: *your child's name, fears, and interests never leave the phone.* Cloud-based AI story apps can't say that, and their marginal cost per story forces them into aggressive paywalls and data trade-offs. Our marginal cost per story is zero.

## Product principles

1. **Bedtime is sacred.** Every design decision optimizes for winding *down*: warm colors, generous type, no badges, no streaks, no notifications after dusk beyond an opt-in "story time" reminder.
2. **The parent is the storyteller, Fable is the muse.** The app assists the ritual; it doesn't replace the parent. Reading aloud together is the default experience.
3. **Privacy is a feature, stated plainly.** No account. No analytics SDK that phones home with content. The privacy nutrition label should be embarrassingly short.
4. **Never a blank page, never a broken promise.** If on-device AI is unavailable (older device, model not downloaded), the curated story engine delivers a great personalized story anyway. The free tier is genuinely useful; the paid tier is genuinely better.
5. **Quality over surface area.** One platform (iOS) done excellently before expansion (iPad optimization → Mac → Watch "audio-only wind-down" later).

## Monetization

- **Free:** 3 personalized stories to start, then 1 new story per week. Full reading experience, no ads, forever.
- **Fable+** (auto-renewing subscription, StoreKit 2):
  - Unlimited new stories
  - Story *series* (continuing adventures with the same characters)
  - Premium themes & seasonal collections
  - Multiple child profiles
- Pricing intent (final prices set in App Store Connect): ~\$4.99/month, ~\$29.99/year with 7-day free trial. Family Sharing enabled — it's a family app; goodwill compounds.

## What success looks like

- **v1.0 in App Store** with a conversion funnel we can measure through App Store Connect alone.
- **North star:** weekly stories read per subscriber (retention proxy), not raw downloads.
- **MRR path:** niche-app economics — thousands of subscribers, not millions. A calm, sustainable compounding product.

## Explicitly out of scope (for now)

- Android, web.
- Cloud accounts or cross-device sync beyond iCloud's free built-ins (CloudKit private DB later, still no accounts).
- Voice cloning / TTS narration in v1 (evaluate AVSpeechSynthesizer personal voices later).
- User-generated content sharing or any social features. It's a bedtime app.
