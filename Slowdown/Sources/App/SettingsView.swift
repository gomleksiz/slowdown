import SwiftUI

struct SettingsView: View {
    @AppStorage("wpmThreshold") private var wpmThreshold = 160
    @AppStorage("alertSoundEnabled") private var alertSoundEnabled = true
    @AppStorage("slidingWindowSeconds") private var slidingWindowSeconds = 15

    var body: some View {
        Form {
            Section("Speech Pace") {
                Stepper("WPM Threshold: \(wpmThreshold)", value: $wpmThreshold, in: 100...250, step: 10)
                Text("You'll be alerted when speaking faster than \(wpmThreshold) words per minute")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Alerts") {
                Toggle("Play alert sound", isOn: $alertSoundEnabled)
            }

            Section("Calculation") {
                Picker("Averaging window", selection: $slidingWindowSeconds) {
                    Text("10 seconds").tag(10)
                    Text("15 seconds").tag(15)
                    Text("20 seconds").tag(20)
                    Text("30 seconds").tag(30)
                }
                Text("Longer windows give more stable readings but react slower to pace changes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }
}
