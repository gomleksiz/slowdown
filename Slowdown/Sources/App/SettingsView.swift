import SwiftUI

struct SettingsView: View {
    @AppStorage("wpmThreshold") private var wpmThreshold = 160
    @AppStorage("alertSoundEnabled") private var alertSoundEnabled = true

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

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.1")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Speech Recognition")
                    Spacer()
                    Text("On-device only")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
    }
}
