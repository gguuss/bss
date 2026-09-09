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

echo "===================================================="
echo "Successfully built and signed: $APP_BUNDLE"
echo "Distribution archive: $DIST_DIR/$ZIP_NAME"
echo "===================================================="
