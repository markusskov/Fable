# Draft: Show HN post

*Submit with v1.1, same day as the blog posts go live. Title under 80
chars. Owner submits from their own account and answers comments; flag me
(a session) for drafting reply help if a thread gets deep.*

**Title:**
Show HN: I built an AI bedtime story app with no server (on-device only)

**Text:**
Fable writes my kid a new bedtime story every night: her name, her
stuffed fox, always ending in sleep. The architectural bet: no backend at
all. Apple's on-device model writes the prose, Image Playground paints
the cover, Personal Voice can read it in a parent's own voice, and the
privacy label is literally "Data Not Collected".

The interesting engineering is under the model: every output crosses a
language-aware safety gate (denylists, mandatory wind-down endings,
homoglyph normalization, prompt-injection fencing of parent input), and
failures fall silently through four layers: model, hand-written
parameterized story shelf in seven languages, emergency story, constant
floor. No error states at bedtime is a hard product requirement, so the
whole system is designed around graceful descent.

Blog posts on the no-server architecture and the safety gate: [links].
App Store: [link]. Happy to answer anything about shipping LLM output to
small children, the seven-language editorial grind, or why the free tier
is a real product and not a demo.

*(HN etiquette: no marketing tone, lead with engineering, disclose the
subscription model when asked, be candid about reinstall-loses-library.)*
