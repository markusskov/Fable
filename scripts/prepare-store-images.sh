#!/bin/bash
# Converts the Figma 4x exports in docs/appstore/AppstoreImages/ (1560x3376)
# into App Store Connect 6.9" spec (1320x2868).
#
# Scale-to-fill height then center-crop width (loses ~2.5px of background
# bleed per side) — deliberately NOT pad-to-fit, which would paint background
# bands across phones that bleed off an edge.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="docs/appstore/AppstoreImages"
OUT="docs/appstore/store-ready"
mkdir -p "$OUT"

i=0
for name in "1. Image" "2. Image" "3. Image" "4. Image" "5. Image" "Final Image"; do
  i=$((i + 1))
  src="$SRC/$name.png"
  out="$OUT/0$i-store.png"
  cp "$src" "$out"
  sips --resampleHeight 2868 "$out" >/dev/null
  sips --cropToHeightWidth 2868 1320 "$out" >/dev/null
  printf "%s -> %s (%s)\n" "$name" "$out" \
    "$(sips -g pixelWidth -g pixelHeight "$out" | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w"x"h}')"
done
echo "Done. Upload $OUT/01..06 to the 6.9\" iPhone slot in order."
