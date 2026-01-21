# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Slowdown is a macOS menu bar application that monitors speech pace in real-time and alerts users when they're speaking too fast. Designed for sales demos where maintaining an appropriate speaking pace improves audience comprehension.

## Build & Run Commands

### Using Swift Package Manager (development builds)

```bash
# Build
swift build

# Run (note: won't have microphone permissions without proper signing)
swift run Slowdown
```

### Using Xcode (recommended for full functionality)

Since this app requires microphone access, speech recognition, and system audio capture, you need an Xcode project with proper entitlements:

```bash
# Generate Xcode project from Package.swift
swift package generate-xcodeproj

# Open in Xcode
open Slowdown.xcodeproj
```

In Xcode:
1. Select the Slowdown target → Signing & Capabilities
2. Add your development team for code signing
3. Add capabilities: "Audio Input" (under Hardened Runtime if needed)
4. Cmd+R to build and run

### After Xcode project generation

Copy the entitlements and Info.plist into the Xcode project:
- `Slowdown/Resources/Slowdown.entitlements` → Add to project, set in Build Settings → Code Signing Entitlements
- `Slowdown/Resources/Info.plist` → Set in Build Settings → Info.plist File

## Architecture

### Core Components

**SlowdownApp.swift** - App entry point using SwiftUI App protocol with `NSApplicationDelegateAdaptor` for menu bar integration.

**MenuBarController.swift** - Manages `NSStatusItem` for menu bar presence. Handles dropdown menu with start/stop, audio source selection, and preferences.

**OverlayWindow.swift** - Floating `NSPanel` (always-on-top, non-activating) displaying current WPM with color-coded status (green/yellow/red based on threshold).

**AudioCaptureManager.swift** - Unified interface for audio capture:
- Microphone: Uses `AVAudioEngine` with `inputNode`
- System audio: Uses `ScreenCaptureKit` (`SCStreamConfiguration` with audio-only capture)
- Provides `AVAudioPCMBuffer` stream to speech recognizer

**SpeechRecognizer.swift** - Wraps `SFSpeechRecognizer` for real-time transcription:
- Creates `SFSpeechAudioBufferRecognitionRequest`
- Feeds audio buffers from AudioCaptureManager
- Emits transcribed segments with timestamps

**WPMCalculator.swift** - Calculates words-per-minute using sliding window:
- Maintains circular buffer of (word_count, timestamp) tuples
- Window size: 15 seconds (configurable)
- Updates on each transcription segment
- Publishes current WPM via Combine

**AlertManager.swift** - Triggers alerts when WPM exceeds threshold:
- Visual: Overlay flashes red, optional screen edge pulse
- Audio: Optional gentle chime (non-intrusive for demos)
- Haptic: If external trackpad supports it
- Cooldown period between alerts (default 10 seconds)

### Data Flow

```
Audio Input (Mic/System)
    ↓
AudioCaptureManager (AVAudioPCMBuffer stream)
    ↓
SpeechRecognizer (real-time transcription)
    ↓
WPMCalculator (sliding window calculation)
    ↓
OverlayWindow (visual display) + AlertManager (threshold alerts)
```

### Key Frameworks

- **AVFoundation**: Microphone audio capture via AVAudioEngine
- **ScreenCaptureKit**: System audio capture (macOS 12.3+)
- **Speech**: On-device speech recognition (SFSpeechRecognizer)
- **Combine**: Reactive data flow between components
- **SwiftUI + AppKit**: Menu bar and overlay window

### Required Entitlements

The app requires these entitlements in `Slowdown.entitlements`:
- `com.apple.security.device.audio-input` - Microphone access
- `com.apple.security.app-sandbox` - App sandbox (if distributing)

And Info.plist keys:
- `NSMicrophoneUsageDescription` - Microphone permission prompt
- `NSSpeechRecognitionUsageDescription` - Speech recognition permission

### Configuration

Default threshold: 160 WPM
Stored in UserDefaults with keys:
- `wpmThreshold` (Int)
- `audioSource` (String: "microphone" | "system")
- `alertSoundEnabled` (Bool)
- `slidingWindowSeconds` (Int)

## Design Decisions

- **On-device speech recognition**: Uses Apple's Speech framework for privacy - no audio leaves the device
- **Floating overlay**: Uses NSPanel with `.nonactivatingPanel` style so it doesn't steal focus during demos
- **Sliding window WPM**: 15-second window provides stable readings without too much lag
- **Menu bar app**: No dock icon (`LSUIElement = true` in Info.plist) to minimize distraction
