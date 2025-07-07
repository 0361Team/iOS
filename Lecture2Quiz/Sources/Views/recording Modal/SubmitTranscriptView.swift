import SwiftUI
import Moya

struct SubmitTranscriptView: View {
    let finalContent: String
    var onSubmitCompleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SubmitTranscriptViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    // 수업 선택
                    Section(header: Text("수업 선택")) {
                        Picker("수업", selection: $viewModel.selectedCourseId) {
                            Text("수업을 선택하세요").tag(Optional<Int>(nil))
                            ForEach(viewModel.folders, id: \.id) { course in
                                Text(course.title).tag(Optional(course.id))
                            }
                        }
                    }

                    // 주차 선택
                    if let selectedCourse = viewModel.selectedCourse {
                        Section(header: Text("주차 선택")) {
                            Picker("주차", selection: $viewModel.selectedWeekId) {
                                Text("주차를 선택하세요").tag(Optional<Int>(nil))
                                ForEach(selectedCourse.weeks, id: \.id) { week in
                                    Text(week.title).tag(Optional(week.id))
                                }
                            }

                            Button("➕ 새 주차 추가") {
                                viewModel.showAddWeekAlert = true
                            }
                            .alert("새 주차 이름", isPresented: $viewModel.showAddWeekAlert) {
                                TextField("예: 3주차 - 반복문", text: $viewModel.newWeekTitle)
                                Button("추가") {
                                    viewModel.addWeek(to: selectedCourse) {
                                        viewModel.fetchFolders()
                                    }
                                }
                                Button("취소", role: .cancel) {}
                            }
                        }
                    }

                    // 저장 버튼
                    Button("저장하기") {
                        viewModel.submitTranscript(content: finalContent) { success in
                            if success {
                                dismiss()
                                onSubmitCompleted()
                            }
                        }
                    }
                    .disabled(viewModel.selectedWeekId == nil)
                }
                .blur(radius: viewModel.isLoading ? 3 : 0)
                .disabled(viewModel.isLoading)

                // 로딩 오버레이
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("처리 중입니다...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                        .shadow(radius: 10)
                }
            }
            .navigationTitle("녹음 저장")
            .onAppear {
                viewModel.fetchFolders()
            }
        }
    }
}

#Preview {
    SubmitTranscriptView(finalContent: "이것은 예시 녹음 내용입니다.") {
        print("✅ 전송 완료 후 동작")
    }
}
