import Foundation
import AVFoundation

class Utils {
    
    /// 화면을 지웁니다 (콘솔에서 작동)
    static func clearScreen() {
        #if os(macOS)
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        #else
        // iOS에서는 콘솔 화면을 지우는 기능이 제한적이므로 빈 줄 여러 개 출력
        for _ in 0..<50 {
            print("")
        }
        #endif
    }
    
    /// 트랜스크립션 텍스트를 포맷팅하여 출력합니다
    static func printTranscript(_ text: [String]) {
        let joinedText = text.joined(separator: " ")
        let width = 60
        
        var currentLine = ""
        for word in joinedText.split(separator: " ") {
            if currentLine.count + word.count + 1 <= width {
                if !currentLine.isEmpty {
                    currentLine += " "
                }
                currentLine += word
            } else {
                print(currentLine)
                currentLine = String(word)
            }
        }
        
        if !currentLine.isEmpty {
            print(currentLine)
        }
    }
    
    /// 초(float)를 SRT 시간 형식으로 변환합니다
    static func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((seconds - Double(Int(seconds))) * 1000)
        
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, milliseconds)
    }
    
    /// SRT 파일을 생성합니다
    static func createSrtFile(segments: [[String: Any]], outputPath: String) {
        var srtContent = ""
        var segmentNumber = 1
        
        for segment in segments {
            guard let start = Double(segment["start"] as? String ?? "0"),
                  let end = Double(segment["end"] as? String ?? "0"),
                  let text = segment["text"] as? String else {
                continue
            }
            
            let startTime = formatTime(start)
            let endTime = formatTime(end)
            
            srtContent += "\(segmentNumber)\n"
            srtContent += "\(startTime) --> \(endTime)\n"
            srtContent += "\(text)\n\n"
            
            segmentNumber += 1
        }
        
        do {
            try srtContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("[INFO]: SRT file written to \(outputPath)")
        } catch {
            print("[ERROR]: Failed to write SRT file: \(error)")
        }
    }
    
    /// 오디오 파일을 16kHz로 리샘플링합니다
    static func resample(file: String, sampleRate: Int = 16000) -> String {
        let fileURL = URL(fileURLWithPath: file)
        let fileExtension = fileURL.pathExtension
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let outputFileName = "\(fileName)_resampled.wav"
        let outputURL = fileURL.deletingLastPathComponent().appendingPathComponent(outputFileName)
        
        do {
            // 소스 오디오 파일 읽기
            let audioFile = try AVAudioFile(forReading: fileURL)
            let sourceFormat = audioFile.processingFormat
            
            // 소스 오디오 데이터를 버퍼로 로드
            let frameCount = UInt32(audioFile.length)
            let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount)!
            try audioFile.read(into: sourceBuffer)
            
            // 대상 오디오 포맷 설정 (16kHz, mono, 16-bit PCM)
            let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                           sampleRate: Double(sampleRate),
                                           channels: 1,
                                           interleaved: true)!
            
            // 컨버터 생성 및 변환
            let converter = AVAudioConverter(from: sourceFormat, to: targetFormat)!
            let targetBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                             frameCapacity: AVAudioFrameCount(Double(frameCount) * Double(sampleRate) / sourceFormat.sampleRate))!
            
            var error: NSError? = nil
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return sourceBuffer
            }
            
            converter.convert(to: targetBuffer, error: &error, withInputFrom: inputBlock)
            
            if let error = error {
                print("[ERROR]: Failed to convert audio: \(error)")
                return file
            }
            
            // 결과 버퍼를 파일로 저장
            let outputFile = try AVAudioFile(forWriting: outputURL,
                                           settings: targetFormat.settings,
                                           commonFormat: targetFormat.commonFormat,
                                           interleaved: targetFormat.isInterleaved)
            try outputFile.write(from: targetBuffer)
            
            print("[INFO]: Audio resampled to \(outputURL.path)")
            return outputURL.path
            
        } catch {
            print("[ERROR]: Failed to resample audio: \(error)")
            return file
        }
    }
}