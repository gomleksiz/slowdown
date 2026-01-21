import AppKit
import SwiftUI
import Combine
import CoreAudio

class MenuBarController {
    private var statusItem: NSStatusItem?
    private var isMonitoring = false
    private var currentSource: AudioSource = .microphone
    private var settingsWindow: NSWindow?
    private var selectedDeviceUID: String?

    private let onStart: () -> Void
    private let onStop: () -> Void
    private let onSourceChange: (AudioSource) -> Void
    private let onToggleOverlay: () -> Void
    private let onDeviceChange: (String?) -> Void
    private let onOpenHistory: () -> Void

    init(
        onStart: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onSourceChange: @escaping (AudioSource) -> Void,
        onToggleOverlay: @escaping () -> Void,
        onDeviceChange: @escaping (String?) -> Void = { _ in },
        onOpenHistory: @escaping () -> Void = {}
    ) {
        self.onStart = onStart
        self.onStop = onStop
        self.onSourceChange = onSourceChange
        self.onToggleOverlay = onToggleOverlay
        self.onDeviceChange = onDeviceChange
        self.onOpenHistory = onOpenHistory

        // Get default device
        if let defaultDevice = AudioDeviceManager.shared.getDefaultInputDevice() {
            selectedDeviceUID = defaultDevice.uid
        }

        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Slowdown")
        }

        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Start/Stop
        let toggleItem = NSMenuItem(
            title: isMonitoring ? "Stop Monitoring" : "Start Monitoring",
            action: #selector(toggleMonitoring),
            keyEquivalent: "s"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Audio Source submenu
        let sourceMenu = NSMenu()
        let micItem = NSMenuItem(title: "Microphone", action: #selector(selectMicrophone), keyEquivalent: "")
        micItem.target = self
        micItem.state = currentSource == .microphone ? .on : .off
        sourceMenu.addItem(micItem)

        let systemItem = NSMenuItem(title: "System Audio", action: #selector(selectSystemAudio), keyEquivalent: "")
        systemItem.target = self
        systemItem.state = currentSource == .systemAudio ? .on : .off
        sourceMenu.addItem(systemItem)

        let sourceMenuItem = NSMenuItem(title: "Audio Source", action: nil, keyEquivalent: "")
        sourceMenuItem.submenu = sourceMenu
        menu.addItem(sourceMenuItem)

        // Microphone Device submenu
        let deviceMenu = NSMenu()
        let devices = AudioDeviceManager.shared.getInputDevices()

        if devices.isEmpty {
            let noDeviceItem = NSMenuItem(title: "No devices found", action: nil, keyEquivalent: "")
            noDeviceItem.isEnabled = false
            deviceMenu.addItem(noDeviceItem)
        } else {
            for device in devices {
                let deviceItem = NSMenuItem(title: device.name, action: #selector(selectDevice(_:)), keyEquivalent: "")
                deviceItem.target = self
                deviceItem.representedObject = device.uid
                deviceItem.state = device.uid == selectedDeviceUID ? .on : .off
                deviceMenu.addItem(deviceItem)
            }
        }

        let deviceMenuItem = NSMenuItem(title: "Microphone Device", action: nil, keyEquivalent: "")
        deviceMenuItem.submenu = deviceMenu
        menu.addItem(deviceMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Toggle overlay
        let overlayItem = NSMenuItem(title: "Toggle Overlay", action: #selector(toggleOverlay), keyEquivalent: "o")
        overlayItem.target = self
        menu.addItem(overlayItem)

        menu.addItem(NSMenuItem.separator())

        // History
        let historyItem = NSMenuItem(title: "Session History...", action: #selector(openHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Slowdown", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        return menu
    }

    @objc private func toggleMonitoring() {
        isMonitoring.toggle()
        if isMonitoring {
            onStart()
            statusItem?.button?.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Slowdown - Active")
        } else {
            onStop()
            statusItem?.button?.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Slowdown")
        }
        statusItem?.menu = buildMenu()
    }

    @objc private func selectMicrophone() {
        currentSource = .microphone
        onSourceChange(.microphone)
        statusItem?.menu = buildMenu()
    }

    @objc private func selectSystemAudio() {
        currentSource = .systemAudio
        onSourceChange(.systemAudio)
        statusItem?.menu = buildMenu()
    }

    @objc private func selectDevice(_ sender: NSMenuItem) {
        guard let uid = sender.representedObject as? String else { return }
        selectedDeviceUID = uid
        onDeviceChange(uid)
        print("🎤 Selected microphone: \(sender.title)")
        statusItem?.menu = buildMenu()
    }

    @objc private func toggleOverlay() {
        onToggleOverlay()
    }

    @objc private func openHistory() {
        onOpenHistory()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Slowdown Settings"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 400, height: 300))
            window.center()

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateWPMDisplay(_ wpm: Int) {
        // Could update menu bar title to show current WPM
        // statusItem?.button?.title = "\(wpm)"
    }
}
