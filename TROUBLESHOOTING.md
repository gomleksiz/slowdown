# Troubleshooting Slowdown

## Speech Recognition Not Working

If speech recognition shows "Failed to access assets" errors, try these steps:

### Method 1: Remove Quarantine Attribute

When you download Slowdown from GitHub, macOS marks it as "quarantined" which can block certain features.

```bash
# If you copied Slowdown to Applications:
sudo xattr -dr com.apple.quarantine /Applications/Slowdown.app
sudo codesign --force --deep --sign - /Applications/Slowdown.app

# Or use the helper script:
./fix-permissions.sh
```

### Method 2: Grant Permissions Manually

1. Open **System Settings** > **Privacy & Security**
2. Go to **Microphone** - ensure Slowdown is checked
3. Go to **Speech Recognition** - ensure Slowdown is checked
4. Restart Slowdown

### Method 3: Build from Source

The most reliable method is to build from source:

```bash
# Build the app
./build.sh

# Test directly
open build/Slowdown.app
```

## "App is damaged or incomplete" Error

This error occurs when the app isn't code-signed properly.

**Solution:** Right-click (Control-click) on Slowdown.app and select "Open" instead of double-clicking.

You only need to do this once. After that, you can launch it normally.

## Microphone Not Working

1. Check that your microphone is connected and working
2. Grant microphone permission when prompted
3. Try selecting a different microphone device from the overlay dropdown

## System Audio Capture Not Working

System audio capture requires **Screen Recording** permission:

1. Go to **System Settings** > **Privacy & Security** > **Screen Recording**
2. Enable permission for Slowdown
3. Restart Slowdown

## Still Having Issues?

Open an issue on GitHub with:
- Your macOS version
- The error messages you see
- Steps to reproduce the problem

https://github.com/gomleksiz/slowdown/issues
