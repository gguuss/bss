#!/usr/bin/env bash
set -euo pipefail

echo "===================================================="
echo "  Building & Packaging Better Screen Shot (v1.0.0)  "
echo "===================================================="

APP_NAME="Better Screen Shot"
BUNDLE_ID="com.gguuss.BetterScreenShot"
VERSION="1.0.0"
BUILD_NUMBER="1"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 1. Compile in release configuration
echo "==> Compiling Swift package in release mode..."
swift build -c release

# 2. Re-create dist and app bundle directories
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. Copy binary
echo "==> Installing executable into app bundle..."
cp "$PROJECT_ROOT/.build/release/BetterScreenShot" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# 4. Copy Icon and assets
if [ -f "$PROJECT_ROOT/Assets/AppIcon.icns" ]; then
    echo "==> Installing AppIcon.icns..."
    cp "$PROJECT_ROOT/Assets/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# 5. Generate Info.plist
echo "==> Generating Info.plist..."
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Better Screen Shot needs screen recording permissions to capture windows and displays to your clipboard.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Gus Class. All rights reserved.</string>
</dict>
</plist>
EOF

# 6. Ad-Hoc Code Signing
echo "==> Signing application bundle (Ad-Hoc with hardened runtime)..."
codesign --force --deep --sign - --options runtime "$APP_BUNDLE"

# 7. Verification
echo "==> Verifying signature..."
codesign --verify --deep --strict "$APP_BUNDLE"
echo "Signature verification passed!"

# 8. Create ZIP archive for distribution
echo "==> Packaging zip archive..."
ZIP_NAME="BetterScreenShot-v$VERSION.zip"
ditto -c -k --keepParent "$APP_BUNDLE" "$DIST_DIR/$ZIP_NAME"

# 9. Create DMG Drag-to-Install disk image
echo "==> Packaging DMG drag-to-install disk image..."
DMG_NAME="BetterScreenShot-v$VERSION.dmg"
DMG_STAGING="$DIST_DIR/dmg_staging"

# Ensure DMG background exists
if [ ! -f "$PROJECT_ROOT/Assets/dmg_background.png" ]; then
    swift "$PROJECT_ROOT/scripts/generate_dmg_background.swift"
fi

rm -rf "$DMG_STAGING" "$DIST_DIR/$DMG_NAME"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"

if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "Better Screen Shot" \
        --volicon "$PROJECT_ROOT/Assets/AppIcon.icns" \
        --background "$PROJECT_ROOT/Assets/dmg_background.png" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 140 190 \
        --app-drop-link 460 190 \
        --hide-extension "$APP_NAME.app" \
        --format UDZO \
        --codesign - \
        --overwrite \
        "$DIST_DIR/$DMG_NAME" \
        "$DMG_STAGING" || true
else
    # Fallback to standard hdiutil if create-dmg is not available
    ln -s /Applications "$DMG_STAGING/Applications"
    hdiutil create -volname "Better Screen Shot" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DIST_DIR/$DMG_NAME"
    codesign --force --sign - "$DIST_DIR/$DMG_NAME" || true
fi

rm -rf "$DMG_STAGING"

echo "===================================================="
echo "Successfully built and signed:"
echo "  - App Bundle:   $APP_BUNDLE"
echo "  - DMG Installer: $DIST_DIR/$DMG_NAME"
echo "  - ZIP Archive:   $DIST_DIR/$ZIP_NAME"
echo "===================================================="
