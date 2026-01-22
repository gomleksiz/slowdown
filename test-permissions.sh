#!/bin/bash

echo "Testing Slowdown.app permissions..."
echo ""

APP="build/Slowdown.app"

if [ ! -d "$APP" ]; then
    echo "❌ App not found at $APP"
    echo "Run ./build.sh first"
    exit 1
fi

echo "📋 Code signature:"
codesign -dv "$APP" 2>&1 | grep -E "Identifier|Signature|Authority"
echo ""

echo "📋 Extended attributes:"
xattr -l "$APP"
echo ""

echo "📋 Info.plist permissions:"
grep -A1 -E "Microphone|Speech" "$APP/Contents/Info.plist"
echo ""

echo "🧪 Removing quarantine attribute (if present)..."
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || echo "No quarantine attribute found"
echo ""

echo "✅ App should now work. Try launching it."
