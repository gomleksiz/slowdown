import Foundation
import Combine

class WPMCalculator: ObservableObject {
    @Published private(set) var currentWPM: Int = 0
    @Published private(set) var status: WPMStatus = .idle

    // Store word counts with their chunk duration
    private var wordChunks: [(words: Int, duration: TimeInterval, timestamp: Date)] = []

    private var windowSeconds: Int {
        UserDefaults.standard.integer(forKey: "slidingWindowSeconds").nonZero ?? 60
    }
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

        let totalWords = wordChunks.reduce(0) { $0 + $1.words }
        let totalDuration = wordChunks.reduce(0.0) { $0 + $1.duration }
        print("📊 WPM: \(currentWPM) | Words: \(totalWords) in \(Int(totalDuration))s | Chunks: \(wordChunks.count) | Status: \(status)")
    }

    /// Legacy method for compatibility
    func addWords(count: Int, at timestamp: Date) {
        addWords(count: count, duration: 10.0, at: timestamp)
    }

    func reset() {
        wordChunks.removeAll()
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
