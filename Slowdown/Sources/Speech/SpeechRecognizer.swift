import Speech
import AVFoundation

class SpeechRecognizer {
    private let speechRecognizer: SFSpeechRecognizer?
    private var audioBuffer: AVAudioPCMBuffer?
    private var audioFormat: AVAudioFormat?
    private var bufferQueue: [AVAudioPCMBuffer] = []
    private var isRecognizing = false
    private var recordingTimer: Timer?
    private var useOnDeviceRecognition: Bool = false
    private var hasLoggedRecognitionMode: Bool = false

    private let chunkDuration: TimeInterval = 10.0  // Record 10 seconds at a time
    private let onWordsRecognized: (Int, TimeInterval) -> Void  // (wordCount, duration)

    init(onWordsRecognized: @escaping (Int, TimeInterval) -> Void) {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.onWordsRecognized = onWordsRecognized

        // Check on-device recognition availability once at init
        if let recognizer = speechRecognizer {
            useOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
            if useOnDeviceRecognition {
                print("🔒 On-device speech recognition available")
            } else {
                print("☁️ On-device recognition not available, will use server-based")
            }
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized")
                    completion(true)
                case .denied:
                    print("❌ Speech recognition denied")
                    completion(false)
                case .restricted:
                    print("❌ Speech recognition restricted")
                    completion(false)
                case .notDetermined:
                    print("❌ Speech recognition not determined")
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    func startRecognition() {
        guard !isRecognizing else { return }
        isRecognizing = true
        bufferQueue.removeAll()

        print("🎙️ Speech recognition started (chunk-based, \(Int(chunkDuration))s intervals)")

        // Start timer to process chunks periodically
        recordingTimer = Timer.scheduledTimer(withTimeInterval: chunkDuration, repeats: true) { [weak self] _ in
            self?.processCurrentChunk()
        }
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isRecognizing else { return }

        // Store format from first buffer
        if audioFormat == nil {
            audioFormat = buffer.format
        }

        // Add buffer to queue
        bufferQueue.append(buffer)
    }

    private func processCurrentChunk() {
        guard !bufferQueue.isEmpty, let format = audioFormat else {
            print("⏳ No audio in buffer, waiting...")
            return
        }

        // Take current buffers and clear queue
        let buffersToProcess = bufferQueue
        bufferQueue.removeAll()

        // Calculate total frame count
        let totalFrames = buffersToProcess.reduce(0) { $0 + Int($1.frameLength) }
        guard totalFrames > 0 else { return }

        print("🔄 Processing \(buffersToProcess.count) buffers (\(totalFrames) frames)...")

        // Create combined buffer
        guard let combinedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else {
            print("❌ Failed to create combined buffer")
            return
        }

        // Copy all buffers into combined buffer
        var currentFrame: AVAudioFrameCount = 0
        for buffer in buffersToProcess {
            let framesToCopy = buffer.frameLength
            if let srcData = buffer.floatChannelData?[0],
               let dstData = combinedBuffer.floatChannelData?[0] {
                memcpy(dstData.advanced(by: Int(currentFrame)), srcData, Int(framesToCopy) * MemoryLayout<Float>.size)
            }
            currentFrame += framesToCopy
        }
        combinedBuffer.frameLength = currentFrame

        // Transcribe the chunk
        transcribeBuffer(combinedBuffer)
    }

    private func transcribeBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("❌ Speech recognizer not available")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false

        // Use on-device recognition if available (checked at init)
        if useOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        request.append(buffer)
        request.endAudio()

        speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            if let error = error {
                let nsError = error as NSError
                // Ignore "no speech" errors
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    print("⏳ No speech detected in chunk")
                    return
                }
                print("⚠️ Transcription error: \(error.localizedDescription)")
                return
            }

            guard let result = result, result.isFinal else { return }

            let transcript = result.bestTranscription.formattedString
            let words = transcript.split(separator: " ")
            let wordCount = words.count

            if wordCount > 0 {
                print("📝 Chunk transcribed: \"\(transcript)\" (\(wordCount) words in \(Int(self?.chunkDuration ?? 10))s)")
                self?.onWordsRecognized(wordCount, self?.chunkDuration ?? 10.0)
            }
        }
    }

    func stopRecognition() {
        print("🛑 Speech recognition stopped")
        isRecognizing = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        bufferQueue.removeAll()
        audioFormat = nil
    }
}
