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
        let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                   sampleRate: sampleRate,
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

    // MARK: - 오디오 버퍼를 WebSocket으로 서버로 전송
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        if let audioData = convertBufferTo16BitPCM(buffer) {
            print("🔄 PCM 데이터 전송 중...")
            audioWebSocket?.sendDataToServer(audioData)
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
