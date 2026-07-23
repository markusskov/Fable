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

# Two sets: ASC app records vary in which iPhone slot they present.
# 6.7" (1284x2778) is what the Fable Bedtime record accepts (verified
# 2026-07-23 via ASC's own error message); 6.9" (1320x2868) kept for
# when the slot upgrades after a build upload.
render() {
  local out_dir="$1" height="$2" width="$3"
  mkdir -p "$out_dir"
  local i=0
  for name in "1. Image" "2. Image" "3. Image" "4. Image" "5. Image" "Final Image"; do
    i=$((i + 1))
    local out="$out_dir/0$i-store.png"
    cp "$SRC/$name.png" "$out"
    sips --resampleHeight "$height" "$out" >/dev/null
    sips --cropToHeightWidth "$height" "$width" "$out" >/dev/null
    printf "%s -> %s (%s)\n" "$name" "$out" \
      "$(sips -g pixelWidth -g pixelHeight "$out" | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w"x"h}')"
  done
}

render "docs/appstore/store-ready/6.7" 2778 1284
render "docs/appstore/store-ready/6.9" 2868 1320
echo "Done. Upload the 6.7 set (1284x2778) to the record's iPhone slot in order."
