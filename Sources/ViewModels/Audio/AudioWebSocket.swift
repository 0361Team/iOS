import Foundation

class AudioWebSocket: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private let host: String
    private let port: Int
    private var retryCount = 0
    private let maxRetries = 3
    private var uid: String
    private let modelSize: String
    
    // 트랜스크립션 결과를 처리하기 위한 콜백
    var onTranscriptionReceived: ((String) -> Void)?

    init(host: String, port: Int, modelSize: String = "tiny") {
        self.host = host
        self.port = port
        self.uid = UUID().uuidString // 고유 식별자 생성
        self.modelSize = modelSize
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
        
        // URL 형식이 wss://host:port 가 아닌 wss://host 형식인지 확인
        // Python 클라이언트에서는 f"ws://{host}:{port}" 형식을 사용
        let socketURL = port == 443 || port == 80
            ? "wss://\(host)"
            : "wss://\(host):\(port)"
        
        guard let url = URL(string: socketURL) else {
            print("잘못된 URL: \(socketURL)")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        print("WebSocket 연결 시도: \(socketURL)")
        listen() // 먼저 수신 리스너 설정
        sendInitialJSON() // 그 다음 초기 JSON 전송
    }

    // MARK: - 첫 JSON 전송
    private func sendInitialJSON() {
        // JSON Payload 생성
        let jsonPayload: [String: Any] = [
            "uid": uid,
            "language": "ko",
            "task": "transcribe",
            "model": modelSize, // 초기화 시 설정된 모델 크기 사용
            "use_vad": true,
            "max_clients": 4,
            "max_connection_time": 600
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonPayload, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            print("📡 전송 JSON: \(jsonString)")
            
            // JSON 전송
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
                print("🔄 오디오 데이터 전송 성공: \(data.count) 바이트")
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
                self?.listen() // 다음 메시지를 위해 다시 리스너 설정
            case .failure(let error):
                print("수신 오류: \(error.localizedDescription)")
                self?.reconnect()
            }
        }
    }

    // MARK: - 메시지 처리 - Python 클라이언트와 유사하게 개선
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            print("서버에서 받은 바이너리 데이터: \(data.count) bytes")
            
        case .string(let text):
            print("서버에서 받은 텍스트: \(text)")
            
            // Python 클라이언트와 같은 방식으로 JSON 파싱 및 처리
            if let data = text.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // 상태 메시지 처리
                        if let status = json["status"] as? String {
                            handleStatusMessage(status: status, message: json["message"] as? String)
                            return
                        }
                        
                        // "SERVER_READY" 메시지 처리
                        if let message = json["message"] as? String, message == "SERVER_READY" {
                            print("✅ 서버 준비 완료")
                            if let backend = json["backend"] as? String {
                                print("👉 서버 백엔드: \(backend)")
                            }
                            return
                        }
                        
                        // 언어 감지 메시지 처리
                        if let language = json["language"] as? String {
                            print("🔍 감지된 언어: \(language)")
                            if let prob = json["language_prob"] as? Double {
                                print("확률: \(prob)")
                            }
                            return
                        }
                        
                        // 세그먼트 처리 (트랜스크립션 결과)
                        if let segments = json["segments"] as? [[String: Any]] {
                            processSegments(segments)
                        }
                    }
                } catch {
                    print("JSON 파싱 오류: \(error.localizedDescription)")
                }
            }
            
        @unknown default:
            print("알 수 없는 메시지 타입")
        }
    }
    
    // 상태 메시지 처리
    private func handleStatusMessage(status: String, message: String?) {
        switch status {
        case "WAIT":
            print("⏳ 서버가 대기 중입니다: \(message ?? "대기 중")")
        case "ERROR":
            print("❌ 서버 에러: \(message ?? "알 수 없는 오류")")
        case "WARNING":
            print("⚠️ 서버 경고: \(message ?? "경고")")
        default:
            print("ℹ️ 서버 상태: \(status), 메시지: \(message ?? "없음")")
        }
    }
    
    // 세그먼트 처리 (Python 클라이언트의 process_segments 함수와 유사)
    private func processSegments(_ segments: [[String: Any]]) {
        var textResults = [String]()
        
        for segment in segments {
            if let text = segment["text"] as? String, !textResults.contains(text) {
                textResults.append(text)
                print("🔊 트랜스크립션: \(text)")
                
                // 콜백을 통해 결과 전달
                onTranscriptionReceived?(text)
            }
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
    
    // MARK: - 오디오 스트림 종료 신호 전송
    func sendEndOfAudio() {
        guard isConnected else {
            print("전송 실패: 연결되지 않음")
            return
        }
        
        // Python 클라이언트의 END_OF_AUDIO 상수와 동일
        let endOfAudioMessage = "END_OF_AUDIO"
        
        webSocketTask?.send(.string(endOfAudioMessage)) { [weak self] error in
            if let error = error {
                print("End Of Audio 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ End Of Audio 전송 성공")
            }
        }
    }
}
