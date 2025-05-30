import SwiftUI

struct RecordingModal: View {
    var onDismiss: () -> Void
    @StateObject private var recordingViewModel = AudioViewModel()
    @GestureState private var dragOffset = CGSize.zero
    @State private var modalPosition: CGFloat = 0
    
    // 수업/주차 선택용 상태값
    @State private var showSubmitModal = false

    // 화면의 위치 설정
    private let midPosition: CGFloat = 0
    private let bottomPosition: CGFloat = UIScreen.main.bounds.height * 0.5

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 6)
                .padding(.top, 8)

            HStack {
                Spacer()
                if recordingViewModel.isRecording {
                    Button("녹음 종료") {
                        recordingViewModel.stopRecording()
                        recordingViewModel.finalizeTranscription()
                        showSubmitModal = true
                    }
                    .font(.headline)
                    .padding()
                    .foregroundColor(.gray)
                }
            }

            // ✅ 스크롤 가능한 텍스트 영역
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(recordingViewModel.transcriptionList.indices, id: \.self) { index in
                        Text(recordingViewModel.transcriptionList[index])
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }

            Divider()
                .padding(.top, 8)

            // ✅ 고정된 하단 컨트롤
            VStack(spacing: 16) {
                Text(recordingViewModel.timeLabel)
                    .font(.system(size: 40))

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
                }) {
                    Image(systemName: recordingViewModel.isRecording ?
                          (recordingViewModel.isPaused ? "play.circle.fill" : "pause.circle.fill") : "mic.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.black)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .offset(y: modalPosition + dragOffset.height)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation
                    }
                }
                .onEnded { value in
                    withAnimation {
                        if value.translation.height > 150 {
                            modalPosition = bottomPosition
                        } else {
                            modalPosition = midPosition
                        }
                    }
                }
        )
        .transition(.move(edge: .bottom))
        .animation(.easeOut, value: dragOffset)
        .onAppear {
            modalPosition = midPosition
        }
        .overlay(
            Group {
                if recordingViewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("처리 중입니다...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
            }
        )
        .sheet(isPresented: $showSubmitModal) {
            SubmitTranscriptView(finalContent: recordingViewModel.finalScript) {
                onDismiss()
            }
        }
    }
}

