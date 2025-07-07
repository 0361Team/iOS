    // AudioWebSocket.swift
    // Lecture2Quiz

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
        private var pingTimer: Timer?
        private var processedTexts = Set<String>()

        var onServerReady: (() -> Void)?
        var onTranscriptionReceived: ((String) -> Void)?

        init(host: String, port: Int, modelSize: String = "medium") {
            self.host = host
            self.port = port
            self.uid = UUID().uuidString
            self.modelSize = modelSize
            super.init()

            self.urlSession = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )
            connect()
        }

        private func connect() {
            guard retryCount <= maxRetries else {
                print("❌ 최대 재연결 시도 초과")
                return
            }

            let socketURL = port == 443 || port == 80
                ? "wss://\(host)"
                : "wss://\(host):\(port)"

            guard let url = URL(string: socketURL) else {
                print("❌ 잘못된 URL: \(socketURL)")
                return
            }

            webSocketTask = urlSession.webSocketTask(with: url)
            webSocketTask?.resume()
            print("📡 WebSocket 연결 시도: \(socketURL)")
            listen()
            sendInitialJSON()
            startPing()
        }

        private func sendInitialJSON() {
            let jsonPayload: [String: Any] = [
                "uid": uid,
                "language": "ko",
                "task": "transcribe",
                "model": modelSize,
                "use_vad": true,
                "max_clients": 4,
                "max_connection_time": 600
            ]

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonPayload, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                print("📱 통신 JSON: \(jsonString)")

                webSocketTask?.send(.string(jsonString)) { [weak self] error in
                    if let error = error {
                        print("❌ JSON 전송 실패: \(error.localizedDescription)")
                        self?.reconnect()
                    } else {
                        print("✅ JSON 전송 성공")
                    }
                }
            } catch {
                print("❌ JSON 직렬화 실패: \(error.localizedDescription)")
            }
        }

        func sendDataToServer(_ data: Data) {
            guard isConnected else {
                print("⚠️ 연결 안 됨 - 데이터 전송 생략")
                reconnect()
                return
            }

            webSocketTask?.send(.data(data)) { [weak self] error in
                if let error = error {
                    print("❌ 전송 실패: \(error.localizedDescription)")
                    self?.reconnect()
                } else {
                    print("📀 파일 전송 성공: \(data.count) bytes")
                }
            }
        }

        internal var isConnected: Bool {
            webSocketTask?.state == .running
        }

        private func reconnect() {
            retryCount += 1
            stopPing()
            let delay = min(5.0, pow(2.0, Double(retryCount)))

            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                print("🚪 재연결 시도 (\(self?.retryCount ?? 0)/\(self?.maxRetries ?? 0))")
                self?.connect()
            }
        }

        private func listen() {
            webSocketTask?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                    self?.listen()
                case .failure(let error):
                    print("❌ 수신 오류: \(error.localizedDescription)")
                    self?.reconnect()
                }
            }
        }

        private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
            switch message {
            case .data(let data):
                print("📂 서버 받은 바이너리: \(data.count) bytes")

            case .string(let text):
                print("💬 서버 받은 텍스트: \(text)")

                guard let data = text.data(using: .utf8) else { return }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let status = json["status"] as? String {
                            handleStatusMessage(status: status, message: json["message"] as? String)
                            return
                        }

                        if let message = json["message"] as? String, message == "SERVER_READY" {
                            print("✅ 서버 준비 완료")
                            onServerReady?()
                            return
                        }

                        if let segments = json["segments"] as? [[String: Any]] {
                            do {
                                let segmentJson: [String: Any] = ["segments": segments]
                                let data = try JSONSerialization.data(withJSONObject: segmentJson, options: [])
                                let jsonString = String(data: data, encoding: .utf8)!
                                onTranscriptionReceived?(jsonString) // ✅ 전체 JSON 전달
                                print("텍스트 전달: \(jsonString)")
                            } catch {
                                print("❌ segments JSON 직렬화 실패: \(error.localizedDescription)")
                            }
                        }
                    }
                } catch {
                    print("❌ JSON 파싱 오류: \(error.localizedDescription)")
                }

            @unknown default:
                print("❓ 알 수 없는 메시지")
            }
        }

        private func handleStatusMessage(status: String, message: String?) {
            switch status {
            case "WAIT":
                print("⏳ 대기 중: \(message ?? "")")
            case "ERROR":
                print("❌ 오류: \(message ?? "")")
            case "WARNING":
                print("⚠️ 경고: \(message ?? "")")
            default:
                print("ℹ️ \(status): \(message ?? "")")
            }
        }

        func sendEndOfAudio() {
            guard isConnected else {
                print("⚠️ WebSocket 연결 안 됨 - 종료 전송 생략")
                return
            }

            webSocketTask?.send(.string("END_OF_AUDIO")) { error in
                if let error = error {
                    print("❌ End Of Audio 전송 실패: \(error.localizedDescription)")
                } else {
                    print("✅ End Of Audio 전송 완료")
                }
            }
        }


        func closeConnection() {
            stopPing()
            webSocketTask?.cancel(with: .normalClosure, reason: nil)
            retryCount = maxRetries
            print("📤 WebSocket 종료 요청 완료")
        }

        private func startPing() {
            stopPing()
            pingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
                self?.webSocketTask?.sendPing { error in
                    if let error = error {
                        print("❌ Ping 전송 실패: \(error.localizedDescription)")
                    } else {
                        print("📱 Ping 전송 성공")
                    }
                }
            }
            RunLoop.main.add(pingTimer!, forMode: .common)
        }

        private func stopPing() {
            pingTimer?.invalidate()
            pingTimer = nil
        }

        func urlSession(_ session: URLSession,
                        webSocketTask: URLSessionWebSocketTask,
                        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                        reason: Data?) {
            print("📴 WebSocket 닫힘 - 코드: \(closeCode.rawValue), 이유: \(String(data: reason ?? Data(), encoding: .utf8) ?? "없음")")
            stopPing()
            reconnect()
        }
    }
