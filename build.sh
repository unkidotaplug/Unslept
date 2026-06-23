#!/bin/bash
# Builds VibeAwake and packages it into a proper .app bundle.
set -e

APP_NAME="VibeAwake"
VERSION="1.0.0"
BUNDLE_ID="com.vibeawake.app"
MIN_OS="13.0"
DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DIR"
echo "→ swift build (release)..."
swift build -c release 2>&1

BINARY="$DIR/.build/release/$APP_NAME"

echo "→ Packaging .app bundle..."
APP_DIR="$DIR/build/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$CONTENTS/Resources"

cp "$BINARY" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# ── Info.plist ─────────────────────────────────────────────────────────────
cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_OS}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 VibeAwake</string>
</dict>
</plist>
PLIST

# ── Ad-hoc codesign (allows running locally without Gatekeeper block) ──────
codesign --deep --force --sign - "$APP_DIR" 2>/dev/null \
    && echo "→ Signed (ad-hoc)" \
    || echo "→ Signing skipped"

echo ""
echo "✓ Ready: $APP_DIR"
echo ""
echo "  Run now:        open \"$APP_DIR\""
echo "  Make DMG:       bash dist.sh"
