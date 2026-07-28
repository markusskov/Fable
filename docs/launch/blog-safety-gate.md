# Draft: "The safety gate: shipping model output to a three-year-old"

*Second dev-story post. More technical; pairs with the no-server post.*

---

Fable's on-device model writes bedtime stories for children. The hard
part is not generation. It is the promise that no model output reaches a
child unchecked, in seven languages, on a device we cannot observe.

The design assumes the model is untrusted and the parent's input is
hostile until proven boring. Four ideas carry the whole thing:

**1. One chokepoint in, one gate out.** Every request passes through a
single neutralization boundary (names and free-text fields validated,
confusables folded, zero-width characters stripped, template braces
removed), and every story, from every engine, passes the same acceptance
gate before display. The provider re-checks even engines that gate their
own output, because a postcondition that depends on someone else's
internals is not a postcondition.

**2. The gate is language-aware.** A denylist that flags the German word
"die" as English death, or misses that a Norwegian story ended in an
English "goodnight", is worse than none. Each language carries its own
denied vocabulary, its own sleep-signal words for the mandatory wind-down
ending, and its own false-friend exemptions. Matching happens after NFKC
normalization, so homoglyph tricks do not slip past.

**3. Prompts fence data from instructions.** Everything a parent typed,
and every recap the model itself wrote on an earlier night, sits inside a
delimited data block with the fence characters stripped from the values.
The instructions above the fence never contain a parent's words. This
sits under the OS provider's own safety layer, not instead of it.

**4. Failure falls to a calmer floor.** Model refused, gate refused,
model unavailable: the hand-written shelf answers. Shelf broken: an
emergency story from neutralized values. That broken too: one constant
story proven safe by exhaustive test. A child sees exactly one story and
zero errors, every night.

None of this is exotic. It is layered defense applied to a consumer AI
product, with the unusual constraint that the runtime is a phone in
airplane mode and the user is asleep before the second page. We test it
with seeded sweeps: thousands of rendered stories per language through
the full gate, plus live-model harnesses that lint real generations for
artifacts the gate does not judge.

*(Example rejection histogram + link to the no-server post.)*
