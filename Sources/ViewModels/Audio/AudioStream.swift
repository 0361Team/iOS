//
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
            // 🎧 블루투스 장치 포함하여 오디오 재생 및 녹음 설정
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
        
        // ✅ 하드웨어 포맷에 맞춰 Tap 포맷 설정
        let inputFormat = inputNode.inputFormat(forBus: 0)
        print("🔍 Input Format: \(inputFormat)")

        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                               sampleRate: 16000,
                                               channels: 1,
                                               interleaved: true) else {
            print("⚠️ AVAudioFormat 생성 실패")
            return
        }

        // ✅ Converter 생성
        guard let audioConverter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            print("🔴 Converter 초기화 실패")
            return
        }
        
        // 🔄 여기서 converter에 값을 할당해야 함
        self.converter = audioConverter

        print("✅ Converter 초기화 성공")

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
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

        // 먼저 16비트 PCM으로 변환 후 Float32로 다시 변환
        if let pcmData = convertBufferTo16BitPCM(outputBuffer) {
            // Float32로 변환하여 서버에 전송
            let floatData = convertPCMToFloat32(pcmData)
            print("🔄 Float32 데이터 전송 중...")
            audioWebSocket?.sendDataToServer(floatData)
        } else {
            print("Error: Audio buffer 변환 실패")
        }
    }

    // MARK: - 32bit float PCM -> 16bit int PCM 변환
    func convertBufferTo16BitPCM(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.int16ChannelData else {
            print("int16ChannelData is nil")
            return nil
        }
        let channelPointer = channelData.pointee
        let dataLength = Int(buffer.frameLength) * MemoryLayout<Int16>.size
        return Data(bytes: channelPointer, count: dataLength)
    }
    
    // MARK: - 16bit int PCM -> Float32 변환 (새로 추가)
    func convertPCMToFloat32(_ pcmData: Data) -> Data {
        // 16비트 PCM 데이터를 float32로 변환
        var floatArray = [Float32](repeating: 0, count: pcmData.count / 2)
        
        pcmData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Void in
            if let baseAddress = bytes.baseAddress {
                let int16Buffer = baseAddress.bindMemory(to: Int16.self, capacity: pcmData.count / 2)
                for i in 0..<pcmData.count / 2 {
                    // -1.0에서 1.0 사이로 정규화 (Python 코드와 동일한 처리)
                    floatArray[i] = Float32(int16Buffer[i]) / 32768.0
                }
            }
        }
        
        // Float32 배열을 Data로 변환
        return Data(bytes: floatArray, count: floatArray.count * MemoryLayout<Float32>.size)
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
