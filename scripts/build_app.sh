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

# Generate simple AppIcon if not present
if [ ! -f "$RESOURCES_DIR/AppIcon.icns" ]; then
    echo "==> Creating default application icon..."
    ICONSET_DIR="/tmp/MacWallspace.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    
    # Generate 512x512 base PNG using python/coregraphics or a simple colored canvas
    python3 -c "
from PIL import Image, ImageDraw
import os

img = Image.new('RGBA', (512, 512), color=(0, 0, 0, 0))
draw = ImageDraw.Draw(img)
# Draw rounded squircle
draw.rounded_rectangle([32, 32, 480, 480], radius=100, fill=(20, 24, 33, 255))
# Draw subtle inner gradient/mountain shape
draw.polygon([(80, 380), (220, 200), (320, 310), (430, 170), (430, 380)], fill=(0, 122, 255, 220))
draw.ellipse([340, 100, 410, 170], fill=(255, 149, 0, 240))
img.save('/tmp/base_icon.png')
" 2>/dev/null || {
        # Fallback if Pillow is not installed: create solid color canvas using sips
        echo "Creating icon without PIL..."
    }
    
    if [ -f "/tmp/base_icon.png" ]; then
        sips -z 16 16     /tmp/base_icon.png --out "$ICONSET_DIR/icon_16x16.png" >/dev/null 2>&1 || true
        sips -z 32 32     /tmp/base_icon.png --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null 2>&1 || true
        sips -z 32 32     /tmp/base_icon.png --out "$ICONSET_DIR/icon_32x32.png" >/dev/null 2>&1 || true
        sips -z 64 64     /tmp/base_icon.png --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null 2>&1 || true
        sips -z 128 128   /tmp/base_icon.png --out "$ICONSET_DIR/icon_128x128.png" >/dev/null 2>&1 || true
        sips -z 256 256   /tmp/base_icon.png --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null 2>&1 || true
        sips -z 256 256   /tmp/base_icon.png --out "$ICONSET_DIR/icon_256x256.png" >/dev/null 2>&1 || true
        sips -z 512 512   /tmp/base_icon.png --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null 2>&1 || true
        sips -z 512 512   /tmp/base_icon.png --out "$ICONSET_DIR/icon_512x512.png" >/dev/null 2>&1 || true
        iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || true
        rm -rf "$ICONSET_DIR" /tmp/base_icon.png
    fi
fi

echo "==> Signing application bundle (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "✓ Successfully built: $APP_BUNDLE"
