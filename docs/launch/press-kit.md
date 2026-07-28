# Press kit (content for site/press.html; owner publishes at launch)

## Fact sheet

- **App:** Fable Bedtime
- **What:** Personalized bedtime stories for children 2 to 9, written fresh
  every night on the device itself.
- **Platform:** iPhone and iPad, iOS 26+
- **Price:** Free (3 starter stories + 1 story a week, forever). Fable+
  subscription for unlimited stories, story series, and profiles for every
  child. Family Sharing included. 7 day free trial on the yearly plan.
- **Privacy:** No account. No server. No analytics. App Store privacy
  label: Data Not Collected. Story generation runs on device with Apple
  Intelligence; when unavailable, a hand-written story shelf steps in.
- **Languages:** English, Norwegian, German, Spanish, French, Italian,
  Brazilian Portuguese. Stories, not just menus: each language's story
  shelf is written by hand in that language.
- **Safety:** every story a child sees passes a language-aware content
  gate before display. If anything fails, a calmer path takes over
  silently. There are no error screens at bedtime.
- **Founder:** Markus Skov (Norway). Fable is built by a team of AI
  engineering agents under the founder's direction, which we are happy to
  talk about.
- **Support:** https://markusskov.github.io/Fable/
- **Press contact:** markusskov@gmail.com

## One-paragraph description

Fable writes your child a brand-new bedtime story every night: their name,
their little companion, their favorite comfort object, woven into a calm
tale that always lands softly in sleep. Everything happens on the phone
itself. There is no account to create, no server to trust, and nothing to
collect. When the on-device model cannot write, a shelf of hand-written
stories steps in, so bedtime never waits and never breaks.

## The angle for tech press

The interesting story is architectural: a generative AI consumer app with
literally no backend. Foundation Models write the prose, Image Playground
paints the covers, Personal Voice reads the story in a parent's own voice,
and a deterministic, seeded, hand-written story engine sits underneath as
the always-works floor. The safety design assumes the model is untrusted:
every output crosses a language-aware content gate, and every failure
falls to a calmer layer. Happy to walk through the layered-defense design
or the seven-language editorial process.

## Assets (owner attaches at publish time)

- App icon (1024): rendered from code, `scripts/render-app-icon.swift`
- 6.9" iPhone screenshot set: `docs/appstore/screenshots/6.9/`
- 13" iPad set: captured via the `IPadLayoutTests` lane at v1.1 prep
