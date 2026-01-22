#!/bin/bash

# Fix permissions for Slowdown.app
# Run this if speech recognition is not working

APP="/Applications/Slowdown.app"

if [ ! -d "$APP" ]; then
    echo "❌ Slowdown.app not found in /Applications"
    echo ""
    echo "Please install Slowdown first by dragging it from the DMG to Applications."
    exit 1
fi

echo "🔧 Fixing permissions for Slowdown..."
echo ""

# Remove quarantine attribute
echo "1. Removing quarantine flag..."
sudo xattr -dr com.apple.quarantine "$APP"

# Re-sign the app
echo "2. Re-signing app..."
sudo codesign --force --deep --sign - "$APP"

echo ""
echo "✅ Done! Try launching Slowdown again."
echo ""
echo "If speech recognition still doesn't work:"
echo "  - Go to System Settings > Privacy & Security > Microphone"
echo "  - Make sure Slowdown is allowed"
echo "  - Go to System Settings > Privacy & Security > Speech Recognition"
echo "  - Make sure Slowdown is allowed"
