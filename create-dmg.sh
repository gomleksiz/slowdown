#!/bin/bash

set -e

APP_NAME="Slowdown"
VERSION="1.2"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"
SOURCE_FOLDER="build"
APP_PATH="${SOURCE_FOLDER}/${APP_NAME}.app"

# Check if app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Error: ${APP_PATH} not found. Run ./build.sh first."
    exit 1
fi

echo "📦 Creating DMG for ${APP_NAME} v${VERSION}..."

# Remove old DMG if exists
rm -f "${DMG_NAME}"
rm -rf dmg-temp

# Create temporary DMG folder
mkdir -p dmg-temp

# Copy app to temp folder
echo "📋 Copying app..."
cp -R "${APP_PATH}" dmg-temp/

# Remove quarantine attributes that might cause issues
echo "🧹 Removing quarantine attributes..."
xattr -cr dmg-temp/Slowdown.app 2>/dev/null || true

# Create Applications folder symlink
echo "🔗 Creating Applications folder symlink..."
ln -s /Applications dmg-temp/Applications

# Create DMG
echo "💿 Creating DMG..."
hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder dmg-temp \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

# Clean up
rm -rf dmg-temp

echo "✅ DMG created: ${DMG_NAME}"
echo ""
echo "📊 DMG Size:"
ls -lh "${DMG_NAME}" | awk '{print $5}'
