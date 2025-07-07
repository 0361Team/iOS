//
//  TextDetailView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/25/25.
//


import SwiftUI
import MarkdownUI

struct TextDetailView: View {
    @Namespace private var animation
    @StateObject private var viewModel: TextViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    var onDeleteSuccess: (() -> Void)? = nil
    
    init(text: String, sumary: String? = nil, id: Int, onDeleteSuccess: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: TextViewModel(text: text, sumary: sumary, id: id))
        self.onDeleteSuccess = onDeleteSuccess
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TextDetailTabView(viewModel: viewModel)

                Group {
                    switch viewModel.selectedTab {
                    case .script:
                        ScrollView {
                            Text(viewModel.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font.Pretend.pretendardMedium(size: 17))
                        }
                    case .sumary:
                        if let summary = viewModel.sumary {
                            ScrollView {
                                Markdown(viewModel.sumary ?? "")
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(Font.Pretend.pretendardMedium(size: 17))
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
                                    FlowLayout(data: keywords, spacing: 8) { keyword in
                                        Text(keyword)
                                            .font(Font.Pretend.pretendardMedium(size: 18))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
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

            // ✅ 삭제 중일 때 로딩 UI
            if viewModel.isDeleting {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("텍스트 삭제 중...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
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
                        onDeleteSuccess?()
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
