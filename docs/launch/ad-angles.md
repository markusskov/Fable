# Ad angle inventory — hooks and scenes

Rewritten 2026-07-30 after the owner's creative verdict on v1: statements
don't sell, hooks do. Every angle now carries a HOOK (the feeling that
stops the thumb), a SCENE (the image-generation prompt for the emotional
layer), and SUPPORT (the primary text that explains). The deterministic
factory composites brand type over the generated scene; product UI
appears small or not at all.

Rules unchanged: every claim true, ads held to the paywall's honesty bar,
no fake people presented as real users, no urgency mechanics. English
first; winners get localized.

Shared scene style suffix: "warm storybook illustration, cozy nighttime
blues and deep violet with golden light, soft and calm, no text".

## 1. Same-story fatigue
- HOOK: "You've read that dinosaur book 400 times. Tonight: something new."
- SCENE: a well-loved, visibly worn stack of the same children's books on
  a nightstand, one lamp, night bedroom.
- SUPPORT: "Fable writes a brand-new bedtime story every night, starring
  your child. Made on your phone, by your phone."

## 2. In the story (personalization)
- HOOK: "He asks for the same story every night. Tonight, he's IN it."
- SCENE: a small child tucked in bed, wide-eyed and delighted, listening;
  a parent silhouette reading from a softly glowing phone.
- SUPPORT: "Their name. Their stuffed fox. Their cozy blanket. Woven into
  tonight's story."

## 3. Asleep before the last page
- HOOK: "She fell asleep before the last page. Again. (That's the point.)"
- SCENE: a child fast asleep mid-story, book-light glow fading, a parent
  tiptoeing out of frame.
- SUPPORT: "Stories engineered to wind down. No cliffhangers, no
  excitement spikes. Every ending lands in sleep."

## 4. The privacy flip
- HOOK: "A bedtime app that knows your kid's name. And never tells anyone."
- SCENE: a phone face-down on a nightstand next to a sleeping child, moon
  through the window, everything at rest.
- SUPPORT: "No account. No ads. No analytics. Privacy label: Data Not
  Collected. Stories are written on the device and never leave it."

## 5. The bedtime negotiation
- HOOK: "The bedtime negotiation ends tonight. You come armed with a story
  about THEM."
- SCENE: a hallway at night, a small determined child in pajamas facing a
  tired but smiling parent, warm light from the bedroom door.
- SUPPORT: "One tap. A fresh story where your child is the hero. Suddenly
  bed is where the good stuff happens."

## 6. Your voice, far away
- HOOK: "Away tonight? Your voice can still read the story."
- SCENE: a child in bed listening to a glowing phone, and somewhere far, a
  parent in a hotel room at night; two warm lights, one story.
- SUPPORT: "Record your Personal Voice once, on your phone. Fable reads
  tonight's story with it. Nothing is ever uploaded."

## 7. Airplane mode (the traveler)
- HOOK: "Somewhere over the Atlantic, at bedtime, with no Wi-Fi: a brand-new
  story."
- SCENE: an airplane cabin at night, a parent and child sharing one glowing
  phone under a blanket, stars out the window.
- SUPPORT: "The stories are written ON the phone by on-device AI. No
  connection needed, ever."

## 8. The chapter ritual
- HOOK: "'What happens next?' Finally a bedtime question you'll love."
- SCENE: a child leaning forward eagerly at a page turn, warm reading
  light, the room already half-asleep around them.
- SUPPORT: "Fable continues last night's adventure, night after night, and
  remembers what happened before."

## Compositing spec
- Scene: full-bleed, generated per angle via Route A (Nano Banana/Gemini,
  tools/adfactory/scenegen-gemini.py, key in ~/Documents/Keys/gemini.txt —
  owner provisions). Route B (on-device ImageCreator) was tried 2026-07-30
  and is dead on this host: creationFailed from any CLI context, even for
  people-free scenes; tools/adfactory/Sources/scenegen kept for Macs where
  it works.
- Scrim: violet-to-transparent gradient top and bottom for text legibility.
- Type: hook headline top (rounded bold, one highlighted word), support
  small above footer, "🌙 Fable Bedtime · On the App Store" lockup.
- Product UI: none, or one small floating story-card/cover inset. The
  scene sells the feeling; the store page sells the product.

## Measurement (unchanged)
- Stage 1: CTR/CPC per angle, broad English US-led, no attribution needed.
- Stage 2: winner per-country + ASC lift. Scaling gate: cost-per-trial ×
  trial→paid vs ~$34 net yearly. Kill-and-double weekly.
