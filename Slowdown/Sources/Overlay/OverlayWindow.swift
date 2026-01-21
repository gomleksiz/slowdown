import AppKit
import SwiftUI
import Combine

class OverlayWindow {
    private var window: NSPanel?
    private var wpmCalculator: WPMCalculator
    private var audioLevelMonitor: AudioLevelMonitor
    private var overlayState: OverlayState
    private var cancellables = Set<AnyCancellable>()

    init(
        wpmCalculator: WPMCalculator,
        audioLevelMonitor: AudioLevelMonitor,
        onStart: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onSourceChange: @escaping (AudioSource) -> Void,
        onDeviceChange: @escaping (String?) -> Void
    ) {
        self.wpmCalculator = wpmCalculator
        self.audioLevelMonitor = audioLevelMonitor
        self.overlayState = OverlayState(
            onStart: onStart,
            onStop: onStop,
            onSourceChange: onSourceChange,
            onDeviceChange: onDeviceChange
        )
        setupWindow()
        bindToCalculator()
    }

    private func setupWindow() {
        let contentView = OverlayContentView(
            wpmCalculator: wpmCalculator,
            audioLevelMonitor: audioLevelMonitor,
            state: overlayState
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 195),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        panel.contentView = NSHostingView(rootView: contentView)

        // Position in bottom-right corner
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 240
            let y = screenFrame.minY + 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = panel
    }

    private func bindToCalculator() {
        wpmCalculator.$status
            .sink { [weak self] status in
                self?.updateAppearance(for: status)
            }
            .store(in: &cancellables)
    }

    private func updateAppearance(for status: WPMCalculator.WPMStatus) {
        if status == .tooFast {
            flashWindow()
        }
    }

    private func flashWindow() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            window?.animator().alphaValue = 0.5
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                self.window?.animator().alphaValue = 1.0
            })
        })
    }

    func show() {
        window?.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func setMonitoring(_ isMonitoring: Bool) {
        overlayState.isMonitoring = isMonitoring
    }
}

// MARK: - Overlay State

class OverlayState: ObservableObject {
    @Published var isMonitoring = false
    @Published var audioSource: AudioSource = .microphone
    @Published var selectedDeviceUID: String?
    @Published var availableDevices: [AudioDeviceManager.AudioDevice] = []

    let onStart: () -> Void
    let onStop: () -> Void
    let onSourceChange: (AudioSource) -> Void
    let onDeviceChange: (String?) -> Void
    let onOpenSettings: () -> Void

    private var settingsWindow: NSWindow?

    init(
        onStart: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onSourceChange: @escaping (AudioSource) -> Void,
        onDeviceChange: @escaping (String?) -> Void,
        onOpenSettings: @escaping () -> Void = {}
    ) {
        self.onStart = onStart
        self.onStop = onStop
        self.onSourceChange = onSourceChange
        self.onDeviceChange = onDeviceChange
        self.onOpenSettings = onOpenSettings

        refreshDevices()

        // Set default device
        if let defaultDevice = AudioDeviceManager.shared.getDefaultInputDevice() {
            selectedDeviceUID = defaultDevice.uid
        }
    }

    func openSettings() {
        DispatchQueue.main.async { [weak self] in
            if self?.settingsWindow == nil {
                let settingsView = SettingsView()
                let hostingController = NSHostingController(rootView: settingsView)

                let window = NSWindow(contentViewController: hostingController)
                window.title = "Slowdown Settings"
                window.styleMask = [.titled, .closable, .miniaturizable]
                window.setContentSize(NSSize(width: 400, height: 300))
                window.center()
                window.isReleasedWhenClosed = false

                self?.settingsWindow = window
            }

            self?.settingsWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func refreshDevices() {
        availableDevices = AudioDeviceManager.shared.getInputDevices()
    }

    func toggleMonitoring() {
        isMonitoring.toggle()
        if isMonitoring {
            onStart()
        } else {
            onStop()
        }
    }

    func setSource(_ source: AudioSource) {
        audioSource = source
        onSourceChange(source)
    }

    func setDevice(_ uid: String?) {
        selectedDeviceUID = uid
        onDeviceChange(uid)
    }
}

// MARK: - Overlay Content View

struct OverlayContentView: View {
    @ObservedObject var wpmCalculator: WPMCalculator
    @ObservedObject var audioLevelMonitor: AudioLevelMonitor
    @ObservedObject var state: OverlayState

    var body: some View {
        VStack(spacing: 10) {
            // WPM Display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(wpmCalculator.currentWPM)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Text("wpm")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Audio Level Indicator
            HStack(spacing: 4) {
                Image(systemName: audioLevelMonitor.isReceivingAudio ? "mic.fill" : "mic.slash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(audioLevelMonitor.isReceivingAudio ? .green : .gray)

                HStack(spacing: 2) {
                    ForEach(0..<12, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(barColor(for: index))
                            .frame(width: 8, height: 10)
                            .opacity(Float(index) / 12.0 < audioLevelMonitor.level ? 1.0 : 0.2)
                    }
                }
            }

            Divider()
                .padding(.horizontal, 8)

            // Controls Row 1
            HStack(spacing: 8) {
                // Start/Stop Button
                Button(action: { state.toggleMonitoring() }) {
                    Image(systemName: state.isMonitoring ? "stop.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(state.isMonitoring ? .red : .green)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                .buttonStyle(.plain)
                .help(state.isMonitoring ? "Stop" : "Start")

                // Source Picker
                Picker("", selection: Binding(
                    get: { state.audioSource },
                    set: { state.setSource($0) }
                )) {
                    Image(systemName: "mic.fill").tag(AudioSource.microphone)
                    Image(systemName: "speaker.wave.2.fill").tag(AudioSource.systemAudio)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)

                // Device Picker (only for microphone)
                if state.audioSource == .microphone && !state.availableDevices.isEmpty {
                    Menu {
                        ForEach(state.availableDevices) { device in
                            Button(action: { state.setDevice(device.uid) }) {
                                HStack {
                                    Text(device.name)
                                    if device.uid == state.selectedDeviceUID {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .frame(width: 24, height: 28)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                    .help("Select Microphone")
                }
            }

            // Controls Row 2 - Settings & Quit
            HStack(spacing: 12) {
                // Settings Button
                Button(action: { state.openSettings() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.system(size: 11))
                        Text("Settings")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .help("Open Settings")

                // Quit Button
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 11))
                        Text("Quit")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .help("Quit Slowdown")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(statusColor.opacity(0.6), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var statusColor: Color {
        switch wpmCalculator.status {
        case .idle:
            return .gray
        case .good:
            return .green
        case .warning:
            return .orange
        case .tooFast:
            return .red
        }
    }

    private func barColor(for index: Int) -> Color {
        if index < 7 {
            return .green
        } else if index < 10 {
            return .yellow
        } else {
            return .red
        }
    }
}
