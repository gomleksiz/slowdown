import Foundation

// MARK: - Session Models

struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let audioSource: AudioSource
    var wpmDataPoints: [WPMDataPoint]

    init(id: UUID = UUID(), startTime: Date = Date(), audioSource: AudioSource) {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
        self.audioSource = audioSource
        self.wpmDataPoints = []
    }

    var duration: TimeInterval {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return end.timeIntervalSince(startTime)
    }

    var averageWPM: Int {
        guard !wpmDataPoints.isEmpty else { return 0 }
        let sum = wpmDataPoints.reduce(0) { $0 + $1.wpm }
        return sum / wpmDataPoints.count
    }

    var maxWPM: Int {
        wpmDataPoints.map { $0.wpm }.max() ?? 0
    }

    var minWPM: Int {
        wpmDataPoints.map { $0.wpm }.min() ?? 0
    }

    var isActive: Bool {
        endTime == nil
    }
}

struct WPMDataPoint: Identifiable, Codable, Hashable {
    let id: UUID
    let wpm: Int
    let timestamp: Date

    init(id: UUID = UUID(), wpm: Int, timestamp: Date) {
        self.id = id
        self.wpm = wpm
        self.timestamp = timestamp
    }
}

// MARK: - AudioSource Codable Conformance

extension AudioSource: Codable {}
