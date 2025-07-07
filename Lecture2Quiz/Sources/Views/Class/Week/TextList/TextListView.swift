//
//  TextListView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/25/25.
//

import SwiftUI
import Moya

struct TextListView: View {
    let weekId: Int
    let courseTitle: String
    let weekTitle: String

    @StateObject private var viewModel: TextListViewModel
    @Environment(\.dismiss) private var dismiss

    init(weekId: Int, courseTitle: String, weekTitle: String, onDeleteSuccess: @escaping () -> Void) {
        self.weekId = weekId
        self.courseTitle = courseTitle
        self.weekTitle = weekTitle
        _viewModel = StateObject(wrappedValue: TextListViewModel(
            weekId: weekId,
            onDeleteSuccess: onDeleteSuccess
        ))
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                if viewModel.isLoading {
                    ProgressView("텍스트 불러오는 중...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.texts.isEmpty {
                    HStack {
                        Text(weekTitle)
                            .font(.title)
                            .bold()
                        Spacer()
                        Button {
                            viewModel.showActionSheet = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                                .foregroundColor(.primary)
                                .padding()
                        }
                    }
                    .padding()
                    Spacer()
                    Text("📭 텍스트가 없습니다.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 50)
                    Spacer()
                    
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack {
                                Text(weekTitle)
                                    .font(.title)
                                    .bold()
                                Spacer()
                                Button {
                                    viewModel.showActionSheet = true
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .rotationEffect(.degrees(90))
                                        .foregroundColor(.primary)
                                        .padding()
                                }
                            }
                            .padding(.top)

                            ForEach(viewModel.texts) { text in
                                NavigationLink {
                                    TextDetailView(
                                        text: text.content,
                                        sumary: text.summation,
                                        id: text.id,
                                        onDeleteSuccess: {
                                                    viewModel.fetchTexts()
                                        }
                                    )
                                } label: {
                                    HStack {
                                        Text("\(courseTitle) - \(weekTitle) - #\(text.id)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)

            if viewModel.isDeleting {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("주차 삭제 중...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .navigationTitle("텍스트 목록")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showActionSheet) {
            CustomCourseActionSheet(
                onDelete: {
                    viewModel.deleteWeek {
                        dismiss()
                    }
                },
                onCancel: {
                    viewModel.showActionSheet = false
                },
                actionStr: "주차 삭제"
            )
            .presentationDetents([.height(140)])
            .presentationDragIndicator(.visible)
            .padding(.top, 24)
        }
    }
}

let mockTexts: [WeekTextResponse] = [
    WeekTextResponse(id: 1, weekId: 10, content: "본문 1", summation: "요약 1"),
    WeekTextResponse(id: 2, weekId: 10, content: "본문 2", summation: "요약 2")
]

struct TextListPreviewWrapper: View {
    @StateObject private var viewModel = TextListViewModel(
        weekId: 10,
        onDeleteSuccess: {
            print("삭제됨 (Preview)")
        }
    )

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.texts) { text in
                            HStack {
                                Text("프로그래밍 언어 - 1주차 - #\(text.id)")
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("텍스트 목록")
            .onAppear {
                viewModel.texts = mockTexts // 강제 주입
                viewModel.isLoading = false
            }
        }
    }
}

#Preview {
    TextListPreviewWrapper()
}




