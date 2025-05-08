//
//  RecordingViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/27/25.
//

import Foundation
import Combine

class RecordingViewModel: ObservableObject {
    @Published var timeLabel: String = "00:00"    // 레이블용
    @Published var isRecording: Bool = false      // 녹음중 여부
    @Published var isPaused: Bool = false         // pause 여부
    
    private var timer: Timer?
    private var elapsedSeconds: Int = 0
    private var streamer = AudioStreamer()        // 녹음 담당 클래스

    
    
    func startRecording() {
        // 상태 초기화
        elapsedSeconds = 0
        timeLabel = "00:00"
        isRecording = true
        
        // AudioStreamer로 녹음 시작
        streamer.startStreaming()
        
        // Timer 시작
        startTimer()
    }

    func stopRecording() {
        isRecording = false
        
        // AudioStreamer로 녹음 중지
        streamer.stopStreaming()
        
        // Timer 중지
        stopTimer()
    }
    
    func pauseRecording() {
        guard isRecording && !isPaused else { return }
        isPaused = true
        streamer.pauseStreaming()  // AudioStreamer도 일시정지
        stopTimer()
    }

    func resumeRecording() {
        guard isRecording && isPaused else { return }
        isPaused = false
        streamer.resumeStreaming() // AudioStreamer도 다시 시작
        startTimer()
    }
    
    
    

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            self.updateTimeLabel()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimeLabel() {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        timeLabel = String(format: "%02d:%02d", minutes, seconds)
    }
}

