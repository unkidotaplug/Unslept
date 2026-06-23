#!/bin/bash
# Creates a distributable DMG from the built .app.
# Run build.sh first. The DMG includes:
#   • Unslept.app
#   • an /Applications symlink (drag-to-install)
#   • a Russian install/usage guide (covers the Gatekeeper bypass)
set -e

APP_NAME="Unslept"
DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$DIR/build/${APP_NAME}.app"
DMG_PATH="$DIR/build/${APP_NAME}.dmg"
STAGE="$DIR/build/dmg-stage"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Run build.sh first — .app not found."
    exit 1
fi

echo "→ Staging DMG contents..."
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp "$DIR/dist/INSTALL.txt" "$STAGE/Прочти меня — установка.txt"

echo "→ Creating DMG..."
rm -f "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH" 2>&1 | tail -1

rm -rf "$STAGE"

echo ""
echo "✓ DMG ready: $DMG_PATH"
echo "  → This is the file you send / upload for distribution."
