# Ad prompt pack — paste-ready for ChatGPT image generation

One complete prompt per angle. Workflow: open ChatGPT, ATTACH the two
reference files listed below, paste the prompt, generate at 4:5 first
(feed), then ask for the same composition at 1:1 and 9:16. The owner is
the render seat today; an OpenAI API key in ~/Documents/Keys/openai.txt
moves the seat to sessions (gpt-image-1) with these same prompts.

**Attach to every generation:**
- `App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png`
  (the REAL app icon — gold crescent over sleeping hills; the model must
  copy it exactly, not invent a book logo)
- One clean screenshot from `docs/appstore/screenshots/clean/en/` when the
  prompt calls for a visible phone screen (otherwise the screen is a soft
  warm glow, no readable fake UI)

**Corrections baked into every prompt (learned from the first draft):**
- iOS only: the official black "Download on the App Store" badge, NEVER a
  Google Play badge
- Logo lockup uses the attached real icon + the words "Fable Bedtime"
- No garbled UI: phone screens are either the attached screenshot or glow
- All in-image text must be exactly the copy given, spelled correctly
- No em dashes anywhere in rendered copy

**Shared style block (append to every prompt):**
"Warm storybook illustration style, cozy nighttime blues and deep violet
with pools of golden lamplight, soft edges, calm and tender mood.
Composition leaves clean space for the headline block. Render all text
crisply and exactly as written. Bottom left: the attached app icon at
small size next to the words 'Fable Bedtime' and beneath it the official
black Download on the App Store badge only."

---

## 1. Same-story fatigue
Headline (top left, large elegant serif): "Bedtime should be magical."
Subline (violet, smaller): "Not the same three books."
Scene: a tired but warm nighttime children's bedroom; on the nightstand a
worn stack of three children's books with visible titles "The Brave
Knight", "The Sleepy Princess", "Goodnight, Little Bear" and a small
handwritten note leaning on them reading "AGAIN? REALLY?"; a parent sits
on the bed edge holding a softly glowing phone (screen from attached
screenshot); a small child asleep under a pink blanket hugging a plush
rabbit. Optional small speech bubble from the child: "...and then the
dragon..." with tiny z's.

## 2. In the story (personalization)
Headline: "Tonight, the story is about HER."
Subline: "Her name. Her stuffed fox. Her adventure."
Scene: a delighted small child sitting up in bed, eyes wide, blanket to
the chin; beside the bed a parent reads from a warmly glowing phone; a
plush fox tucked beside the child; a faint dreamlike ribbon of tiny
golden stars curling from the phone toward the ceiling, hinting at a
story taking shape.

## 3. Asleep before the last page
Headline: "Asleep before the last page. Again."
Subline: "(That's the point.)"
Scene: a child deeply asleep mid-story, one arm over a plush toy; the
parent caught mid-tiptoe toward the door, looking back with a soft
triumphant smile; the phone on the nightstand still glowing faintly; the
room almost entirely at rest.

## 4. The privacy flip
Headline: "It knows your kid's name."
Subline: "And never tells anyone. No account. No ads. Data Not Collected."
Scene: a serene wide shot of a sleeping child's room at night; the phone
lies face down on the nightstand, done for the day; moonlight through
the window; a sense of total quiet and safety. Minimal, calm, almost
still-life.

## 5. The bedtime negotiation
Headline: "The bedtime negotiation ends tonight."
Subline: "You come armed with a story about THEM."
Scene: a warmly lit hallway at night; a small determined child in
pajamas, arms crossed, facing a tired but gently smiling parent who
holds up a softly glowing phone like a peace offering; the bedroom door
behind them spills golden light.

## 6. Your voice, far away
Headline: "Away tonight? Your voice still reads the story."
Subline: "Recorded once. Never uploaded."
Scene: split composition: left, a child snug in bed listening to a
glowing phone on the pillow; right, a parent in a dim hotel room by a
window with city lights, smiling at their own phone; the two halves
joined by one thin golden thread of light.

## 7. Airplane mode (the traveler)
Headline: "No Wi-Fi over the Atlantic. New story anyway."
Subline: "Written on the phone, by the phone."
Scene: a dim airplane cabin at night; a parent and small child under one
blanket sharing a warmly glowing phone (screen from attached
screenshot); stars and a wingtip out the oval window; other seats
asleep.

## 8. The chapter ritual
Headline: "'What happens next?'"
Subline: "Finally a bedtime question you'll love."
Scene: a child leaning eagerly toward a parent holding the glowing
phone, mid page-turn moment; the room warm and half-asleep; on the wall,
faint shadow shapes of last night's story (a little boat, a lantern)
like afterimages.

---

## QA checklist per output (session reviews every image)
- [ ] Icon matches the attached real icon
- [ ] App Store badge only, correctly drawn; no Google Play
- [ ] Every rendered word exactly as scripted, no typos, no em dashes
- [ ] Phone screens: attached screenshot or glow, never invented UI
- [ ] Claims in copy all true (cross-check ad-angles.md rules)
- [ ] Feels calm and warm at thumbnail size; headline readable at 300px
