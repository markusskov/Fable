# App Store metadata (copy-paste ready)

Prepared 2026-07-23 for the App Store Connect app record. Update alongside any
feature change that alters what the store page promises.

## Name & subtitle

- **Name (30 chars max):** `Fable Bedtime` (13) — fallback if taken: `Fable: Bedtime Stories` (22)
- **Subtitle (30 chars max):** `Stories starring your child` (27)

## Category

- Primary: **Kids** — no. Deliberately **Lifestyle** (primary) / **Books** (secondary).
  The operator is the *parent*; staying outside the Kids category avoids the
  Kids-category restrictions while our privacy posture (no tracking, no ads,
  nothing leaves the device) already exceeds them. Revisit if ASO data suggests
  otherwise.

## Description

> **Tonight's story stars the person your child loves most: themselves.**
>
> Fable turns your child's name, their favorite sidekick, and the cozy thing
> they sleep with into a brand-new bedtime story — imagined fresh on your
> iPhone, every night.
>
> **Completely private.** Stories are generated entirely on your device with
> Apple Intelligence. No account. No cloud. Nothing about your child ever
> leaves the phone — we couldn't read it if we wanted to, and we designed it
> that way on purpose.
>
> **Calm by design.** A warm, quiet reading experience for the last fifteen
> minutes of the day. Generous storybook type, a page-turn made for sleepy
> thumbs, and never a notification, streak, or ad. The screen even stays lit
> while you read aloud.
>
> **Always a story.** Even without Apple Intelligence, Fable's hand-written
> story library steps in — personalized, beautiful, and ready every night.
>
> **Free, forever:** three starter stories, then a fresh story every week,
> and your whole library to re-read anytime.
>
> **Fable+** makes story time unlimited:
> • A new story every night — as many as bedtime needs
> • Story series: continuing adventures, night after night
> • A profile for every child in the family
> • Family Sharing included
>
> Fable+ is $4.99/month or $39.99/year with a 7-day free trial.
> Subscriptions renew automatically until cancelled in Settings.
>
> Sweet dreams.

## URLs

- **Support URL:** `https://markusskov.github.io/Fable/`
- **Privacy Policy URL:** `https://markusskov.github.io/Fable/privacy.html`
- Source lives in `site/`; pushed to `main` it auto-deploys via `.github/workflows/pages.yml`.

## Keywords (100 chars max)

`bedtime,story,stories,kids,sleep,children,fairy tale,night,calm,toddler,storytime,ai` (84)

## Promotional text (170 chars max)

> A new bedtime story every night, starring your child — imagined privately on
> your iPhone with Apple Intelligence. No accounts, no ads, nothing leaves the
> device. (159)

## What's New (v1.0)

> The very first Fable. Personalized stories on-device, story series for
> continuing adventures, profiles for every child, and a calm reader made for
> reading aloud. Tell us what your family thinks — we read everything.

## App Review notes

- Fable generates children's bedtime stories **on-device** using Apple's
  FoundationModels framework; there is no server component and the app makes
  no network calls except StoreKit.
- Model output passes a structural + content safety gate before display
  (`App/Sources/StoryEngine/ContentSafetyCheck.swift`); any rejection falls
  back to a hand-written story library bundled with the app.
- The app is operated by the parent, reading aloud to their child.
- Subscription: Fable+ (monthly/annual, 7-day trial) unlocks unlimited
  stories, story series, and additional child profiles. The free tier is
  permanent: 3 starter stories, then one story per week, full library access.
- Restore Purchases is on the paywall footer. No account or login exists.
- To review quickly: create a profile (any name), pick a theme, "Tell
  tonight's story". On review devices without Apple Intelligence the curated
  library serves the story — same flow, no error states.

## Age rating questionnaire (expected answers)

Everything "None" (no violence, fear themes are actively filtered, no user
generated content, no web access, no gambling). Made-for-kids: **No** (parent
is the operator); age rating lands at 4+.

## Privacy nutrition label (App Privacy section)

- **Data collection: none.** The app collects no data, links no data to the
  user, and does not track. Child profiles and stories live in on-device
  SwiftData (no CloudKit in v1).
- Purchases are processed by Apple; the app itself stores no purchase data
  beyond StoreKit's local entitlements.
- Answer "Data Not Collected" for every category. The privacy label should be
  exactly one line. That's the product.
