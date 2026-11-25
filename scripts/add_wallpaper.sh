#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_to_video.mp4|mov|gif>"
    exit 1
fi

SOURCE_FILE="$1"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: File '$SOURCE_FILE' not found!"
    exit 1
fi

WALLPAPERS_DIR="$HOME/Library/Application Support/MacWallspace/Wallpapers"
THUMBNAILS_DIR="$HOME/Library/Application Support/MacWallspace/Thumbnails"
mkdir -p "$WALLPAPERS_DIR" "$THUMBNAILS_DIR"

FILENAME=$(basename "$SOURCE_FILE")
UUID_STR=$(uuidgen | tr '[:upper:]' '[:lower:]')
TARGET_NAME="${UUID_STR}_${FILENAME}"
TARGET_PATH="$WALLPAPERS_DIR/$TARGET_NAME"

echo "==> Importing '$FILENAME' to MaC Wallspace library..."
cp "$SOURCE_FILE" "$TARGET_PATH"

echo "✓ Added to: $TARGET_PATH"
echo "==> Launching MaC Wallspace to apply..."
open -a "Mac Wallspace" 2>/dev/null || open "dist/Mac Wallspace.app" 2>/dev/null || true
echo "✓ Done! Your wallpaper is now ready in MaC Wallspace."
