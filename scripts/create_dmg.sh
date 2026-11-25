#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Mac Wallspace"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_NAME="Mac-Wallspace-v1.0.0.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
ZIP_NAME="Mac-Wallspace-v1.0.0-macOS.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found! Building app first..."
    "$ROOT_DIR/scripts/build_app.sh"
fi

echo "==> Creating release ZIP package..."
rm -f "$ZIP_PATH"
(cd "$DIST_DIR" && zip -r -y -q "$ZIP_NAME" "$APP_NAME.app")
echo "✓ Created ZIP: $ZIP_PATH"

echo "==> Creating release DMG image..."
rm -f "$DMG_PATH"
DMG_STAGING="/tmp/MacWallspace_DMG_Staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

rm -rf "$DMG_STAGING"
echo "✓ Created DMG: $DMG_PATH"
echo "==> All release artifacts ready in $DIST_DIR"
