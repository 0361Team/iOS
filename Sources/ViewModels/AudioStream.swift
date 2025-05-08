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
    private let outputNode: AVAudioOutputNode
    private var inputFormat: AVAudioFormat?
    private var isPaused: Bool = false
    private(set) var receivedBufferCount = 0  // 받은 버퍼 수 (테스트용)
    
    init() {
        self.inputNode = engine.inputNode
        self.outputNode = engine.outputNode
    }

    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error.localizedDescription)")
        }
    }
    
    func startStreaming() {
        configureAudioSession() // 오디오 세션 설정
        inputFormat = inputNode.inputFormat(forBus: 0)
        
        guard let inputFormat else {
            print("inputFormat이 nil입니다.")
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            
            self?.receivedBufferCount += 1 // 🔥 버퍼 받을 때마다 +1 (테스트용)
            
            // buffer를 서버로 보내거나, 이펙트를 적용하거나 등등 처리
            print("오디오 버퍼 수신, frameLength: \(buffer.frameLength)")
        }
        
        do {
            try engine.start()
            print("AVAudioEngine 시작됨")
        } catch {
            print("AVAudioEngine 시작 실패: \(error.localizedDescription)")
        }
        
        receivedBufferCount = 0 // (테스트용)
    }
    
    func pauseStreaming() {
        guard !isPaused else { return }
        inputNode.removeTap(onBus: 0)
        isPaused = true
    }

    func resumeStreaming() {
        guard isPaused else { return }
        
        guard let inputFormat else {
            print("inputFormat이 nil입니다.")
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            self?.receivedBufferCount += 1
            print("오디오 버퍼 수신, frameLength: \(buffer.frameLength)")
        }
        
        isPaused = false
    }
    
    func stopStreaming() {
        inputNode.removeTap(onBus: 0)
        engine.stop()
        print("AVAudioEngine 중지됨")
    }
}
