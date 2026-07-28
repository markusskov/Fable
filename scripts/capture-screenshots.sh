#!/usr/bin/env bash
# App Store / documentation screenshot lane.
#
# Fresh-installs the app, overrides the status bar to the marketing-clean
# 9:41 / full battery, drives the staged evening in
# App/UITests/ScreenshotTests.swift, and exports the numbered PNGs to
# docs/appstore/screenshots/<language>/.
#
# Runs once per supported language by default, so the set never disagrees
# with what a family in that language actually sees. The test finds every
# control by accessibility identifier, so no translated strings live in it.
#
# Usage:
#   scripts/capture-screenshots.sh                 # all languages
#   scripts/capture-screenshots.sh nb de           # just these
#   DEVICE="iPhone 17 Pro" scripts/capture-screenshots.sh en
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE_NAME="${DEVICE:-iPhone 17 Pro Max}"
BUNDLE_ID="com.markusskov.fable"

# iPad captures land in their own set so the iPhone sets are never
# overwritten: ASC wants both, per listing.
case "$DEVICE_NAME" in
  *iPad*) SET_PREFIX="ipad-13/" ;;
  *)      SET_PREFIX="" ;;
esac

# Language -> region, matching the app's supported set. Region only affects
# formatting (the dates on library rows), so each language gets its home market.
LANGUAGES=(en nb de es fr it pt-BR)
region_for() {
  case "$1" in
    en) echo US ;; nb) echo NO ;; de) echo DE ;; es) echo ES ;;
    fr) echo FR ;; it) echo IT ;; pt-BR) echo BR ;; *) echo US ;;
  esac
}

if [[ $# -gt 0 ]]; then
  LANGUAGES=("$@")
fi

UDID=$(xcrun simctl list devices available \
  | grep -F "$DEVICE_NAME (" | head -1 \
  | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
if [[ -z "$UDID" ]]; then
  echo "error: no available simulator named '$DEVICE_NAME'" >&2
  exit 1
fi
echo "Using $DEVICE_NAME ($UDID)"
echo "Languages: ${LANGUAGES[*]}"

xcodegen generate
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b

xcrun simctl status_bar "$UDID" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 --operatorName ""

for LANG_CODE in "${LANGUAGES[@]}"; do
  REGION_CODE="$(region_for "$LANG_CODE")"
  OUT_DIR="docs/appstore/screenshots/${SET_PREFIX}$LANG_CODE"
  echo ""
  echo "=== $LANG_CODE ($REGION_CODE) ==="

  # The staging test scripts the first run, so it needs a truly fresh install.
  xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true

  WORK_DIR=$(mktemp -d)
  RESULT_BUNDLE="$WORK_DIR/screenshots.xcresult"
  # Only the staged-evening lane: the target also holds IPadLayoutTests,
  # which would run first (alphabetically), create the profile, and rob
  # this test of the fresh install it scripts.
  xcodebuild -project Fable.xcodeproj -scheme FableScreenshots \
    -destination "id=$UDID" \
    -testLanguage "$LANG_CODE" -testRegion "$REGION_CODE" \
    -resultBundlePath "$RESULT_BUNDLE" \
    -only-testing:"FableScreenshots/ScreenshotTests" \
    test

  EXPORT_DIR="$WORK_DIR/attachments"
  xcrun xcresulttool export attachments --path "$RESULT_BUNDLE" --output-path "$EXPORT_DIR"

  rm -rf "$OUT_DIR"
  mkdir -p "$OUT_DIR"
  python3 - "$EXPORT_DIR" "$OUT_DIR" <<'PY'
import json, pathlib, re, shutil, sys

export_dir, out_dir = map(pathlib.Path, sys.argv[1:3])
manifest = json.loads((export_dir / "manifest.json").read_text())
copied = []
for test in manifest:
    for attachment in test.get("attachments", []):
        name = attachment.get("suggestedHumanReadableName") or attachment["exportedFileName"]
        # xcresulttool suffixes the attachment name with `_<index>_<UUID>`.
        stem = re.sub(r"_\d+_[0-9A-Fa-f-]{36}$", "", name.removesuffix(".png"))
        destination = out_dir / f"{stem}.png"
        shutil.copy(export_dir / attachment["exportedFileName"], destination)
        copied.append(destination.name)
if not copied:
    sys.exit("error: the result bundle contained no screenshot attachments")
for name in sorted(copied):
    print(f"  {name}")
print(f"{len(copied)} screenshots -> {out_dir}")
PY
  rm -rf "$WORK_DIR"
done

xcrun simctl status_bar "$UDID" clear
echo ""
echo "Done. Sets written under docs/appstore/screenshots/."
