import AppKit
import AVFoundation
import Combine

class AlertManager {
    private var wpmCalculator: WPMCalculator
    private var cancellables = Set<AnyCancellable>()
    private var lastAlertTime: Date?
    private let cooldownSeconds: TimeInterval = 10

    private var alertSoundEnabled: Bool {
        UserDefaults.standard.bool(forKey: "alertSoundEnabled")
    }

    init(wpmCalculator: WPMCalculator) {
        self.wpmCalculator = wpmCalculator
        bindToCalculator()
    }

    private func bindToCalculator() {
        wpmCalculator.$status
            .sink { [weak self] status in
                if status == .tooFast {
                    self?.triggerAlert()
                }
            }
            .store(in: &cancellables)
    }

    private func triggerAlert() {
        // Check cooldown
        if let lastAlert = lastAlertTime,
           Date().timeIntervalSince(lastAlert) < cooldownSeconds {
            return
        }

        lastAlertTime = Date()

        // Play alert sound if enabled
        if alertSoundEnabled {
            playAlertSound()
        }
    }

    private func playAlertSound() {
        // Use a subtle system sound
        NSSound(named: "Tink")?.play()
    }
}
