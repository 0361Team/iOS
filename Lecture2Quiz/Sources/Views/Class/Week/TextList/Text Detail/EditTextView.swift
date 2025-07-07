import SwiftUI
import Moya

struct EditTextView: View {
    let originalText: String
    let textId: Int
    let originalType: String
    var onEditCompleted: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var editedText: String
    @State private var isLoading = false

    private let provider = MoyaProvider<CourseAPI>()

    init(originalText: String, textId: Int, originalType: String, onEditCompleted: (() -> Void)? = nil) {
        self.originalText = originalText
        self.textId = textId
        self.originalType = originalType
        self.onEditCompleted = onEditCompleted
        _editedText = State(initialValue: originalText)
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $editedText)
                    .padding()
                    .frame(maxHeight: .infinity)

                if isLoading {
                    ProgressView("수정 중...")
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    Button("수정 완료") {
                        isLoading = true
                        provider.request(.updateText(textId: textId, content: editedText, type: originalType)) { result in
                            DispatchQueue.main.async {
                                isLoading = false
                                switch result {
                                case .success:
                                    onEditCompleted?()
                                    dismiss()
                                case .failure(let error):
                                    print("❌ 수정 실패: \(error)")
                                    // 오류 표시를 원한다면 Alert 처리도 가능
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
            .navigationTitle("텍스트 수정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
