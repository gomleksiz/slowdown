import AVFoundation
import ScreenCaptureKit
import Combine

class AudioCaptureManager: NSObject {
    private var audioEngine: AVAudioEngine?
    private var stream: SCStream?
    private var currentSource: AudioSource = .microphone
    private var selectedDeviceUID: String?
    private let onAudioBuffer: (AVAudioPCMBuffer) -> Void

    private(set) var isCapturing = false

    init(onAudioBuffer: @escaping (AVAudioPCMBuffer) -> Void) {
        self.onAudioBuffer = onAudioBuffer
        super.init()
    }

    func setSource(_ source: AudioSource) {
        currentSource = source
        UserDefaults.standard.set(source.rawValue, forKey: "audioSource")
    }

    func setDevice(uid: String?) {
        selectedDeviceUID = uid
        if let uid = uid {
            // Find the device and set it as default input
            let devices = AudioDeviceManager.shared.getInputDevices()
            if let device = devices.first(where: { $0.uid == uid }) {
                if AudioDeviceManager.shared.setDefaultInputDevice(deviceID: device.id) {
                    print("✅ Set default input device to: \(device.name)")
                } else {
                    print("⚠️ Failed to set default input device")
                }
            }
        }
    }

    func startCapture() {
        switch currentSource {
        case .microphone:
            requestMicrophonePermission { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.startMicrophoneCapture()
                    }
                } else {
                    print("❌ Microphone permission denied")
                }
            }
        case .systemAudio:
            startSystemAudioCapture()
        }
    }

    func stopCapture() {
        stopMicrophoneCapture()
        stopSystemAudioCapture()
        isCapturing = false
    }

    // MARK: - Microphone Permission

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("✅ Microphone already authorized")
            completion(true)
        case .notDetermined:
            print("🔄 Requesting microphone permission...")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                print(granted ? "✅ Microphone permission granted" : "❌ Microphone permission denied")
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied:
            print("❌ Microphone permission denied - go to System Settings > Privacy > Microphone")
            completion(false)
        case .restricted:
            print("❌ Microphone permission restricted")
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    // MARK: - Microphone Capture

    private func startMicrophoneCapture() {
        print("🎤 Starting microphone capture...")

        // Stop any existing engine
        stopMicrophoneCapture()

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            print("❌ Failed to create audio engine")
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        print("📊 Recording format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")

        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("❌ Invalid microphone format")
            return
        }

        do {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
                self?.onAudioBuffer(buffer)
            }
            print("✅ Audio tap installed")

            try audioEngine.start()
            isCapturing = true
            print("✅ Audio engine started - microphone is now capturing")

        } catch {
            print("❌ Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    private func stopMicrophoneCapture() {
        guard audioEngine != nil else { return }
        print("🛑 Stopping microphone capture...")
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    // MARK: - System Audio Capture

    private func startSystemAudioCapture() {
        print("🔊 Starting system audio capture...")
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

                let config = SCStreamConfiguration()
                config.capturesAudio = true
                config.excludesCurrentProcessAudio = true
                config.sampleRate = 48000
                config.channelCount = 1

                guard let display = content.displays.first else {
                    print("❌ No displays available")
                    return
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                stream = SCStream(filter: filter, configuration: config, delegate: nil)

                try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: .main)
                try await stream?.startCapture()

                await MainActor.run {
                    isCapturing = true
                    print("✅ System audio capture started")
                }

            } catch {
                print("❌ Failed to start system audio capture: \(error.localizedDescription)")
            }
        }
    }

    private func stopSystemAudioCapture() {
        guard stream != nil else { return }
        print("🛑 Stopping system audio capture...")
        Task {
            try? await stream?.stopCapture()
            stream = nil
        }
    }
}

// MARK: - SCStreamOutput

extension AudioCaptureManager: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }

        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else {
            return
        }

        guard let format = AVAudioFormat(streamDescription: audioStreamBasicDescription) else {
            return
        }

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }

        let frameCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return
        }

        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)

        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?

        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)

        if let dataPointer = dataPointer, let floatChannelData = pcmBuffer.floatChannelData {
            memcpy(floatChannelData[0], dataPointer, totalLength)
        }

        onAudioBuffer(pcmBuffer)
    }
}
