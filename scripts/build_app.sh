#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Mac Wallspace"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Building $APP_NAME for macOS..."

mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

SDK_PATH="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"

SWIFT_SOURCES=$(find "$ROOT_DIR/Sources/MacWallspace" -name "*.swift" -type f)

echo "==> Compiling Swift sources ($ARCH) using SDK $SDK_PATH..."

swiftc \
    -sdk "$SDK_PATH" \
    -target "${ARCH}-apple-macosx11.0" \
    -O \
    -framework Cocoa \
    -framework AVFoundation \
    -framework IOKit \
    -framework SwiftUI \
    -framework ServiceManagement \
    -framework UniformTypeIdentifiers \
    $SWIFT_SOURCES \
    -o "$MACOS_DIR/MacWallspace"

echo "==> Packaging Info.plist and resources..."
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy Black & White AppIcon
if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
    echo "==> Embedding Black & White AppIcon.icns..."
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "==> Signing application bundle (ad-hoc)..."
codesign --force --deep --timestamp=none --sign - "$APP_BUNDLE" 2>/dev/null || true

# Strip any residual quarantine attributes
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo "✓ Successfully built: $APP_BUNDLE"
