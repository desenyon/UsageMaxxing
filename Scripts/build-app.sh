#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT/VERSION" ]]; then
  VERSION="${VERSION:-$(sed -n '1p' "$ROOT/VERSION" | tr -d '[:space:]')}"
  BUILD_NUMBER="${BUILD_NUMBER:-$(sed -n '2p' "$ROOT/VERSION" | tr -d '[:space:]')}"
else
  VERSION="${VERSION:-1.1.0}"
  BUILD_NUMBER="${BUILD_NUMBER:-2}"
fi

APP_DIR="$ROOT/dist/UsageMaxxing.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
BUILD_CONFIG="${BUILD_CONFIG:-release}"

cd "$ROOT"
python3 "$ROOT/Scripts/generate_app_icon.py" >&2
swift build -c "$BUILD_CONFIG" --product UsageMaxxing >&2

BINARY_DIR="$ROOT/.build/$BUILD_CONFIG"
BINARY="$BINARY_DIR/UsageMaxxing"
BUNDLE="$BINARY_DIR/UsageMaxxing_UsageMaxxing.bundle"

if [[ ! -f "$BINARY" ]]; then
  echo "Missing binary at $BINARY" >&2
  exit 1
fi

if [[ ! -d "$BUNDLE" ]]; then
  echo "Missing resource bundle at $BUNDLE" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp "$BINARY" "$MACOS/UsageMaxxing"
cp -R "$BUNDLE" "$MACOS/"
cp "$ROOT/UsageMaxxing/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>UsageMaxxing</string>
  <key>CFBundleIdentifier</key>
  <string>local.usagemaxxing.app</string>
  <key>CFBundleName</key>
  <string>UsageMaxxing</string>
  <key>CFBundleDisplayName</key>
  <string>UsageMaxxing</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

echo "$APP_DIR"
