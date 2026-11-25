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

echo "==> Building Custom Styled DMG..."
rm -f "$DMG_PATH"

STAGING_DIR="/tmp/MacWallspace_DMG_Staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
mkdir -p "$STAGING_DIR/.background"

# 1. Copy App & Applications Symlink
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# 2. Add Background Artwork
if [ -f "$ROOT_DIR/Resources/icon_assets/dmg_background.png" ]; then
    cp "$ROOT_DIR/Resources/icon_assets/dmg_background.png" "$STAGING_DIR/.background/background.png"
fi

# 3. Add 1-Click Gatekeeper Fixer & Launcher
cat << 'EOF' > "$STAGING_DIR/Fix Gatekeeper & Open.command"
#!/usr/bin/env bash
# MaC Wallspace - 1-Click Gatekeeper Unblocker & Launcher
clear
echo "=========================================================="
echo "  MaC Wallspace — Security Permission Setup"
echo "=========================================================="
echo ""

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="/Applications/Mac Wallspace.app"

if [ ! -d "$TARGET" ]; then
    TARGET="$DIR/Mac Wallspace.app"
fi

echo "==> Removing macOS download quarantine attribute..."
xattr -cr "$TARGET" 2>/dev/null || true
codesign --force --deep --sign - "$TARGET" 2>/dev/null || true

echo "✓ Gatekeeper check unblocked successfully!"
echo "==> Launching MaC Wallspace..."
open "$TARGET"

echo ""
echo "Done! You can close this terminal window."
exit 0
EOF
chmod +x "$STAGING_DIR/Fix Gatekeeper & Open.command"

# 4. Add Quick Help Instructions
cat << 'EOF' > "$STAGING_DIR/FIRST LAUNCH HELP.txt"
===========================================================
  MaC Wallspace — How to Open if Gatekeeper Warns You
===========================================================

Because MaC Wallspace is a community open-source project 
built for older Macs, macOS may show a warning:
"Apple cannot check it for malicious software"

HOW TO OPEN (Choose either method):

METHOD 1 (Recommended):
  1. Drag "Mac Wallspace" to "Applications".
  2. In Applications, Right-Click (or Control-Click) "Mac Wallspace".
  3. Select "Open" from the menu.
  4. Click "Open" in the prompt.
  * You only need to do this ONCE! After that, it opens with a normal double-click.

METHOD 2 (1-Click Fix):
  Double-click "Fix Gatekeeper & Open.command" right here in this DMG!
===========================================================
EOF

# 5. Create temporary writable DMG
TMP_DMG="/tmp/tmp_macwallspace.dmg"
rm -f "$TMP_DMG"

# Calculate size needed
DU_SIZE=$(du -sk "$STAGING_DIR" | cut -f1)
DMG_SIZE=$((DU_SIZE + 10240)) # Add 10MB buffer

hdiutil create \
    -size "${DMG_SIZE}k" \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -fs HFS+ \
    -format UDRW \
    "$TMP_DMG" >/dev/null

# 6. Mount temporary DMG and run AppleScript to position icons and background
ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG")
MOUNT_DIR=$(echo "$ATTACH_OUTPUT" | grep "/Volumes/" | sed -E 's/.*(\/Volumes\/.*)/\1/')

if [ -n "$MOUNT_DIR" ] && [ -d "$MOUNT_DIR" ]; then
    echo "==> Customizing DMG Finder layout at '$MOUNT_DIR'..."
    
    # Copy Volume Icon if present
    if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
        cp "$ROOT_DIR/Resources/AppIcon.icns" "$MOUNT_DIR/.VolumeIcon.icns" || true
        SetFile -a C "$MOUNT_DIR" 2>/dev/null || true
    fi
    
    VOL_NAME=$(basename "$MOUNT_DIR")
    
    osascript - << OSA_EOF 2>/dev/null || true
    tell application "Finder"
        tell disk "$VOL_NAME"
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set the bounds of container window to {200, 150, 860, 570}
            
            set theViewOptions to the icon view options of container window
            set icon size of theViewOptions to 110
            set text size of theViewOptions to 12
            set arrangement of theViewOptions to not arranged
            
            try
                set background picture of theViewOptions to file ".background:background.png"
            end try
            
            set position of item "$APP_NAME.app" of container window to {160, 195}
            set position of item "Applications" of container window to {500, 195}
            set position of item "Fix Gatekeeper & Open.command" of container window to {240, 310}
            set position of item "FIRST LAUNCH HELP.txt" of container window to {420, 310}
            
            update without registering applications
            delay 1
            close
        end tell
    end tell
OSA_EOF

    # Sync and unmount
    sync || true
    hdiutil detach "$MOUNT_DIR" -force >/dev/null 2>&1 || true
    sleep 1
    
    # 7. Convert to final compressed read-only DMG
    echo "==> Compressing final DMG image..."
    hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" >/dev/null
    rm -f "$TMP_DMG"
else
    echo "Fallback direct packaging..."
    hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null
fi

rm -rf "$STAGING_DIR"
echo "✓ Created Custom Styled DMG: $DMG_PATH"
