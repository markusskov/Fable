# First-day smoke checklist (release day, either verdict)

## If APPROVED (owner presses Release manually)

1. Before pressing Release: confirm the approved build number is 5, and
   that German description in ASC is the re-pasted price-free version
   (OWNER-ASKS a2).
2. Press Release. App availability propagates over a few hours; do not
   panic at 404s in the first hour.
3. Fresh-install smoke test on a real device from the App Store build
   (not TestFlight): create profile, first story in under 60 seconds,
   tell one story per engine path if possible (model on, then airplane
   mode for curated), paywall renders with live prices, restore purchases
   works, privacy and terms links open.
4. Verify the store listing renders: screenshots, description, in-app
   purchases visible, all three live localizations (en, de, nb).
5. Buy the monthly subscription for real with a personal Apple ID
   (smallest tier), confirm entitlement arrives, then cancel. Keep the
   receipt for the books.
6. Start the v1.1 release train when ready: version bump via
   scripts/release.sh, upload, submit with the remaining localized
   listings (metadata-es/fr/it/pt-BR) and the 13" iPad screenshot set.
7. Only after v1.1 is live: press kit page, blog posts, Show HN, Apple
   featuring nomination, Norway push (docs/launch/).

## If REJECTED

1. Read the rejection reasons calmly; most likely candidates and their
   prepared answers live in OWNER-ASKS item 0 (guideline 2.3.2 screenshot
   marking, subscription metadata). Both are metadata-only fixes.
2. Metadata-only rejection: fix the listing per the reviewer note,
   resubmit the same build, no new binary needed.
3. Binary rejection: open a session with the rejection text; the roadmap
   gets a fix item, a build 6 goes out through the normal train.
4. Respond in Resolution Center within a day, factually, no argument
   unless the rejection misreads a fact (then cite the App Review note).
5. Launch material stays parked until approval; nothing in docs/launch/
   goes out on a rejected build.

## Either way

- Check ASC metrics the next morning: impressions, product page views,
  installs. Baseline numbers go in the roadmap for the ASO items.
- Watch support inbox; templates in docs/launch/support-responses.md.
