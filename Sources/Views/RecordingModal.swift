//
//  RecordingModal.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/5/25.
//

import SwiftUI

struct RecordingModal: View {
    var onDismiss: () -> Void
    @StateObject var recordingViewModel = AudioViewModel()
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        VStack {
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
            
            HStack {
                Spacer()
                // 녹음 중이라면 Stop 버튼 추가
                if recordingViewModel.isRecording {
                    Button("녹음 종료") {
                        recordingViewModel.stopRecording()
                        onDismiss()
                    }
                    .font(.headline)
                    .padding()
                    .foregroundColor(.gray)
                }
            }

            Spacer()
            // 타임 레이블
            Text(recordingViewModel.timeLabel)
                .font(Font.Pretend.pretendardMedium(size: 40))
            
            // 녹음 시작/중단/재개 버튼
            Button(action: {
                if recordingViewModel.isRecording {
                    if recordingViewModel.isPaused {
                        recordingViewModel.resumeRecording()
                    } else {
                        recordingViewModel.pauseRecording()
                    }
                } else {
                    recordingViewModel.startRecording()
                }
            }, label: {
                Image(systemName: recordingViewModel.isRecording ?
                      (recordingViewModel.isPaused ? "play.circle.fill" : "pause.circle.fill") : "mic.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.black)
                    .padding(.bottom, 40)
            })
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .offset(y: dragOffset.height)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        onDismiss()
                    }
                }
        )
        .transition(.move(edge: .bottom))
        .animation(.easeOut, value: dragOffset)
    }
}



#Preview {
    var showRecordingModal = true
    RecordingModal {
        withAnimation {
            showRecordingModal = false
        }
    }
    .zIndex(1)
}
