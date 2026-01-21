import SwiftUI

struct HistoryView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var selectedSession: Session?
    @State private var sourceFilter: AudioSource? = nil

    private var filteredSessions: [Session] {
        sessionManager.sessionsFiltered(by: sourceFilter).sorted { $0.startTime > $1.startTime }
    }

    var body: some View {
        HSplitView {
            // Left side - Session List
            VStack(spacing: 0) {
                // Header with filter
                HStack {
                    Text("Sessions")
                        .font(.headline)
                        .padding(.leading)

                    Spacer()

                    // Filter picker
                    Picker("", selection: $sourceFilter) {
                        Text("All").tag(nil as AudioSource?)
                        Text("Microphone").tag(AudioSource.microphone as AudioSource?)
                        Text("System Audio").tag(AudioSource.systemAudio as AudioSource?)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Session list
                if filteredSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.text.clipboard")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No sessions yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Start monitoring to record sessions")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredSessions, selection: $selectedSession) { session in
                        SessionRowView(session: session)
                            .tag(session)
                    }
                }

                // Statistics footer
                if !sessionManager.sessions.isEmpty {
                    Divider()
                    HStack(spacing: 16) {
                        StatisticView(
                            title: "Total Sessions",
                            value: "\(sessionManager.totalSessions)"
                        )
                        StatisticView(
                            title: "Total Time",
                            value: formatDuration(sessionManager.totalSpeakingTime)
                        )
                        StatisticView(
                            title: "Avg WPM",
                            value: "\(sessionManager.overallAverageWPM)"
                        )
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color(nsColor: .controlBackgroundColor))
                }
            }
            .frame(minWidth: 350, idealWidth: 400)

            // Right side - Session Detail
            VStack {
                if let session = selectedSession {
                    SessionDetailView(session: session)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Select a session")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatDate(session.startTime))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)

                Spacer()

                // Source badge
                HStack(spacing: 4) {
                    Image(systemName: session.audioSource == .microphone ? "mic.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 10))
                    Text(session.audioSource == .microphone ? "Mic" : "System")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(sourceColor(session.audioSource).opacity(0.2))
                .foregroundColor(sourceColor(session.audioSource))
                .cornerRadius(4)
            }

            HStack(spacing: 16) {
                Label("\(formatDuration(session.duration))", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(session.averageWPM) wpm", systemImage: "waveform")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !session.wpmDataPoints.isEmpty {
                    Label("\(session.wpmDataPoints.count) points", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    private func sourceColor(_ source: AudioSource) -> Color {
        source == .microphone ? .blue : .purple
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: Session

    private var threshold: Int {
        UserDefaults.standard.integer(forKey: "wpmThreshold").nonZeroOrDefault(160)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(formatDate(session.startTime))
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        // Source badge
                        HStack(spacing: 6) {
                            Image(systemName: session.audioSource == .microphone ? "mic.fill" : "speaker.wave.2.fill")
                            Text(session.audioSource == .microphone ? "Microphone" : "System Audio")
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(sourceColor(session.audioSource).opacity(0.2))
                        .foregroundColor(sourceColor(session.audioSource))
                        .cornerRadius(8)
                    }

                    Text("Duration: \(formatDuration(session.duration))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // Statistics
                HStack(spacing: 16) {
                    StatCardView(
                        title: "Average",
                        value: "\(session.averageWPM)",
                        unit: "wpm",
                        color: wpmColor(session.averageWPM)
                    )

                    StatCardView(
                        title: "Maximum",
                        value: "\(session.maxWPM)",
                        unit: "wpm",
                        color: wpmColor(session.maxWPM)
                    )

                    StatCardView(
                        title: "Minimum",
                        value: "\(session.minWPM)",
                        unit: "wpm",
                        color: .secondary
                    )

                    StatCardView(
                        title: "Data Points",
                        value: "\(session.wpmDataPoints.count)",
                        unit: "points",
                        color: .secondary
                    )
                }

                // WPM Chart
                if !session.wpmDataPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WPM Over Time")
                            .font(.headline)
                            .padding(.horizontal)

                        SessionChartView(session: session, threshold: threshold)
                            .frame(height: 300)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    private func sourceColor(_ source: AudioSource) -> Color {
        source == .microphone ? .blue : .purple
    }

    private func wpmColor(_ wpm: Int) -> Color {
        if wpm > threshold + 10 {
            return .red
        } else if wpm > threshold - 10 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Session Chart View

struct SessionChartView: View {
    let session: Session
    let threshold: Int

    var body: some View {
        GeometryReader { geometry in
            let data = session.wpmDataPoints
            let maxWPM = max(data.map { $0.wpm }.max() ?? 200, threshold + 40)
            let minWPM = max(0, (data.map { $0.wpm }.min() ?? 0) - 20)

            ZStack {
                // Grid lines
                ForEach(0..<5) { index in
                    let wpm = minWPM + (maxWPM - minWPM) * index / 4
                    let y = geometry.size.height * CGFloat(4 - index) / 4

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)

                    Text("\(wpm)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .position(x: -20, y: y)
                }

                // Threshold line
                let thresholdY = yPosition(for: threshold, in: geometry.size.height, minWPM: minWPM, maxWPM: maxWPM)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: thresholdY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: thresholdY))
                }
                .stroke(Color.orange.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

                Text("Threshold: \(threshold)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
                    .cornerRadius(4)
                    .position(x: geometry.size.width - 60, y: thresholdY - 15)

                // WPM line
                if data.count > 1 {
                    Path { path in
                        for (index, point) in data.enumerated() {
                            let x = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                            let y = yPosition(for: point.wpm, in: geometry.size.height, minWPM: minWPM, maxWPM: maxWPM)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2.5)

                    // Data points
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                        let x = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = yPosition(for: point.wpm, in: geometry.size.height, minWPM: minWPM, maxWPM: maxWPM)

                        Circle()
                            .fill(pointColor(point.wpm))
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }

    private func yPosition(for wpm: Int, in height: CGFloat, minWPM: Int, maxWPM: Int) -> CGFloat {
        let range = CGFloat(maxWPM - minWPM)
        let normalizedValue = CGFloat(wpm - minWPM) / range
        return height * (1 - normalizedValue)
    }

    private func pointColor(_ wpm: Int) -> Color {
        if wpm > threshold + 10 {
            return .red
        } else if wpm > threshold - 10 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Helper Views

struct StatisticView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// Helper extension
private extension Int {
    func nonZeroOrDefault(_ defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}
