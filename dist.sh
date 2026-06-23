#!/bin/bash
# Creates a distributable DMG from the built .app.
# Run build.sh first.
set -e

APP_NAME="VibeAwake"
DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$DIR/build/${APP_NAME}.app"
DMG_PATH="$DIR/build/${APP_NAME}.dmg"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Run build.sh first — .app not found."
    exit 1
fi

rm -f "$DMG_PATH"

echo "→ Creating DMG..."
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH" 2>&1

echo ""
echo "✓ DMG ready: $DMG_PATH"
echo "  → Upload this file to your website for distribution."
