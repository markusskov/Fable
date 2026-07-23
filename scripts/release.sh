#!/bin/bash
# Release automation for Fable.
#
#   scripts/release.sh [--dry-run] <major|minor|patch|X.Y.Z>
#       Bump MARKETING_VERSION (and CURRENT_PROJECT_VERSION by one) in
#       project.yml, prepend a changelog section generated from conventional
#       commits since the last v* tag, and commit the result as
#       "chore(release): vX.Y.Z (build N)". Run this on a release branch and
#       merge via PR like any other change.
#
#   scripts/release.sh [--dry-run] build
#       Bump only CURRENT_PROJECT_VERSION (for re-uploading the same marketing
#       version to TestFlight). No changelog entry.
#
#   scripts/release.sh tag
#       After the release commit has merged: create the annotated tag for the
#       version currently in project.yml. Pushing the tag triggers the Release
#       workflow, which publishes a GitHub Release with that version's notes.
set -euo pipefail

die() { echo "release.sh: $*" >&2; exit 1; }

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROJECT_YML="$ROOT/project.yml"
CHANGELOG="$ROOT/CHANGELOG.md"
INSERT_MARKER='<!-- insert: newest release below this line -->'

DRY_RUN=0
ACTION=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $arg" ;;
    *) [ -n "$ACTION" ] && die "one action only (got '$ACTION' and '$arg')"
       ACTION="$arg" ;;
  esac
done
[ -n "$ACTION" ] || die "usage: release.sh [--dry-run] <major|minor|patch|X.Y.Z|build|tag>"

# BSD sed (macOS) needs -i '', GNU sed needs bare -i.
sedi() {
  if sed --version >/dev/null 2>&1; then sed -i -E "$@"; else sed -i '' -E "$@"; fi
}

current_version() {
  sed -n 's/^ *MARKETING_VERSION: "\([0-9.]*\)"$/\1/p' "$PROJECT_YML" | head -1
}
current_build() {
  sed -n 's/^ *CURRENT_PROJECT_VERSION: \([0-9]*\)$/\1/p' "$PROJECT_YML" | head -1
}

VERSION=$(current_version)
BUILD=$(current_build)
[ -n "$VERSION" ] || die "MARKETING_VERSION not found in project.yml"
[ -n "$BUILD" ] || die "CURRENT_PROJECT_VERSION not found in project.yml"

if [ "$ACTION" = "tag" ]; then
  TAG="v$VERSION"
  git -C "$ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null \
    && die "$TAG already exists"
  grep -q "^## $TAG " "$CHANGELOG" \
    || die "no '## $TAG' section in CHANGELOG.md — run the bump first"
  [ -z "$(git -C "$ROOT" status --porcelain)" ] || die "working tree not clean"
  git -C "$ROOT" tag -a "$TAG" -m "Fable $VERSION (build $BUILD)"
  echo "Tagged $TAG at $(git -C "$ROOT" rev-parse --short HEAD)."
  echo "Push it to publish the GitHub Release:  git push origin $TAG"
  exit 0
fi

if [ "$DRY_RUN" -eq 0 ] && [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
  die "working tree not clean — commit or stash first"
fi

NEW_BUILD=$((BUILD + 1))

if [ "$ACTION" = "build" ]; then
  echo "Build bump: $BUILD -> $NEW_BUILD (version stays $VERSION)"
  [ "$DRY_RUN" -eq 1 ] && exit 0
  sedi "s/^( *CURRENT_PROJECT_VERSION:) [0-9]+$/\\1 $NEW_BUILD/" "$PROJECT_YML"
  git -C "$ROOT" add "$PROJECT_YML"
  git -C "$ROOT" commit -m "chore(release): build $NEW_BUILD"
  exit 0
fi

case "$ACTION" in
  major|minor|patch)
    IFS=. read -r MAJ MIN PAT <<EOF
$VERSION
EOF
    case "$ACTION" in
      major) NEW_VERSION="$((MAJ + 1)).0.0" ;;
      minor) NEW_VERSION="$MAJ.$((MIN + 1)).0" ;;
      patch) NEW_VERSION="$MAJ.$MIN.$((PAT + 1))" ;;
    esac ;;
  *)
    # Two- or three-part versions: CFBundleShortVersionString allows both,
    # and the App Store version string ("1.0") must match the binary exactly.
    echo "$ACTION" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$' \
      || die "not a bump keyword or X.Y[.Z] version: $ACTION"
    NEW_VERSION="$ACTION" ;;
esac

# --- Changelog from conventional commits since the last v* tag ---------------

LAST_TAG=$(git -C "$ROOT" describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)
if [ -n "$LAST_TAG" ]; then RANGE="$LAST_TAG..HEAD"; else RANGE="HEAD"; fi

FEATURES="" FIXES="" OTHER=""
while IFS= read -r subject; do
  case "$subject" in
    "chore(release):"*) continue ;;
  esac
  entry=$(echo "$subject" | sed -E 's/^[a-z]+(\([^)]*\))?!?: //')
  if echo "$subject" | grep -Eq '^[a-z]+(\([^)]*\))?!:'; then
    entry="**Breaking:** $entry"
  fi
  case "$subject" in
    feat*) FEATURES="$FEATURES- $entry"$'\n' ;;
    fix*)  FIXES="$FIXES- $entry"$'\n' ;;
    *)     OTHER="$OTHER- $entry"$'\n' ;;
  esac
done < <(git -C "$ROOT" log --no-merges --format='%s' "$RANGE")

# Empty is unusual (only chore(release) commits since the last tag) but must
# not fail: CI dry-runs this on every push, including right after a release.
[ -n "$FEATURES$FIXES$OTHER" ] \
  || echo "warning: no notable commits since ${LAST_TAG:-the beginning}" >&2

SECTION_FILE=$(mktemp)
trap 'rm -f "$SECTION_FILE"' EXIT
{
  echo
  echo "## v$NEW_VERSION (build $NEW_BUILD) — $(date +%Y-%m-%d)"
  [ -n "$FEATURES" ] && { echo; echo "### Features"; printf '%s' "$FEATURES"; }
  [ -n "$FIXES" ]    && { echo; echo "### Fixes";    printf '%s' "$FIXES"; }
  [ -n "$OTHER" ]    && { echo; echo "### Other";    printf '%s' "$OTHER"; }
  [ -z "$FEATURES$FIXES$OTHER" ] && { echo; echo "_No notable changes._"; }
  true
} > "$SECTION_FILE"

echo "Version bump: $VERSION -> $NEW_VERSION, build $BUILD -> $NEW_BUILD"
echo "Commits since ${LAST_TAG:-the first commit}:"
cat "$SECTION_FILE"

[ "$DRY_RUN" -eq 1 ] && exit 0

grep -qF "$INSERT_MARKER" "$CHANGELOG" \
  || die "insert marker missing from CHANGELOG.md"
TMP_CHANGELOG=$(mktemp)
awk -v sec="$SECTION_FILE" -v marker="$INSERT_MARKER" '
  { print }
  index($0, marker) { while ((getline line < sec) > 0) print line }
' "$CHANGELOG" > "$TMP_CHANGELOG"
mv "$TMP_CHANGELOG" "$CHANGELOG"

sedi "s/^( *MARKETING_VERSION:) \"[0-9.]+\"$/\\1 \"$NEW_VERSION\"/" "$PROJECT_YML"
sedi "s/^( *CURRENT_PROJECT_VERSION:) [0-9]+$/\\1 $NEW_BUILD/" "$PROJECT_YML"

git -C "$ROOT" add "$PROJECT_YML" "$CHANGELOG"
git -C "$ROOT" commit -m "chore(release): v$NEW_VERSION (build $NEW_BUILD)"
echo
echo "Committed. Next: push the branch, open a PR, merge, then on main run:"
echo "  scripts/release.sh tag && git push origin v$NEW_VERSION"
