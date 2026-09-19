#!/usr/bin/env bash
# Builds spinCD.app — a self-contained macOS bundle with the curated collection's
# scans baked into Resources, so the app needs no server and no network.
#
#   ./scripts/build_app.sh            release build
#   ./scripts/build_app.sh debug      faster, for iterating
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
APP="$ROOT/dist/spinCD.app"
CONTENTS="$APP/Contents"

echo "==> Building spinCD ($CONFIG)"
cd "$ROOT"
swift build -c "$CONFIG" --arch arm64 --arch x86_64 2>/dev/null \
  || { echo "    universal build unavailable, building for this Mac only"; swift build -c "$CONFIG"; }

BIN="$(swift build -c "$CONFIG" --show-bin-path 2>/dev/null | tail -1)"

echo "==> Assembling bundle"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN/spinCD" "$CONTENTS/MacOS/spinCD"

# SwiftPM resource bundle (holds Seed.json); Bundle.module finds it in Resources.
cp -R "$BIN/spinCD_spinCD.bundle" "$CONTENTS/Resources/"

# Album scans, so every cover is available offline.
if [ -d "$REPO/scans/processed" ]; then
  mkdir -p "$CONTENTS/Resources/scans"
  rsync -a --delete "$REPO/scans/processed/" "$CONTENTS/Resources/scans/"
  echo "    bundled $(find "$CONTENTS/Resources/scans" -type f | wc -l | tr -d ' ') scan images"
else
  echo "    WARNING: $REPO/scans/processed not found; covers will be generated art"
fi

echo "==> Writing Info.plist"
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>spinCD</string>
  <key>CFBundleDisplayName</key><string>spinCD</string>
  <key>CFBundleExecutable</key><string>spinCD</string>
  <key>CFBundleIdentifier</key><string>dev.seanmichael.spinCD</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.music</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>spinCD · personal registry</string>
</dict>
</plist>
PLIST

ICON_SRC="$REPO/frontend/public/cdicon.png"
if [ -f "$ICON_SRC" ]; then
  echo "==> Building icon"
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$ICONSET"
  for size in 16 32 128 256 512; do
    sips -z $size $size "$ICON_SRC" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$ICON_SRC" \
      --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns"
fi

echo "==> Signing (ad-hoc)"
codesign --force --sign - --timestamp=none "$APP" >/dev/null 2>&1 \
  || echo "    ad-hoc signing failed; the app still runs locally"

echo
echo "Built $APP ($(du -sh "$APP" | cut -f1))"
echo "Run it with:  open '$APP'"
