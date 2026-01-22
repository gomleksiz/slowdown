import SwiftUI

@main
struct SlowdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var overlayWindow: OverlayWindow?
    private var audioCaptureManager: AudioCaptureManager?
    private var speechRecognizer: SpeechRecognizer?
    private var wpmCalculator: WPMCalculator?
    private var alertManager: AlertManager?
    private var audioLevelMonitor: AudioLevelMonitor?
    private var sessionManager: SessionManager?
    private var historyWindow: NSWindow?
    private var currentAudioSource: AudioSource = .microphone

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize components
        sessionManager = SessionManager()
        wpmCalculator = WPMCalculator()
        audioLevelMonitor = AudioLevelMonitor()
        alertManager = AlertManager(wpmCalculator: wpmCalculator!)

        speechRecognizer = SpeechRecognizer { [weak self] wordCount, duration in
            let timestamp = Date()
            self?.wpmCalculator?.addWords(count: wordCount, duration: duration, at: timestamp)

            // Record WPM data point in session
            if let wpm = self?.wpmCalculator?.currentWPM {
                self?.sessionManager?.addWPMDataPoint(wpm: wpm, timestamp: timestamp)
            }
        }

        audioCaptureManager = AudioCaptureManager { [weak self] buffer in
            self?.audioLevelMonitor?.processBuffer(buffer)
            self?.speechRecognizer?.processAudioBuffer(buffer)
        }

        // Create overlay with callbacks
        overlayWindow = OverlayWindow(
            wpmCalculator: wpmCalculator!,
            audioLevelMonitor: audioLevelMonitor!,
            onStart: { [weak self] in self?.startMonitoring() },
            onStop: { [weak self] in self?.stopMonitoring() },
            onSourceChange: { [weak self] source in self?.changeAudioSource(source) },
            onDeviceChange: { [weak self] uid in self?.changeDevice(uid) }
        )

        menuBarController = MenuBarController(
            onStart: { [weak self] in self?.startMonitoring() },
            onStop: { [weak self] in self?.stopMonitoring() },
            onSourceChange: { [weak self] source in self?.changeAudioSource(source) },
            onToggleOverlay: { [weak self] in self?.overlayWindow?.toggle() },
            onDeviceChange: { [weak self] uid in self?.changeDevice(uid) },
            onOpenHistory: { [weak self] in self?.openHistory() }
        )

        // Show overlay on launch
        overlayWindow?.show()
    }

    private func startMonitoring() {
        // Request speech recognition authorization first
        speechRecognizer?.requestAuthorization { [weak self] authorized in
            if authorized {
                // Start a new session
                self?.sessionManager?.startSession(audioSource: self?.currentAudioSource ?? .microphone)

                self?.audioCaptureManager?.startCapture()
                self?.speechRecognizer?.startRecognition()
                self?.overlayWindow?.setMonitoring(true)
            } else {
                print("Speech recognition not authorized")
            }
        }
    }

    private func stopMonitoring() {
        audioCaptureManager?.stopCapture()
        speechRecognizer?.stopRecognition()
        wpmCalculator?.reset()
        audioLevelMonitor?.reset()
        overlayWindow?.setMonitoring(false)

        // End the current session
        sessionManager?.endSession()
    }

    private func changeAudioSource(_ source: AudioSource) {
        currentAudioSource = source
        let wasRunning = audioCaptureManager?.isCapturing ?? false
        if wasRunning {
            stopMonitoring()
        }
        audioCaptureManager?.setSource(source)
        if wasRunning {
            startMonitoring()
        }
    }

    private func openHistory() {
        if historyWindow == nil {
            let historyView = HistoryView(sessionManager: sessionManager!)
            let hostingController = NSHostingController(rootView: historyView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Session History"
            window.styleMask = [.titled, .closable, .resizable]
            window.setContentSize(NSSize(width: 1000, height: 700))
            window.minSize = NSSize(width: 900, height: 600)
            window.center()

            historyWindow = window
        }

        historyWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func changeDevice(_ uid: String?) {
        let wasRunning = audioCaptureManager?.isCapturing ?? false
        if wasRunning {
            stopMonitoring()
        }
        audioCaptureManager?.setDevice(uid: uid)
        if wasRunning {
            startMonitoring()
        }
    }
}
