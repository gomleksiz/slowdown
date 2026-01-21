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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize components
        wpmCalculator = WPMCalculator()
        audioLevelMonitor = AudioLevelMonitor()
        alertManager = AlertManager(wpmCalculator: wpmCalculator!)

        speechRecognizer = SpeechRecognizer { [weak self] wordCount, duration in
            self?.wpmCalculator?.addWords(count: wordCount, duration: duration, at: Date())
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
            onDeviceChange: { [weak self] uid in self?.changeDevice(uid) }
        )

        // Show overlay on launch
        overlayWindow?.show()
    }

    private func startMonitoring() {
        // Request speech recognition authorization first
        speechRecognizer?.requestAuthorization { [weak self] authorized in
            if authorized {
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
    }

    private func changeAudioSource(_ source: AudioSource) {
        let wasRunning = audioCaptureManager?.isCapturing ?? false
        if wasRunning {
            stopMonitoring()
        }
        audioCaptureManager?.setSource(source)
        if wasRunning {
            startMonitoring()
        }
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
