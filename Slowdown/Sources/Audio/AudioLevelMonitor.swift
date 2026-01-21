import AVFoundation
import Combine

class AudioLevelMonitor: ObservableObject {
    @Published var level: Float = 0  // 0.0 to 1.0
    @Published var isReceivingAudio: Bool = false

    private var lastUpdateTime: Date = Date()

    func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // Calculate RMS (root mean square) for audio level
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))

        // Convert to 0-1 range (with some amplification for visibility)
        let normalizedLevel = min(1.0, rms * 5)

        DispatchQueue.main.async {
            self.level = normalizedLevel
            self.isReceivingAudio = normalizedLevel > 0.01
            self.lastUpdateTime = Date()
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.level = 0
            self.isReceivingAudio = false
        }
    }
}
