//
//  QuizView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/26/25.
//

import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @State private var showCreateQuizSheet = false
    @State private var isDeckPresented = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // ✅ 기존 UI 구성 그대로
                HStack {
                    Spacer()
                    Button(action:{showCreateQuizSheet = true}, label: {
                        Text("➕ 퀴즈 생성")
                            .font(Font.Pretend.pretendardBold(size: 18))
                            .foregroundColor(.black)
                    })
                    .padding(.trailing)
                }

                if viewModel.quizzes.isEmpty {
                    Spacer()
                    Text("퀴즈가 없습니다.")
                    Spacer()
                } else {
                    List(viewModel.quizzes, id: \.id) { quiz in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(quiz.title)
                                .font(.headline)
                            
                            Text(quiz.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Button(action: {
                                    viewModel.fetchQuizDetail(id: quiz.id, useForSheet: true) {}
                                }) {
                                    Text("정보 보기")
                                        .font(Font.Pretend.pretendardMedium(size: 14))
                                }
                                
                                Spacer()
                                
                                Button("퀴즈 풀기") {
                                    viewModel.fetchQuizDetail(id: quiz.id, useForSheet: false) {
                                        viewModel.startQuizSession(quizId: quiz.id) { success in
                                            if success {
                                                isDeckPresented = true
                                            } else {
                                                print("❌ 세션 시작 실패")
                                            }
                                        }
                                    }
                                }
                                .font(Font.Pretend.pretendardMedium(size: 16))
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.top)

            // ✅ 전체화면 로딩 오버레이
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("로딩 중...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchAllQuizzes()
            if viewModel.courses.isEmpty {
                viewModel.fetchCourses()
            }
        }
        .sheet(isPresented: $showCreateQuizSheet) {
            CreateQuizSheetView(viewModel: viewModel)
        }
        .sheet(item: $viewModel.selectedQuizDetailForSheet) { detail in
            QuizDetailSheet(detail: detail, viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $isDeckPresented) {
            QuizDeckViewWrapper(viewModel: viewModel, isPresented: $isDeckPresented)
        }
    }
}
