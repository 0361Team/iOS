import Foundation
import AVFoundation
import utils

class Client: NSObject, URLSessionWebSocketDelegate {
    /**
     * WebSocket 서버와의 통신을 처리하는 클라이언트 클래스.
     */
    
    // MARK: - 상수
    static let END_OF_AUDIO = "END_OF_AUDIO"
    static var INSTANCES: [String: Client] = [:]
    
    // MARK: - 프로퍼티
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var ws_thread: DispatchWorkItem?
    
    private(set) var recording = false
    private(set) var task = "transcribe"
    private(set) var uid: String
    private(set) var waiting = false
    private(set) var last_response_received: Date?
    private(set) var disconnect_if_no_response_for: TimeInterval = 15
    private(set) var language: String?
    private(set) var model: String
    private(set) var server_error = false
    private(set) var error_message: Error?
    private(set) var srt_file_path: String
    private(set) var use_vad: Bool
    private(set) var use_wss: Bool
    private(set) var last_segment: [String: Any]?
    private(set) var last_received_segment: String?
    private(set) var log_transcription: Bool
    private(set) var max_clients: Int
    private(set) var max_connection_time: Int
    private(set) var send_last_n_segments: Int
    private(set) var no_speech_thresh: Double
    private(set) var clip_audio: Bool
    private(set) var same_output_threshold: Int
    private(set) var server_backend: String?
    
    var transcript: [[String: Any]] = []
    var transcription_callback: ((_ text: String, _ segments: [[String: Any]]) -> Void)?
    
    // MARK: - 초기화
    init(
        host: String? = nil,
        port: Int? = nil,
        lang: String? = nil,
        translate: Bool = false,
        model: String = "small",
        srt_file_path: String = "output.srt",
        use_vad: Bool = true,
        use_wss: Bool = false,
        log_transcription: Bool = true,
        max_clients: Int = 4,
        max_connection_time: Int = 600,
        send_last_n_segments: Int = 10,
        no_speech_thresh: Double = 0.45,
        clip_audio: Bool = false,
        same_output_threshold: Int = 10,
        transcription_callback: ((_ text: String, _ segments: [[String: Any]]) -> Void)? = nil
    ) {
        self.uid = UUID().uuidString
        self.language = lang
        self.model = model
        self.srt_file_path = srt_file_path
        self.use_vad = use_vad
        self.use_wss = use_wss
        self.log_transcription = log_transcription
        self.max_clients = max_clients
        self.max_connection_time = max_connection_time
        self.send_last_n_segments = send_last_n_segments
        self.no_speech_thresh = no_speech_thresh
        self.clip_audio = clip_audio
        self.same_output_threshold = same_output_threshold
        self.transcription_callback = transcription_callback
        
        if translate {
            self.task = "translate"
        }
        
        super.init()
        
        if let host = host, let port = port {
            let socket_protocol = self.use_wss ? "wss" : "ws"
            let socket_url = "\(socket_protocol)://\(host):\(port)"
            
            if let url = URL(string: socket_url) {
                self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
                self.webSocketTask = urlSession.webSocketTask(with: url)
                
                Client.INSTANCES[self.uid] = self
                
                // WebSocket 연결 시작
                self.webSocketTask?.resume()
                self.setupReceiveMessage()
                print("[INFO]: * recording")
            } else {
                print("[ERROR]: Invalid URL: \(socket_url)")
            }
        } else {
            print("[ERROR]: No host or port specified.")
        }
    }
    
    // MARK: - WebSocket 메시지 수신 설정
    private func setupReceiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    do {
                        if let jsonData = text.data(using: .utf8),
                           let messageJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                            self.handle_message(messageJson)
                        }
                    } catch {
                        print("[ERROR]: Failed to parse JSON message: \(error)")
                    }
                case .data(let data):
                    print("[INFO]: Received binary data: \(data.count) bytes")
                @unknown default:
                    print("[ERROR]: Unknown message type")
                }
                // 계속해서 메시지 수신
                self.setupReceiveMessage()
            case .failure(let error):
                print("[ERROR]: WebSocket receive error: \(error)")
                if !self.server_error {
                    self.on_error(error: error)
                }
            }
        }
    }
    
    // MARK: - 서버 상태 메시지 처리
    func handle_status_messages(_ message_data: [String: Any]) {
        guard let status = message_data["status"] as? String else { return }
        
        if status == "WAIT" {
            self.waiting = true
            if let waitTime = message_data["message"] as? Double {
                print("[INFO]: Server is full. Estimated wait time \(Int(round(waitTime))) minutes.")
            }
        } else if status == "ERROR" {
            if let message = message_data["message"] as? String {
                print("Message from Server: \(message)")
            }
            self.server_error = true
        } else if status == "WARNING" {
            if let message = message_data["message"] as? String {
                print("Message from Server: \(message)")
            }
        }
    }
    
    // MARK: - 트랜스크립션 세그먼트 처리
    func process_segments(_ segments: [[String: Any]]) {
        var text: [String] = []
        
        for (i, seg) in segments.enumerated() {
            if let segText = seg["text"] as? String {
                if text.isEmpty || text.last != segText {
                    text.append(segText)
                    
                    if i == segments.count - 1, let completed = seg["completed"] as? Bool, !completed {
                        self.last_segment = seg
                    } else if let serverBackend = self.server_backend, 
                              serverBackend == "faster_whisper",
                              let completed = seg["completed"] as? Bool, completed,
                              (self.transcript.isEmpty || 
                               (let segStart = Double(seg["start"] as? String ?? "0"),
                                let lastEnd = Double(self.transcript.last?["end"] as? String ?? "0"),
                                segStart >= lastEnd)) {
                        self.transcript.append(seg)
                    }
                }
            }
        }
        
        // 마지막 수신된 세그먼트와 응답 시간 업데이트
        if let lastSegmentText = segments.last?["text"] as? String,
           self.last_received_segment != lastSegmentText {
            self.last_response_received = Date()
            self.last_received_segment = lastSegmentText
        }
        
        // 트랜스크립션 콜백 호출
        if let callback = transcription_callback {
            callback(text.joined(separator: " "), segments)
            return
        }
        
        // 로깅
        if self.log_transcription {
            // 간결성을 위해 마지막 3개 항목으로 제한
            let displayText = Array(text.suffix(3))
            Utils.clearScreen()
            Utils.printTranscript(displayText)
        }
    }
    
    // MARK: - 메시지 처리
    func handle_message(_ message: [String: Any]) {
        guard let messageUid = message["uid"] as? String, messageUid == self.uid else {
            print("[ERROR]: invalid client uid")
            return
        }
        
        if message["status"] != nil {
            self.handle_status_messages(message)
            return
        }
        
        if let messageText = message["message"] as? String {
            if messageText == "DISCONNECT" {
                print("[INFO]: Server disconnected due to overtime.")
                self.recording = false
            } else if messageText == "SERVER_READY" {
                self.last_response_received = Date()
                self.recording = true
                self.server_backend = message["backend"] as? String
                if let backend = self.server_backend {
                    print("[INFO]: Server Running with backend \(backend)")
                }
                return
            }
        }
        
        if message["language"] != nil {
            self.language = message["language"] as? String
            let langProb = message["language_prob"] as? Double
            if let lang = self.language, let prob = langProb {
                print("[INFO]: Server detected language \(lang) with probability \(prob)")
            }
            return
        }
        
        if let segments = message["segments"] as? [[String: Any]] {
            self.process_segments(segments)
        }
    }
    
    // MARK: - WebSocket 이벤트 처리
    func on_open() {
        print("[INFO]: Opened connection")
        let initialMessage: [String: Any] = [
            "uid": self.uid,
            "language": self.language as Any,
            "task": self.task,
            "model": self.model,
            "use_vad": self.use_vad,
            "max_clients": self.max_clients,
            "max_connection_time": self.max_connection_time,
            "send_last_n_segments": self.send_last_n_segments,
            "no_speech_thresh": self.no_speech_thresh,
            "clip_audio": self.clip_audio,
            "same_output_threshold": self.same_output_threshold
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: initialMessage)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                self.webSocketTask?.send(.string(jsonString)) { error in
                    if let error = error {
                        print("[ERROR]: Failed to send initial message: \(error)")
                    }
                }
            }
        } catch {
            print("[ERROR]: Failed to serialize JSON: \(error)")
        }
    }
    
    func on_error(error: Error) {
        print("[ERROR] WebSocket Error: \(error)")
        self.server_error = true
        self.error_message = error
    }
    
    func on_close(code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        var reasonStr = "No reason"
        if let reason = reason, let reasonText = String(data: reason, encoding: .utf8) {
            reasonStr = reasonText
        }
        print("[INFO]: Websocket connection closed: \(code.rawValue): \(reasonStr)")
        self.recording = false
        self.waiting = false
    }
    
    // MARK: - URLSessionWebSocketDelegate 메서드
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        on_open()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        on_close(code: closeCode, reason: reason)
    }
    
    // MARK: - 오디오 패킷 전송
    func send_packet_to_server(_ message: Data) {
        if !recording && !server_error && !waiting {
            print("[WARN]: Not sending packet because recording=\(recording), server_error=\(server_error), waiting=\(waiting)")
            return
        }
        
        webSocketTask?.send(.data(message)) { error in
            if let error = error {
                print("[ERROR]: Failed to send audio packet: \(error)")
            }
        }
    }
    
    // MARK: - WebSocket 연결 종료
    func close_websocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        print("[INFO]: Closed WebSocket connection")
    }
    
    // MARK: - 클라이언트 소켓 가져오기
    func get_client_socket() -> URLSessionWebSocketTask? {
        return webSocketTask
    }
    
    // MARK: - SRT 파일 작성
func write_srt_file(output_path: String = "output.srt") {
    guard let backend = self.server_backend, backend == "faster_whisper" else { return }
    
    if transcript.isEmpty, let lastSegment = self.last_segment {
        transcript.append(lastSegment)
    } else if let lastSegment = self.last_segment, 
              let lastText = transcript.last?["text"] as? String,
              let segmentText = lastSegment["text"] as? String,
              lastText != segmentText {
        transcript.append(lastSegment)
    }
    
    // Utils 클래스 사용
    Utils.createSrtFile(segments: transcript, outputPath: output_path)
    }
            
    // MARK: - 연결 종료 전 대기
    func wait_before_disconnect() {
        guard let lastResponse = last_response_received else { return }
        
        // Swift에서는 Python의 busy waiting 대신 다른 방식으로 구현
        let waitTime = disconnect_if_no_response_for - Date().timeIntervalSince(lastResponse)
        if waitTime > 0 {
            Thread.sleep(forTimeInterval: waitTime)
        }
    }
}

// MARK: - TranscriptionTeeClient 클래스
class TranscriptionTeeClient {
    /**
     * 하나 이상의 WebSocket 연결을 통해 오디오 녹음, 스트리밍 및 트랜스크립션 작업을 처리하는 클라이언트입니다.
     *
     * WebSocket 연결을 사용하여 오디오 트랜스크립션 작업을 위한 상위 레벨 클라이언트로 작동합니다.
     * 트랜스크립션을 위해 하나 이상의 서버에 오디오 데이터를 보내고 트랜스크립션된 텍스트 세그먼트를 받을 수 있습니다.
     */
    
    // MARK: - 프로퍼티
    let clients: [Client]
    let chunk: Int = 4096
    let channels: Int = 1
    let sampleRate: Int = 16000
    let recordSeconds: Int = 60000
    let saveOutputRecording: Bool
    let outputRecordingFilename: String
    let muteAudioPlayback: Bool
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var frames: Data = Data()
    
    // MARK: - 초기화
    init(clients: [Client], saveOutputRecording: Bool = false, outputRecordingFilename: String = "./output_recording.wav", muteAudioPlayback: Bool = false) {
        self.clients = clients
        if clients.isEmpty {
            fatalError("At least one client is required.")
        }
        
        self.saveOutputRecording = saveOutputRecording
        self.outputRecordingFilename = outputRecordingFilename
        self.muteAudioPlayback = muteAudioPlayback
        
        setupAudioEngine()
    }
    
    // MARK: - 오디오 엔진 설정
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("[WARN]: Unable to access microphone. \(error)")
        }
    }
    
    // MARK: - 트랜스크립션 시작
    func start(audio: String? = nil, rtspUrl: String? = nil, hlsUrl: String? = nil, saveFile: String? = nil) {
        // 소스가 최대 하나만 제공되었는지 검증
        let providedSources = [audio, rtspUrl, hlsUrl].compactMap { $0 }
        guard providedSources.count <= 1 else {
            print("[ERROR]: You must provide only one selected source")
            return
        }
        
        print("[INFO]: Waiting for server ready ...")
        
        // 모든 클라이언트가 준비될 때까지 대기
        var clientsReady = false
        while !clientsReady {
            clientsReady = true
            
            for client in clients {
                if !client.recording {
                    clientsReady = false
                    
                    if client.waiting || client.server_error {
                        closeAllClients()
                        return
                    }
                    
                    // 잠시 대기 후 다시 확인
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        }
        
        print("[INFO]: Server Ready!")
        
        if let hlsUrl = hlsUrl {
            processHLSStream(hlsUrl: hlsUrl, saveFile: saveFile)
        } else if let audio = audio {
            playFile(filename: audio)
        } else if let rtspUrl = rtspUrl {
            processRTSPStream(rtspUrl: rtspUrl)
        } else {
            record()
        }
    }
    
    // MARK: - 모든 클라이언트 닫기
    func closeAllClients() {
        for client in clients {
            client.close_websocket()
        }
    }
    
    // MARK: - 모든 클라이언트 SRT 파일 작성
    func writeAllClientsSRT() {
        for client in clients {
            client.write_srt_file(output_path: client.srt_file_path)
        }
    }
    
    // MARK: - 패킷 멀티캐스트
    func multicastPacket(_ packet: Data, unconditional: Bool = false) {
        for client in clients {
            if unconditional || client.recording {
                client.send_packet_to_server(packet)
            }
        }
    }
    
    // MARK: - 파일 재생
    func playFile(filename: String) {
        // 원본 오디오 파일 리샘플링 (Swift에서 구현 필요)
        let resampledFile = resampleAudio(filename: filename)
        
        do {
            guard let audioFileURL = URL(string: "file://\(resampledFile)") else {
                print("[ERROR]: Invalid file URL")
                return
            }
            
            let audioFile = try AVAudioFile(forReading: audioFileURL)
            let audioFormat = audioFile.processingFormat
            
            let audioEngine = AVAudioEngine()
            let playerNode = AVAudioPlayerNode()
            
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
            
            try audioEngine.start()
            playerNode.scheduleFile(audioFile, at: nil)
            
            // 오디오 파일을 버퍼로 읽어서 처리
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(chunk))!
            
            while true {
                do {
                    try audioFile.read(into: buffer)
                    
                    // 더 이상 읽을 프레임이 없으면 종료
                    if buffer.frameLength == 0 {
                        break
                    }
                    
                    // 16비트 PCM으로 변환
                    if let pcmData = convertBufferTo16BitPCM(buffer) {
                        // Float32로 변환
                        let floatData = convertPCMToFloat32(pcmData)
                        multicastPacket(floatData)
                    }
                    
                    // 재생 (muteAudioPlayback이 false인 경우)
                    if !muteAudioPlayback {
                        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                    }
                    
                    // 클라이언트가 녹음 중이 아니면 종료
                    if !clients.contains(where: { $0.recording }) {
                        break
                    }
                    
                } catch {
                    print("[ERROR]: Error reading audio file: \(error)")
                    break
                }
            }
            
            // 종료 처리
            for client in clients {
                client.wait_before_disconnect()
            }
            
            // 종료 신호 전송
            if let endMessage = Client.END_OF_AUDIO.data(using: .utf8) {
                multicastPacket(endMessage, unconditional: true)
            }
            
            writeAllClientsSRT()
            playerNode.stop()
            audioEngine.stop()
            closeAllClients()
            
        } catch {
            print("[ERROR]: Error processing audio file: \(error)")
            closeAllClients()
            writeAllClientsSRT()
        }
    }
    
    // MARK: - 오디오 리샘플링
    private func resampleAudio(filename: String) -> String {
        return Utils.resample(file: filename, sampleRate: sampleRate)
    }
    
    // MARK: - RTSP 스트림 처리
    func processRTSPStream(rtspUrl: String) {
        print("[INFO]: RTSP stream processing is not implemented in the Swift version")
        // Swift에서 RTSP 스트림 처리 구현 필요
        
        for client in clients {
            client.wait_before_disconnect()
        }
        
        if let endMessage = Client.END_OF_AUDIO.data(using: .utf8) {
            multicastPacket(endMessage, unconditional: true)
        }
        
        closeAllClients()
        writeAllClientsSRT()
        print("[INFO]: RTSP stream processing finished.")
    }
    
    // MARK: - HLS 스트림 처리
    func processHLSStream(hlsUrl: String, saveFile: String? = nil) {
        print("[INFO]: HLS stream processing is not implemented in the Swift version")
        // Swift에서 HLS 스트림 처리 구현 필요
        
        for client in clients {
            client.wait_before_disconnect()
        }
        
        if let endMessage = Client.END_OF_AUDIO.data(using: .utf8) {
            multicastPacket(endMessage, unconditional: true)
        }
        
        closeAllClients()
        writeAllClientsSRT()
        print("[INFO]: HLS stream processing finished.")
    }
    
    // MARK: - AV 스트림 처리
    private func processAVStream(container: Any, streamType: String, saveFile: String? = nil) {
        print("[INFO]: AV stream processing is not implemented in the Swift version")
        // Swift에서 AV 스트림 처리 구현 필요
    }
    
    // MARK: - 오디오 청크 저장
    private func saveChunk(nAudioFile: Int) {
        // Swift에서 오디오 청크 저장 구현 필요
        DispatchQueue.global().async {
            self.writeAudioFramesToFile(frames: self.frames, fileName: "chunks/\(nAudioFile).wav")
        }
    }
    
    // MARK: - 녹음 마무리
    private func finalizeRecording(nAudioFile: Int) {
        var nextAudioFileIndex = nAudioFile
        
        if saveOutputRecording && !frames.isEmpty {
            writeAudioFramesToFile(frames: frames, fileName: "chunks/\(nAudioFile).wav")
            nextAudioFileIndex += 1
        }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        closeAllClients()
        
        if saveOutputRecording {
            writeOutputRecording(nAudioFile: nextAudioFileIndex)
        }
        
        writeAllClientsSRT()
    }
    
    // MARK: - 녹음
    func record() {
        var nAudioFile = 0
        
        if saveOutputRecording {
            let fileManager = FileManager.default
            let chunksDir = "chunks"
            
            // 이전 chunks 디렉토리 삭제
            if fileManager.fileExists(atPath: chunksDir) {
                try? fileManager.removeItem(atPath: chunksDir)
            }
            
            // 새 chunks 디렉토리 생성
            try? fileManager.createDirectory(atPath: chunksDir, withIntermediateDirectories: true)
        }
        
        guard let audioEngine = audioEngine, let inputNode = inputNode else {
            print("[ERROR]: Audio engine not initialized")
            return
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        // 인터럽트 핸들러 설정
        var isInterrupted = false
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            if let userInfo = notification.userInfo,
               let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
               let type = AVAudioSession.InterruptionType(rawValue: typeValue) {
                
                if type == .began {
                    isInterrupted = true
                    self.finalizeRecording(nAudioFile: nAudioFile)
                }
            }
        }
        
        // 인풋 노드에 탭 설치
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(chunk), format: format) { [weak self] buffer, time in
            guard let self = self, !isInterrupted else { return }
            
            // 클라이언트가 녹음 중이 아니면 처리 중단
            if !self.clients.contains(where: { $0.recording }) {
                return
            }
            
            // 버퍼를 16비트 PCM Data로 변환
            if let pcmData = self.convertBufferToRawPCM(buffer) {
                // 프레임에 추가
                self.frames.append(pcmData)
                
                // Float32로 변환하여 전송
                let floatData = self.convertPCMToFloat32(pcmData)
                self.multicastPacket(floatData)
                
                // 1분 이상 녹음되면 청크 저장
                if self.frames.count > 60 * self.sampleRate * 2 { // 16비트(2바이트) PCM
                    if self.saveOutputRecording {
                        self.saveChunk(nAudioFile: nAudioFile)
                        nAudioFile += 1
                    }
                    self.frames = Data()
                }
            }
        }
        
        do {
            try audioEngine.start()
            print("[INFO]: AVAudioEngine started")
            
            // 녹음 지속 시간 설정 (타이머 대신 사용)
            let recordDuration = TimeInterval(recordSeconds / 1000) // 밀리초에서 초로 변환
            
            // 키보드 인터럽트 처리를 위한 메인 스레드 대기
            DispatchQueue.global().async {
                // 최대 녹음 시간 또는 클라이언트 녹음 종료까지 실행
                let startTime = Date()
                
                while Date().timeIntervalSince(startTime) < recordDuration && 
                      self.clients.contains(where: { $0.recording }) && 
                      !isInterrupted {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                // 녹음 종료 처리
                DispatchQueue.main.async {
                    self.finalizeRecording(nAudioFile: nAudioFile)
                }
            }
            
        } catch {
            print("[ERROR]: Could not start audio engine: \(error)")
        }
    }
    
    // MARK: - 오디오 프레임을 파일로 저장
    private func writeAudioFramesToFile(frames: Data, fileName: String) {
        do {
            let settings: [String: Any] = [
                AVNumberOfChannelsKey: channels,
                AVSampleRateKey: sampleRate,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            
            guard let url = URL(string: "file://\(fileName)") else {
                print("[ERROR]: Invalid file URL")
                return
            }
            
            try frames.write(to: url)
            print("[INFO]: Wrote audio frames to \(fileName)")
        } catch {
            print("[ERROR]: Failed to write audio frames: \(error)")
        }
    }
    
    // MARK: - 출력 녹음 파일 작성
    private func writeOutputRecording(nAudioFile: Int) {
        let fileManager = FileManager.default
        
        // 존재하는 청크 파일 경로 수집
        var inputFiles: [String] = []
        for i in 0..<nAudioFile {
            let filePath = "chunks/\(i).wav"
            if fileManager.fileExists(atPath: filePath) {
                inputFiles.append(filePath)
            }
        }
        
        // 청크 파일들을 하나의 WAV 파일로 결합
        do {
            // 여기서는 간단한 구현을 위해 첫 번째 청크 파일을 출력 파일로 복사하고, 나머지 청크의 데이터를 추가하는 방식 사용
            if let firstFile = inputFiles.first {
                try fileManager.copyItem(atPath: firstFile, toPath: outputRecordingFilename)
                
                // 나머지 청크 처리 (실제로는 WAV 파일 조작 라이브러리 필요)
                for file in inputFiles.dropFirst() {
                    // 파일 데이터 추가 로직 (생략)
                    print("[INFO]: Would append \(file) to output recording")
                    
                    // 처리 후 청크 파일 삭제
                    try fileManager.removeItem(atPath: file)
                }
            }
            
            // chunks 디렉토리 정리
            if fileManager.fileExists(atPath: "chunks") {
                try fileManager.removeItem(atPath: "chunks")
            }
            
            print("[INFO]: Output recording saved to \(outputRecordingFilename)")
        } catch {
            print("[ERROR]: Failed to write output recording: \(error)")
        }
    }
    
    // MARK: - AVAudioPCMBuffer를 Raw PCM 데이터로 변환
    private func convertBufferToRawPCM(_ buffer: AVAudioPCMBuffer) -> Data? {
        let format = buffer.format
        let frameCount = Int(buffer.frameLength)
        
        if format.commonFormat == .pcmFormatFloat32 {
            // Float32에서 Int16으로 변환
            guard let floatChannelData = buffer.floatChannelData else {
                return nil
            }
            
            let channelPointer = floatChannelData.pointee
            var pcmData = Data(capacity: frameCount * MemoryLayout<Int16>.size)
            
            for i in 0..<frameCount {
                let sample = max(-1.0, min(1.0, channelPointer[i])) // 클리핑 처리
                var intSample = Int16(sample * Float(Int16.max))
                pcmData.append(Data(bytes: &intSample, count: MemoryLayout<Int16>.size))
            }
            
            return pcmData
            
        } else if format.commonFormat == .pcmFormatInt16 {
            // 이미 Int16 형식인 경우 직접 변환
            guard let int16ChannelData = buffer.int16ChannelData else {
                return nil
            }
            
            let channelPointer = int16ChannelData.pointee
            let dataLength = frameCount * MemoryLayout<Int16>.size
            return Data(bytes: channelPointer, count: dataLength)
        }
        
        print("[ERROR]: Unsupported audio format: \(format.commonFormat)")
        return nil
    }
    
    // MARK: - 버퍼를 16비트 PCM으로 변환
    private func convertBufferTo16BitPCM(_ buffer: AVAudioPCMBuffer) -> Data? {
        // 버퍼 포맷 확인 및 적절한 변환 처리
        if buffer.format.commonFormat == .pcmFormatInt16 {
            guard let channelData = buffer.int16ChannelData else {
                print("int16ChannelData is nil")
                return nil
            }
            let channelPointer = channelData.pointee
            let dataLength = Int(buffer.frameLength) * MemoryLayout<Int16>.size
            return Data(bytes: channelPointer, count: dataLength)
        } else if buffer.format.commonFormat == .pcmFormatFloat32 {
            guard let floatChannelData = buffer.floatChannelData else {
                print("floatChannelData is nil")
                return nil
            }
            
            let channelPointer = floatChannelData.pointee
            let frameLength = Int(buffer.frameLength)
            var pcmData = Data(capacity: frameLength * MemoryLayout<Int16>.size)
            
            for i in 0..<frameLength {
                let sample = max(-1.0, min(1.0, channelPointer[i])) // 클리핑 처리
                var intSample = Int16(sample * Float(Int16.max))
                pcmData.append(Data(bytes: &intSample, count: MemoryLayout<Int16>.size))
            }
            
            return pcmData
        } else {
            print("예상치 못한 버퍼 포맷: \(buffer.format.commonFormat)")
            return nil
        }
    }
    
    // MARK: - 16비트 PCM을 Float32로 변환
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
}

// MARK: - TranscriptionClient 클래스
class TranscriptionClient: TranscriptionTeeClient {
    /**
     * 단일 WebSocket 연결을 통한 오디오 트랜스크립션 작업을 처리하는 클라이언트.
     *
     * WebSocket 연결을 사용하여 오디오 트랜스크립션 작업을 위한 상위 레벨 클라이언트로 작동합니다.
     * 서버에 오디오 데이터를 전송하고 트랜스크립션된 텍스트 세그먼트를 수신할 수 있습니다.
     */
    
    let client: Client
    
    init(
        host: String,
        port: Int,
        lang: String? = nil,
        translate: Bool = false,
        model: String = "small",
        use_vad: Bool = true,
        use_wss: Bool = false,
        save_output_recording: Bool = false,
        output_recording_filename: String = "./output_recording.wav",
        output_transcription_path: String = "./output.srt",
        log_transcription: Bool = true,
        max_clients: Int = 4,
        max_connection_time: Int = 600,
        mute_audio_playback: Bool = false,
        send_last_n_segments: Int = 10,
        no_speech_thresh: Double = 0.45,
        clip_audio: Bool = false,
        same_output_threshold: Int = 10,
        transcription_callback: ((_ text: String, _ segments: [[String: Any]]) -> Void)? = nil
    ) {
        // 기본 클라이언트 생성
        self.client = Client(
            host: host,
            port: port,
            lang: lang,
            translate: translate,
            model: model,
            srt_file_path: output_transcription_path,
            use_vad: use_vad,
            use_wss: use_wss,
            log_transcription: log_transcription,
            max_clients: max_clients,
            max_connection_time: max_connection_time,
            send_last_n_segments: send_last_n_segments,
            no_speech_thresh: no_speech_thresh,
            clip_audio: clip_audio,
            same_output_threshold: same_output_threshold,
            transcription_callback: transcription_callback
        )
        
        // 파일 이름 유효성 검사
        if save_output_recording && !output_recording_filename.hasSuffix(".wav") {
            fatalError("Please provide a valid `output_recording_filename`: \(output_recording_filename)")
        }
        if !output_transcription_path.hasSuffix(".srt") {
            fatalError("Please provide a valid `output_transcription_path`: \(output_transcription_path). The file extension should be `.srt`.")
        }
        
        // 부모 클래스 초기화
        super.init(
            clients: [client],
            saveOutputRecording: save_output_recording,
            outputRecordingFilename: output_recording_filename,
            muteAudioPlayback: mute_audio_playback
        )
    }
}