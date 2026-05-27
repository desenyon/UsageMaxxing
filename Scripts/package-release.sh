#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/VERSION" ]]; then
  VERSION="${VERSION:-$(sed -n '1p' "$ROOT/VERSION" | tr -d '[:space:]')}"
else
  VERSION="${VERSION:-1.1.0}"
fi
DIST="$ROOT/dist"
APP="$DIST/UsageMaxxing.app"
ARCHIVE="$DIST/UsageMaxxing-${VERSION}-macos-arm64.zip"

cd "$ROOT"
VERSION="$VERSION" BUILD_CONFIG=release Scripts/build-app.sh >/dev/null

rm -f "$ARCHIVE"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
echo "$ARCHIVE"
