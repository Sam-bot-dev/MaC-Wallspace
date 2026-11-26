#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Mac Wallspace"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Building $APP_NAME as a Universal 2 (x86_64 + arm64) macOS application..."

mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

SDK_PATH="$(xcrun --show-sdk-path)"
BUILD_TEMP="/tmp/macwallspace_build_$$"
mkdir -p "$BUILD_TEMP"
trap 'rm -rf "$BUILD_TEMP"' EXIT

SWIFT_SOURCES=$(find "$ROOT_DIR/Sources/MacWallspace" -name "*.swift" -type f)

echo "==> [1/3] Compiling Swift sources for Intel (x86_64)..."
swiftc \
    -sdk "$SDK_PATH" \
    -target "x86_64-apple-macosx11.0" \
    -O \
    -framework Cocoa \
    -framework AVFoundation \
    -framework IOKit \
    -framework SwiftUI \
    -framework ServiceManagement \
    -framework UniformTypeIdentifiers \
    $SWIFT_SOURCES \
    -o "$BUILD_TEMP/MacWallspace_x86_64"

echo "==> [2/3] Compiling Swift sources for Apple Silicon (arm64)..."
swiftc \
    -sdk "$SDK_PATH" \
    -target "arm64-apple-macosx11.0" \
    -O \
    -framework Cocoa \
    -framework AVFoundation \
    -framework IOKit \
    -framework SwiftUI \
    -framework ServiceManagement \
    -framework UniformTypeIdentifiers \
    $SWIFT_SOURCES \
    -o "$BUILD_TEMP/MacWallspace_arm64"

echo "==> [3/3] Creating Universal 2 binary with lipo..."
lipo -create \
    -output "$MACOS_DIR/MacWallspace" \
    "$BUILD_TEMP/MacWallspace_x86_64" \
    "$BUILD_TEMP/MacWallspace_arm64"

echo "==> Packaging Info.plist and resources..."
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy Black & White AppIcon
if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
    echo "==> Embedding Black & White AppIcon.icns..."
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Copy preview thumbnails
if [ -d "$ROOT_DIR/docs/previews" ]; then
    echo "==> Embedding preview thumbnails..."
    mkdir -p "$RESOURCES_DIR/previews"
    cp -R "$ROOT_DIR/docs/previews/" "$RESOURCES_DIR/previews/"
fi

# Copy bundled anime wallpaper artwork
if [ -f "$ROOT_DIR/Resources/icon_assets/anime_wallpaper.jpg" ]; then
    echo "==> Embedding anime_wallpaper.jpg..."
    cp "$ROOT_DIR/Resources/icon_assets/anime_wallpaper.jpg" "$RESOURCES_DIR/anime_wallpaper.jpg"
fi

echo "==> Signing application bundle (ad-hoc)..."
codesign --force --deep --timestamp=none --sign - "$APP_BUNDLE" 2>/dev/null || true

# Strip any residual quarantine attributes
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo "✓ Successfully built Universal 2 application:"
file "$MACOS_DIR/MacWallspace"
