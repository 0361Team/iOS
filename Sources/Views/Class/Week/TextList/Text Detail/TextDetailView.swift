//
//  TextDetailView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/25/25.
//


import SwiftUI

struct TextDetailView: View {
    @Namespace private var animation
    @StateObject private var viewModel: TextViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false

    init(text: String, sumary: String? = nil, id: Int) {
        _viewModel = StateObject(wrappedValue: TextViewModel(text: text, sumary: sumary, id: id))
    }

    var body: some View {
        VStack(spacing: 0) {
            TextDetailTabView(viewModel: viewModel)

            Group {
                switch viewModel.selectedTab {
                case .script:
                    ScrollView {
                        Text(viewModel.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                case .sumary:
                    if let summary = viewModel.sumary {
                        ScrollView {
                            Text(summary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        ProgressView("요약 불러오는 중...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                case .keyword:
                    if let keywords = viewModel.keywords {
                        if keywords.isEmpty {
                            Text("키워드 없음")
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(keywords, id: \.self) { keyword in
                                    Text("• \(keyword)")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        ProgressView("키워드 불러오는 중...")
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("텍스트 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.isShowingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                }
                .foregroundColor(.black)
            }
        }
        .sheet(isPresented: $viewModel.isShowingActionSheet) {
            CustomTextActionSheet(
                onEdit: {
                    viewModel.isShowingActionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isEditing = true
                    }
                },
                onDelete: {
                    viewModel.deleteText {
                        dismiss()
                    }
                },
                onCancel: {
                    viewModel.isShowingActionSheet = false
                }
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isEditing) {
            EditTextView(
                originalText: viewModel.text,
                textId: viewModel.id,
                originalType: "String",
                onEditCompleted: {
                    viewModel.refreshText()
                }
            )
        }
    }
}




#Preview {
    TextDetailView(
        text: "이것은 대본입니다. 강의 내용을 여기에 입력하세요.",
        sumary: "이것은 요약입니다. 핵심 내용을 간략히 정리한 내용입니다.",
        id: 1
    )
}




#Preview {
    TextDetailView(
        text: "이것은 대본입니다. 강의 내용을 여기에 입력하세요.",
        sumary: "이것은 요약입니다. 핵심 내용을 간략히 정리한 내용입니다.",
        id: 1
    )
}
