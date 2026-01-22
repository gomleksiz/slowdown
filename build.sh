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

echo "✅ App bundle created at: ${APP_BUNDLE}"
echo ""
echo "ℹ️  Note: This app is not code-signed. Users will need to right-click and select 'Open' on first launch."
