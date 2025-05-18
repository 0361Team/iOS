//  AudioStream.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/27/25.
//

import AVFoundation

class AudioStreamer {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private var inputFormat: AVAudioFormat?
    private var isPaused: Bool = false
    private var audioWebSocket: AudioWebSocket?
    private var partialBuffer = Data() // 🔄 남은 청크 보관

    // WhisperLive 설정에 맞춘 포맷
    private var bufferSize: AVAudioFrameCount = 1600  // 100ms 기준
    private var sampleRate: Double = 16000
    private var channels: UInt32 = 1

    // 🔄 리샘플링을 위한 오디오 컨버터
    private var converter: AVAudioConverter?

    init(webSocket: AudioWebSocket) {
        self.inputNode = engine.inputNode
        self.audioWebSocket = webSocket
        
        // 💡 리샘플링 포맷 설정
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("🔍 입력 포맷: \(inputFormat)")

        // 🔄 WhisperLive가 기대하는 16kHz Int16 포맷 생성
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: 16000,
                                         channels: 1,
                                         interleaved: true)!
        
        // 🔄 오디오 변환기 생성
        self.converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        self.inputFormat = outputFormat
    }

    // MARK: - 오디오 세션 설정
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setPreferredSampleRate(48000)
            try session.setPreferredInputNumberOfChannels(1) // Mono로 강제 설정
            try session.setMode(.measurement)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            sampleRate = session.sampleRate
            channels = UInt32(session.inputNumberOfChannels)
            print("🎙️ 설정된 샘플레이트: \(sampleRate)")
            print("🎙️ 설정된 채널 수: \(channels)")
        } catch {
            print("🔴 오디오 세션 설정 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 오디오 스트리밍 시작
    func startStreaming() {
        configureAudioSession()
        
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: 48000,
                                   channels: channels,
                                   interleaved: true)
        
        guard let hardwareFormat = format else {
            print("⚠️ 오디오 포맷 생성 실패")
            return
        }

        self.inputFormat = hardwareFormat
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: hardwareFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        do {
            try engine.start()
            print("🎙️ AVAudioEngine 시작됨")
        } catch {
            print("🔴 AVAudioEngine 시작 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 오디오 버퍼를 WebSocket으로 전송
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = self.converter else {
            print("❌ 오디오 컨버터 생성 실패")
            return
        }

        // 🔍 **RMS 계산**
        if let floatChannelData = buffer.floatChannelData {
            let frameLength = Int(buffer.frameLength)
            let channelDataValue = Array(UnsafeBufferPointer(start: floatChannelData.pointee, count: frameLength))
            
            // 🔄 RMS 계산
            let rms = sqrt(channelDataValue.map { $0 * $0 }.reduce(0, +) / Float(frameLength))
            print("🔊 오디오 RMS 값: \(rms)")
            
            // 🔍 너무 작으면 경고 로그 출력
            if rms < 0.01 {
                print("⚠️ 볼륨이 너무 작습니다.")
            }
        }

        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: 16000,
                                         channels: 1,
                                         interleaved: true)!

        guard let newBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: 1600) else {
            print("❌ PCM Buffer 생성 실패")
            return
        }

        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        var error: NSError?
        converter.convert(to: newBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            print("❌ 오디오 변환 실패: \(error.localizedDescription)")
            return
        }

        print("📝 변환된 Buffer Frame Length: \(newBuffer.frameLength), Sample Rate: \(newBuffer.format.sampleRate)")

        if let audioData = convertToFloat32BytesLikePython(newBuffer) {
            var completeData = partialBuffer + audioData
            let chunkSize = 4096

            while completeData.count >= chunkSize {
                let chunk = completeData.prefix(chunkSize)
                audioWebSocket?.sendDataToServer(chunk)
                print("🔄 오디오 데이터 전송 성공: 4096 바이트")
                completeData.removeFirst(chunkSize)
            }

            partialBuffer = completeData
        }
    }



    // MARK: - Python의 bytes_to_float_array 메소드와 유사하게 변환
    func convertToFloat32BytesLikePython(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let int16ChannelData = buffer.int16ChannelData else {
            print("int16ChannelData is nil")
            return nil
        }

        let frameLength = Int(buffer.frameLength)
        let channelPointer = int16ChannelData.pointee
        
        // Float32 배열 생성
        var floatArray = [Float32](repeating: 0, count: frameLength)
        
        // Int16 -> Float32 정규화 (Python과 동일한 방식)
        for i in 0..<frameLength {
            let int16Value = channelPointer[i]
            // Python의 정규화 방식: value.astype(np.float32) / 32768.0
            floatArray[i] = Float32(Int16(littleEndian: int16Value)) / 32768.0

        }
        
        // Float32 배열을 바이트로 변환 (Python의 tobytes()와 동일)
        let floatData = Data(bytes: floatArray, count: frameLength * MemoryLayout<Float32>.size)
        
        print("🔄 Python 스타일로 Float32로 변환 완료 - \(floatData.count) bytes")
        return floatData
    }

    // MARK: - 오디오 스트리밍 일시 정지
    func pauseStreaming() {
        guard !isPaused else { return }
        inputNode.removeTap(onBus: 0)
        isPaused = true
        print("⏸️ 오디오 스트리밍 일시 정지됨")
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
        print("▶️ 오디오 스트리밍 재개됨")
    }

    // MARK: - 오디오 스트리밍 중지
    func stopStreaming() {
        inputNode.removeTap(onBus: 0)
        engine.stop()
        print("🛑 AVAudioEngine 중지됨")
    }
}
