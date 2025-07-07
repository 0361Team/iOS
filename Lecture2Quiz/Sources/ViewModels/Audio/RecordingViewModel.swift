//
//  RecordingViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/27/25.
//

import AVFoundation
import Combine
import Moya

struct TranscriptionSegment: Identifiable, Equatable {
    var id = UUID()
    var start: Double
    var end: Double
    var text: String
    var completed: Bool
}

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

    // ✅ segment 단위 관리
    private var segments: [TranscriptionSegment] = []

    init() {}

    func startRecording() {
        guard let audioAPIUrl = Bundle.main.object(forInfoDictionaryKey: "AudioAPI_URL") as? String else {
            fatalError("❌ xcconfig에서 'AudioAPI_URL'을 찾을 수 없습니다.")
        }

        audioWebSocket = AudioWebSocket(host: audioAPIUrl, port: 443)
        audioStreamer = AudioStreamer(webSocket: audioWebSocket!)

        isLoading = true

        audioWebSocket?.onTranscriptionReceived = { [weak self] text in
            self?.handleRawTranscriptionJSON(text)
        }

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
        audioWebSocket?.onTranscriptionReceived = nil
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

    // ✅ 최종 텍스트 처리
    func finalizeTranscription() {
        isLoading = false
        let completedText = segments
            .filter { $0.completed }
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
        finalScript = completedText
        print("📝 최종 스크립트:\n\(finalScript)")
    }

    func postTranscript(to weekId: Int, type: String = "RECORDING") {
        let content = finalScript.trimmingCharacters(in: .whitespacesAndNewlines)
        let provider = MoyaProvider<CourseAPI>()

        provider.request(.submitTranscript(weekId: weekId, content: content, type: type)) { result in
            switch result {
            case .success(let response):
                print("✅ 전송 성공: \(response.statusCode)")
            case .failure(let error):
                print("❌ 전송 실패: \(error)")
            }
        }
    }

    // ✅ 서버로부터 받은 JSON 문자열 처리
    func handleRawTranscriptionJSON(_ jsonString: String) {
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return }

        if trimmed.hasPrefix("{") {
            do {
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let segmentDicts = dict["segments"] as? [[String: Any]] {

                    for item in segmentDicts {
                        guard let startStr = item["start"] as? String,
                              let endStr = item["end"] as? String,
                              let text = item["text"] as? String,
                              let completed = item["completed"] as? Bool,
                              let start = Double(startStr),
                              let end = Double(endStr) else { continue }

                        let newSegment = TranscriptionSegment(start: start, end: end, text: text, completed: completed)

                        // start 기준으로 덮어쓰기 또는 append
                        if let index = self.segments.firstIndex(where: { $0.start == start }) {
                            self.segments[index] = newSegment
                        } else {
                            self.segments.append(newSegment)
                        }
                    }

                    DispatchQueue.main.async {
                        let completedTexts = self.segments
                            .filter { $0.completed }
                            .sorted(by: { $0.start < $1.start })
                            .map { $0.text.trimmingCharacters(in: .whitespaces) }

                        let pendingText = self.segments
                            .filter { !$0.completed }
                            .sorted(by: { $0.start < $1.start })
                            .map { $0.text.trimmingCharacters(in: .whitespaces) }
                            .last ?? ""

                        self.transcriptionList = completedTexts + (pendingText.isEmpty ? [] : [pendingText])
                        self.finalScript = self.transcriptionList.joined(separator: " ")
                    }
                }
            } catch {
                print("❌ JSON 파싱 오류: \(error)")
            }
        } else {
            // 일반 텍스트 처리
            DispatchQueue.main.async {
                if self.transcriptionList.last != trimmed {
                    self.transcriptionList.append(trimmed)
                    self.finalScript = self.transcriptionList.joined(separator: " ")
                }
            }
        }
    }



}
