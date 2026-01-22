#!/bin/bash

set -e

echo "🔨 Building Slowdown v1.2..."

# Clean previous builds
rm -rf build
rm -rf .build/release
mkdir -p build

# Build the Swift package in release mode
echo "📦 Building Swift package..."
swift build -c release

# Create app bundle structure
APP_NAME="Slowdown"
APP_BUNDLE="build/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "📁 Creating app bundle structure..."
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# Copy executable
echo "📋 Copying executable..."
cp ".build/release/${APP_NAME}" "${MACOS}/"

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp "Slowdown/Resources/Info.plist" "${CONTENTS}/"

# Copy icon
echo "🎨 Copying app icon..."
cp "Slowdown/Resources/AppIcon.icns" "${RESOURCES}/"

# Copy entitlements (for reference)
cp "Slowdown/Resources/Slowdown.entitlements" "${RESOURCES}/"

# Set executable permissions
chmod +x "${MACOS}/${APP_NAME}"

# Ad-hoc code sign the app WITHOUT entitlements
# (entitlements only work with proper Apple Developer signing)
echo "🔐 Code signing app (ad-hoc, no entitlements)..."
codesign --force --deep --sign - "${APP_BUNDLE}" 2>&1 || {
    echo "⚠️  Code signing failed, but app should still work"
}

echo "✅ App bundle created at: ${APP_BUNDLE}"
echo ""
echo "ℹ️  Note: This app uses ad-hoc signing. Users will need to:"
echo "   1. Right-click the app and select 'Open' on first launch"
echo "   2. Grant microphone and speech recognition permissions when prompted"
