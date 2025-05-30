//
//  RecordingViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/27/25.
//

import AVFoundation
import Combine
import Moya

class AudioViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var timeLabel = "00:00"
    @Published var transcriptionList: [String] = []
    @Published var isLoading = false
    @Published var finalScript: String = ""
    
    private var finalTextTimer: Timer?
    private var finalTextDeadline: Date?
    
    private var audioStreamer: AudioStreamer?
    private var audioWebSocket: AudioWebSocket?
    
    private var timer: Timer?
    private var elapsedTime: Int = 0
    
    init() {}
    
    func startRecording() {
        // 서버 URL 준비
        guard let audioAPIUrl = Bundle.main.object(forInfoDictionaryKey: "AudioAPI_URL") as? String else {
            fatalError("❌ xcconfig에서 'AudioAPI_URL'을 찾을 수 없습니다.")
        }
        
        // WebSocket 초기화
        audioWebSocket = AudioWebSocket(host: audioAPIUrl, port: 443)
        audioStreamer = AudioStreamer(webSocket: audioWebSocket!)
        
        isLoading = true // ✅ 서버 준비 기다리는 중
        
        // 텍스트 수신 콜백(중복 제거)
        audioWebSocket?.onTranscriptionReceived = { [weak self] text in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if self.transcriptionList.last != text {
                    self.transcriptionList.append(text)
                }
            }
        }
        
        // 서버가 준비됐을 때 녹음 시작
        audioWebSocket?.onServerReady = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                self.isRecording = true
                self.isPaused = false
                self.timeLabel = "00:00"
                self.elapsedTime = 0
                self.startTimer()
                self.audioStreamer?.startStreaming()
            }
        }
        
        // WebSocket 연결은 AudioWebSocket 초기화 시 자동으로 이뤄져야 함
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
        isPaused = false
        timer?.invalidate()

        audioStreamer?.stopStreaming()
        audioWebSocket?.sendEndOfAudio()

        // 콜백을 제거해서 더 이상 transcription을 받지 않게 한다
        audioWebSocket?.onTranscriptionReceived = nil

        // 즉시 WebSocket 종료 (15초 대기 없이)
        audioWebSocket?.closeConnection()
    }


    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1
            let minutes = self.elapsedTime / 60
            let seconds = self.elapsedTime % 60
            self.timeLabel = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func finalizeTranscription() {
        isLoading = false
        finalScript = transcriptionList.joined(separator: " ")
        print("📝 최종 스크립트:\n\(finalScript)")
    }
    
    func postTranscript(to weekId: Int, type: String = "RECORDING") {
        let content = finalScript.trimmingCharacters(in: .whitespacesAndNewlines)
        let provider = MoyaProvider<CourseAPI>()
        
        let payload: [String: Any] = [
            "weekId": weekId,
            "content": content,
            "type": type
        ]
        
        provider.request(.submitTranscript(weekId: weekId, content: content, type: type)) { result in
            switch result {
            case .success(let response):
                print("✅ 전송 성공: \(response.statusCode)")
            case .failure(let error):
                print("❌ 전송 실패: \(error)")
            }
        }
        
    }
}
