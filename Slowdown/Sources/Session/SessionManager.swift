import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published private(set) var currentSession: Session?
    @Published private(set) var sessions: [Session] = []

    private let storageURL: URL
    private let maxSessionsToKeep = 100 // Keep last 100 sessions

    init() {
        // Setup storage location in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("Slowdown", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.storageURL = appFolder.appendingPathComponent("sessions.json")

        // Load existing sessions
        loadSessions()
    }

    // MARK: - Session Management

    func startSession(audioSource: AudioSource) {
        // End any existing session first
        if currentSession != nil {
            endSession()
        }

        currentSession = Session(startTime: Date(), audioSource: audioSource)
        print("📝 Started new session: \(currentSession!.id) with source: \(audioSource.rawValue)")
    }

    func endSession() {
        guard var session = currentSession else { return }

        session.endTime = Date()
        currentSession = nil

        // Only save sessions with actual data
        if !session.wpmDataPoints.isEmpty {
            sessions.append(session)
            saveSessions()
            print("📝 Ended session: \(session.id) - Duration: \(Int(session.duration))s, Avg WPM: \(session.averageWPM)")
        } else {
            print("📝 Discarded empty session: \(session.id)")
        }
    }

    func addWPMDataPoint(wpm: Int, timestamp: Date = Date()) {
        guard currentSession != nil else { return }

        let dataPoint = WPMDataPoint(wpm: wpm, timestamp: timestamp)
        currentSession?.wpmDataPoints.append(dataPoint)
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }

    func clearAllSessions() {
        sessions.removeAll()
        saveSessions()
    }

    // MARK: - Filtering

    func sessionsFiltered(by audioSource: AudioSource? = nil) -> [Session] {
        guard let source = audioSource else {
            return sessions
        }
        return sessions.filter { $0.audioSource == source }
    }

    // MARK: - Persistence

    private func saveSessions() {
        // Keep only the most recent sessions
        let sessionsToSave = Array(sessions.suffix(maxSessionsToKeep))

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessionsToSave)
            try data.write(to: storageURL)
            print("💾 Saved \(sessionsToSave.count) sessions")
        } catch {
            print("❌ Failed to save sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            print("💾 No existing sessions file found")
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            sessions = try decoder.decode([Session].self, from: data)
            print("💾 Loaded \(sessions.count) sessions")
        } catch {
            print("❌ Failed to load sessions: \(error)")
        }
    }

    // MARK: - Statistics

    var totalSessions: Int {
        sessions.count
    }

    var totalSpeakingTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var overallAverageWPM: Int {
        guard !sessions.isEmpty else { return 0 }
        let sum = sessions.reduce(0) { $0 + $1.averageWPM }
        return sum / sessions.count
    }
}
