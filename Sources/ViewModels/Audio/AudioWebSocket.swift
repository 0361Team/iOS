//  AudioWebSocket.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/12/25.
//

import Foundation

class AudioWebSocket: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private let host: String
    private let port: Int
    private var retryCount = 0
    private let maxRetries = 3
    private var uid: String

    init(host: String, port: Int) {
        self.host = host
        self.port = port
        self.uid = UUID().uuidString // 고유 식별자 생성
        super.init()
        
        self.urlSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: .main
        )
        connect()
    }

    // MARK: - WebSocket 연결 (재연결 지원)
    private func connect() {
        guard retryCount <= maxRetries else {
            print("최대 재연결 시도 횟수 초과")
            return
        }
        
        let socketURL = "wss://\(host)"
        
        guard let url = URL(string: socketURL) else {
            print("잘못된 URL: \(socketURL)")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        print("WebSocket 연결 시도: \(socketURL)")
        sendInitialJSON()   // ➡️ 처음 연결 시 JSON 전송
        listen()
    }

    // MARK: - 첫 JSON 전송
    private func sendInitialJSON() {
        // JSON Payload 생성
        let jsonPayload: [String: Any] = [
            "uid": uid,
            "language": "ko",
            "task": "transcribe",
            "model": "tiny",
            "use_vad": false,
            "max_clients": 4,
            "max_connection_time": 600
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonPayload, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            print("📡 전송 JSON: \(jsonString)")
            
            // ✅ 전송
            webSocketTask?.send(.string(jsonString)) { [weak self] error in
                if let error = error {
                    print("JSON 전송 실패: \(error.localizedDescription)")
                    self?.reconnect()
                } else {
                    print("✅ JSON 전송 성공")
                }
            }
        } catch {
            print("❌ JSON 직렬화 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 데이터 전송
    func sendDataToServer(_ data: Data) {
        guard isConnected else {
            print("전송 실패: 연결되지 않음")
            reconnect()
            return
        }

        webSocketTask?.send(.data(data)) { [weak self] error in
            if let error = error {
                print("전송 실패: \(error.localizedDescription)")
                self?.reconnect()
            } else {
                print("🔄 오디오 데이터 전송 성공")
            }
        }
    }

    // MARK: - 연결 상태 체크
    private var isConnected: Bool {
        webSocketTask?.state == .running
    }

    // MARK: - 재연결 로직
    private func reconnect() {
        retryCount += 1
        let delay = min(5.0, pow(2.0, Double(retryCount)))
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            print("재연결 시도 (\(self?.retryCount ?? 0)/\(self?.maxRetries ?? 0))")
            self?.connect()
        }
    }

    // MARK: - 메시지 수신 대기
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.listen()
            case .failure(let error):
                print("수신 오류: \(error.localizedDescription)")
                self?.reconnect()
            }
        }
    }

    // MARK: - 메시지 처리
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            print("서버에서 받은 바이너리 데이터: \(data.count) bytes")
        case .string(let text):
            print("서버에서 받은 텍스트: \(text)")
        @unknown default:
            print("알 수 없는 메시지 타입")
        }
    }

    // MARK: - 연결 종료 처리
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("연결 종료. 코드: \(closeCode.rawValue)")
        reconnect()
    }

    // MARK: - 수동 연결 종료
    func closeConnection() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        print("WebSocket 연결 종료 요청")
    }
}
