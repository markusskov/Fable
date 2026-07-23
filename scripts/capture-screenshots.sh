#!/usr/bin/env bash
# App Store screenshot lane.
#
# Fresh-installs the app on a 6.9" simulator, overrides the status bar to the
# marketing-clean 9:41 / full battery, drives the staged evening in
# App/UITests/ScreenshotTests.swift, and exports the numbered PNGs to
# docs/appstore/screenshots/6.9/. Rerun after any UI change that dates the set.
#
# Usage: scripts/capture-screenshots.sh ["iPhone 17 Pro Max"]
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE_NAME="${1:-iPhone 17 Pro Max}"
BUNDLE_ID="com.markusskov.fable"
OUT_DIR="docs/appstore/screenshots/6.9"

UDID=$(xcrun simctl list devices available \
  | grep -F "$DEVICE_NAME (" | head -1 \
  | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
if [[ -z "$UDID" ]]; then
  echo "error: no available simulator named '$DEVICE_NAME'" >&2
  exit 1
fi
echo "Using $DEVICE_NAME ($UDID)"

xcodegen generate
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b

xcrun simctl status_bar "$UDID" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 --operatorName ""
# The staging test scripts the first run, so it needs a truly fresh install.
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true

WORK_DIR=$(mktemp -d)
RESULT_BUNDLE="$WORK_DIR/screenshots.xcresult"
xcodebuild -project Fable.xcodeproj -scheme FableScreenshots \
  -destination "id=$UDID" \
  -resultBundlePath "$RESULT_BUNDLE" \
  test

EXPORT_DIR="$WORK_DIR/attachments"
xcrun xcresulttool export attachments --path "$RESULT_BUNDLE" --output-path "$EXPORT_DIR"

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

xcrun simctl status_bar "$UDID" clear
echo "Done. Review the set, then upload to App Store Connect (6.9\" slot)."
