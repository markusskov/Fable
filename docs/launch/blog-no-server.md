# Draft: "An AI bedtime app with no server"

*Dev-story post for the site, timed with v1.1 and the Show HN. Owner voice,
first person. No em dashes in published copy.*

---

Fable writes my daughter a new bedtime story every night. Her name is in
it, her stuffed fox is in it, and it always ends with her falling asleep.
The part that surprises people is not the AI. It is that the app has no
server.

Not "we minimize data collection". No server. There is no account system,
no API endpoint, no analytics SDK, no crash reporter phoning home. The App
Store privacy label is one line: Data Not Collected. If you reinstall the
app, your library is gone, because we could not read it if we wanted to.
That is a real trade-off, and we tell families about it in the app instead
of hiding it.

How does a generative AI app work with no backend? Apple Intelligence
ships a language model inside the operating system. Fable hands it a
carefully fenced prompt (the child's name and the parent's words are data,
never instructions), receives a structured story back, and then treats
that story as untrusted input: every page passes a language-aware content
gate before a child ever sees it. Scary words, wrong-language endings,
missing wind-downs, stories that do not land in sleep: all rejected.

Rejected into what? That is the second architectural decision. Underneath
the model sits a shelf of hand-written, parameterized stories in seven
languages, deterministic under a seeded generator, edited to publishable
quality. If the model is unavailable, slow, or writes something the gate
refuses, the shelf answers instead, silently. Beneath the shelf sits an
emergency story built only from neutralized values, and beneath that a
single constant story that cannot fail. Four floors, and a child only
ever sees the top one that worked. There are no error states at bedtime,
because at 8pm with a tired three-year-old, an error dialog is a product
bug no matter how pretty it is.

Covers work the same way: Image Playground paints them on the device from
prompts the app fully controls, and if it cannot, the story keeps its
quiet emoji emblem. Narration is AVSpeechSynthesizer, and with Personal
Voice a parent can lend the app their own voice, which also never leaves
the phone.

The result is an AI product whose entire threat model fits in a sentence:
nothing goes in but the OS, and nothing comes out at all.

*(Closing line + link to the safety-gate post.)*
