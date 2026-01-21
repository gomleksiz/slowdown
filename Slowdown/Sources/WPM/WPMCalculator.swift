import Foundation
import Combine

class WPMCalculator: ObservableObject {
    @Published private(set) var currentWPM: Int = 0
    @Published private(set) var status: WPMStatus = .idle
    @Published private(set) var wpmHistory: [WPMDataPoint] = []

    struct WPMDataPoint: Identifiable {
        let id = UUID()
        let wpm: Int
        let timestamp: Date
    }

    // Store word counts with their chunk duration
    private var wordChunks: [(words: Int, duration: TimeInterval, timestamp: Date)] = []

    private let windowSeconds: Int = 60  // Fixed 60 second window
    private let historyLimit: Int = 30   // Keep last 30 data points for graph

    private var threshold: Int {
        UserDefaults.standard.integer(forKey: "wpmThreshold").nonZero ?? 160
    }

    enum WPMStatus {
        case idle
        case good      // Under threshold
        case warning   // At threshold
        case tooFast   // Over threshold
    }

    /// Add words from a chunk with known duration
    func addWords(count: Int, duration: TimeInterval = 10.0, at timestamp: Date = Date()) {
        wordChunks.append((words: count, duration: duration, timestamp: timestamp))
        pruneOldChunks()
        calculateWPM()

        // Add to history for graph
        let dataPoint = WPMDataPoint(wpm: currentWPM, timestamp: timestamp)
        wpmHistory.append(dataPoint)
        if wpmHistory.count > historyLimit {
            wpmHistory.removeFirst()
        }

        let totalWords = wordChunks.reduce(0) { $0 + $1.words }
        let totalDuration = wordChunks.reduce(0.0) { $0 + $1.duration }
        print("📊 WPM: \(currentWPM) | Words: \(totalWords) in \(Int(totalDuration))s | Chunks: \(wordChunks.count) | Status: \(status)")
    }

    func reset() {
        wordChunks.removeAll()
        wpmHistory.removeAll()
        currentWPM = 0
        status = .idle
    }

    private func pruneOldChunks() {
        let cutoff = Date().addingTimeInterval(-Double(windowSeconds))
        wordChunks.removeAll { $0.timestamp < cutoff }
    }

    private func calculateWPM() {
        guard !wordChunks.isEmpty else {
            currentWPM = 0
            status = .idle
            return
        }

        let totalWords = wordChunks.reduce(0) { $0 + $1.words }
        let totalDuration = wordChunks.reduce(0.0) { $0 + $1.duration }

        // Need at least 5 seconds of data
        guard totalDuration >= 5 else {
            status = .idle
            return
        }

        // Calculate WPM: (words / seconds) * 60
        let wpm = Int(Double(totalWords) / totalDuration * 60)
        currentWPM = wpm

        // Update status
        if wpm > threshold + 10 {
            status = .tooFast
        } else if wpm > threshold - 10 {
            status = .warning
        } else {
            status = .good
        }
    }
}

// Helper extension
private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}
