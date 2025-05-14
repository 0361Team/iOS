//
//  RecordingViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/27/25.
//

import AVFoundation
import Combine

class AudioViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var timeLabel = "00:00"

    private var audioStreamer: AudioStreamer?
    private var audioWebSocket: AudioWebSocket?
    
    private var timer: Timer?
    private var elapsedTime: Int = 0

    init() {
        // WebSocket 서버 주소와 포트를 설정하여 AudioStreamer와 WebSocket을 초기화
        audioWebSocket = AudioWebSocket(host: "whisperlive-cpu-620597935007.us-central1.run.app", port: 443)
        audioStreamer = AudioStreamer(webSocket: audioWebSocket!)
    }

    func startRecording() {
        isRecording = true
        isPaused = false
        timeLabel = "00:00"
        elapsedTime = 0
        
        // 타이머 시작
        startTimer()

        // 오디오 스트리밍 시작
        audioStreamer?.startStreaming()
    }

    func pauseRecording() {
        isPaused = true
        audioStreamer?.pauseStreaming()
        timer?.invalidate()
    }

    func resumeRecording() {
        isPaused = false
        audioStreamer?.resumeStreaming()
        startTimer()
    }

    func stopRecording() {
        isRecording = false
        audioStreamer?.stopStreaming()
        timer?.invalidate()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1
            let minutes = self.elapsedTime / 60
            let seconds = self.elapsedTime % 60
            self.timeLabel = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
