#!/bin/zsh
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <version> <notes-file>" >&2
  exit 1
fi

VERSION="$1"
NOTES_FILE="$2"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release-artifacts/$VERSION"

if [[ ! -f "$NOTES_FILE" ]]; then
  echo "notes file not found: $NOTES_FILE" >&2
  exit 1
fi

"$ROOT_DIR/scripts/package_release.sh" "$VERSION"

gh release create "v$VERSION" \
  "$RELEASE_DIR/Luminark-$VERSION-macos-arm64.zip" \
  "$RELEASE_DIR/Luminark-$VERSION-macos-x86_64.zip" \
  --repo goosefraba/luminark \
  --verify-tag \
  --title "Luminark v$VERSION" \
  --notes-file "$NOTES_FILE"
