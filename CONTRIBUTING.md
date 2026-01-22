# Contributing to Slowdown

Thank you for your interest in contributing to Slowdown! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Building the Project](#building-the-project)
- [Project Structure](#project-structure)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Getting Started

Slowdown is a macOS menu bar application that monitors speech pace in real-time. Before contributing, please:

1. Read the [README.md](README.md) to understand what the project does
2. Check existing [issues](https://github.com/gomleksiz/slowdown/issues) and [pull requests](https://github.com/gomleksiz/slowdown/pulls)
3. Open an issue to discuss major changes before starting work

## Development Setup

### Prerequisites

- **macOS 13 (Ventura) or later**
- **Xcode 14+** or **Swift 5.9+**
- **Git**

### Clone the Repository

```bash
git clone https://github.com/gomleksiz/slowdown.git
cd slowdown
```

### Install Development Tools (Optional)

If you want to create releases:

```bash
# Install GitHub CLI (for creating releases)
brew install gh
gh auth login
```

## Building the Project

### Quick Development Build

For quick testing without proper permissions:

```bash
swift build
swift run Slowdown
```

**Note:** This method won't have microphone permissions due to lack of code signing.

### Production Build

For a full build with app icon and proper structure:

```bash
# Build the app bundle
./build.sh

# Create distributable DMG
./create-dmg.sh
```

The app bundle will be created at `build/Slowdown.app` and the DMG at `Slowdown.dmg`.

### Development with Xcode (Recommended)

For full functionality with microphone access:

1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```

2. In Xcode:
   - Select the Slowdown scheme
   - Go to Signing & Capabilities
   - Add your Apple Developer team
   - Ensure these capabilities are enabled:
     - App Sandbox (if distributing)
     - Audio Input

3. Run the project (⌘R)

## Project Structure

```
slowdown/
├── Slowdown/
│   ├── Sources/
│   │   ├── App/              # Application entry point
│   │   │   ├── SlowdownApp.swift
│   │   │   └── SettingsView.swift
│   │   ├── Audio/            # Audio capture and processing
│   │   │   ├── AudioCaptureManager.swift
│   │   │   ├── AudioDeviceManager.swift
│   │   │   ├── AudioLevelMonitor.swift
│   │   │   └── AudioSource.swift
│   │   ├── Speech/           # Speech recognition
│   │   │   └── SpeechRecognizer.swift
│   │   ├── WPM/              # WPM calculation
│   │   │   └── WPMCalculator.swift
│   │   ├── Alerts/           # Alert management
│   │   │   └── AlertManager.swift
│   │   ├── MenuBar/          # Menu bar UI
│   │   │   └── MenuBarController.swift
│   │   ├── Overlay/          # Floating overlay window
│   │   │   └── OverlayWindow.swift
│   │   └── Session/          # Session tracking and history
│   │       ├── SessionModels.swift
│   │       ├── SessionManager.swift
│   │       └── HistoryView.swift
│   └── Resources/
│       ├── Info.plist
│       ├── Slowdown.entitlements
│       └── AppIcon.icns
├── docs/                     # Website files
├── build.sh                  # Build script
├── create-dmg.sh            # DMG creation script
├── Package.swift            # Swift package manifest
└── CLAUDE.md                # Architecture documentation
```

## Coding Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift's naming conventions (camelCase for variables/functions, PascalCase for types)
- Prefer explicit types for clarity in complex scenarios
- Use `// MARK: -` to organize code sections

### Code Organization

- Keep files focused on a single responsibility
- Place related components in appropriate directories
- Use extensions to organize conformances and related functionality

### Example Code Style

```swift
// MARK: - Session Management

class SessionManager: ObservableObject {
    @Published private(set) var currentSession: Session?

    func startSession(audioSource: AudioSource) {
        // Implementation
    }

    func endSession() {
        // Implementation
    }
}
```

### Comments

- Document public APIs with clear descriptions
- Explain "why" not "what" for complex logic
- Keep comments up-to-date with code changes

### Architecture Principles

- **Privacy First**: All speech recognition happens on-device
- **Performance**: Use Combine for reactive data flow
- **User Experience**: Non-intrusive overlay that doesn't steal focus
- **Data Persistence**: Use Codable for JSON serialization

## Testing

Currently, the project relies on manual testing:

1. **Audio Source Testing**
   - Test with microphone input
   - Test with system audio capture
   - Test device switching

2. **WPM Calculation**
   - Speak at different paces
   - Verify threshold alerts trigger correctly
   - Check graph visualization accuracy

3. **Session History**
   - Start/stop multiple sessions
   - Verify data persistence
   - Test filtering by audio source

4. **UI Testing**
   - Test overlay visibility and positioning
   - Test menu bar interactions
   - Test settings changes

### Adding Tests (Future)

We welcome contributions that add automated testing:
- Unit tests for WPM calculation
- Unit tests for session management
- UI tests for critical flows

## Submitting Changes

### Pull Request Process

1. **Fork the repository** and create a branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding guidelines

3. **Test thoroughly** on macOS

4. **Commit your changes** with clear messages:
   ```bash
   git commit -m "Add feature: brief description

   More detailed explanation of what changed and why.

   Co-Authored-By: Your Name <your.email@example.com>"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request** on GitHub with:
   - Clear title describing the change
   - Description of what changed and why
   - Screenshots/videos for UI changes
   - Reference to related issues

### Commit Message Format

```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
- Use bullet points for multiple changes
- Reference issues: Fixes #123

Co-Authored-By: Your Name <your.email@example.com>
```

### What to Include

- **Feature additions**: New functionality with explanation
- **Bug fixes**: Description of the bug and how it's fixed
- **Documentation**: Improvements to README, comments, or guides
- **Refactoring**: Code improvements without behavior changes

### What to Avoid

- Unrelated changes in the same PR
- Breaking changes without discussion
- Formatting-only changes mixed with logic changes

## Release Process

### Version Numbers

We follow [Semantic Versioning](https://semver.org/):
- **Major (1.0.0)**: Breaking changes
- **Minor (1.1.0)**: New features, backwards compatible
- **Patch (1.0.1)**: Bug fixes, backwards compatible

### Creating a Release

Maintainers only:

1. **Update version** in `Slowdown/Resources/Info.plist`:
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.3</string>
   <key>CFBundleVersion</key>
   <string>4</string>
   ```

2. **Update website** in `docs/index.html`:
   - Version number
   - Release date
   - New features

3. **Build and create DMG**:
   ```bash
   ./build.sh
   ./create-dmg.sh
   ```

4. **Create GitHub release**:
   ```bash
   gh release create v1.3 Slowdown.dmg \
     --title "Slowdown v1.3" \
     --notes "Release notes here..."
   ```

5. **Push changes**:
   ```bash
   git add .
   git commit -m "Version 1.3: Release summary"
   git push
   ```

## Questions?

- **Bug reports**: [Open an issue](https://github.com/gomleksiz/slowdown/issues/new)
- **Feature requests**: [Open an issue](https://github.com/gomleksiz/slowdown/issues/new)
- **Questions**: [Start a discussion](https://github.com/gomleksiz/slowdown/discussions)

## License

By contributing to Slowdown, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to make Slowdown better! 🎉
