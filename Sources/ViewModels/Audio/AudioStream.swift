import AVFoundation

class AudioStreamer {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private var inputFormat: AVAudioFormat?
    private var isPaused: Bool = false
    private var audioWebSocket: AudioWebSocket?
    private var converter: AVAudioConverter?

    // WhisperLive 설정에 맞춘 포맷
    private var bufferSize: AVAudioFrameCount = 4096
    private var sampleRate: Double = 16000
    private var channels: UInt32 = 1

    init(webSocket: AudioWebSocket) {
        self.inputNode = engine.inputNode
        self.audioWebSocket = webSocket
    }

    // MARK: - 오디오 세션 설정
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setActive(true)

            // 🔍 사용 가능한 오디오 입력 디바이스 탐색
            if let availableInputs = session.availableInputs {
                for input in availableInputs {
                    print("🔎 입력 디바이스 발견: \(input.portType.rawValue)")
                    if input.portType == .bluetoothHFP || input.portType == .bluetoothLE {
                        try session.setPreferredInput(input)
                        print("🎧 에어팟이 입력 디바이스로 설정되었습니다.")
                    }
                }
            }

            // ✅ 실제 하드웨어 포맷 가져오기
            let inputSampleRate = session.sampleRate
            let inputChannels = UInt32(session.inputNumberOfChannels)
            print("🎙️ 설정된 샘플레이트: \(inputSampleRate)")
            print("🎙️ 설정된 채널 수: \(inputChannels)")

            // ✅ 샘플레이트를 16000으로 변환하도록 설정
            let inputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputSampleRate, channels: inputChannels, interleaved: false)!
            let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: inputChannels, interleaved: false)!
            
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
            
        } catch {
            print("🔴 오디오 세션 설정 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 오디오 스트리밍 시작
    func startStreaming() {
        configureAudioSession()
        
        let format = inputNode.outputFormat(forBus: 0)
        self.inputFormat = format

        
        self.inputFormat = format
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        do {
            try engine.start()
            print("🎙️ AVAudioEngine 시작됨")
        } catch {
            print("🔴 AVAudioEngine 시작 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 오디오 버퍼를 WebSocket으로 서버로 전송
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = converter else { return }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: buffer.frameCapacity)!
        var error: NSError?

        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            print("🔴 변환 중 에러: \(error.localizedDescription)")
            return
        }

        if let audioData = convertBufferTo16BitPCM(outputBuffer) {
            print("🔄 PCM 데이터 전송 중...")
            audioWebSocket?.sendDataToServer(audioData)
        } else {
            print("Error: Audio buffer 변환 실패")
        }
    }

    // MARK: - 32bit float PCM -> 16bit int PCM 변환
    func convertBufferTo16BitPCM(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let floatChannelData = buffer.floatChannelData else {
            print("floatChannelData is nil")
            return nil
        }

        let channelPointer = floatChannelData.pointee
        let frameLength = Int(buffer.frameLength)
        var pcmData = Data(capacity: frameLength * MemoryLayout<Int16>.size)

        for i in 0..<frameLength {
            let sample = max(-1.0, min(1.0, channelPointer[i])) // 클리핑 처리
            var intSample = Int16(sample * Float(Int16.max))
            pcmData.append(Data(bytes: &intSample, count: MemoryLayout<Int16>.size))
        }

        return pcmData
    }

    // MARK: - 오디오 스트리밍 일시 정지
    func pauseStreaming() {
        guard !isPaused else { return }
        inputNode.removeTap(onBus: 0)
        isPaused = true
    }

    // MARK: - 오디오 스트리밍 재개
    func resumeStreaming() {
        guard isPaused else { return }
        guard let inputFormat = inputFormat else {
            print("inputFormat이 nil입니다.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        isPaused = false
    }

    // MARK: - 오디오 스트리밍 중지
    func stopStreaming() {
        inputNode.removeTap(onBus: 0)
        engine.stop()
        print("🛑 AVAudioEngine 중지됨")
    }
}

