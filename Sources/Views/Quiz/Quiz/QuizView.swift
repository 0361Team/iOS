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
        VStack(spacing: 16) {
            
            
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
                ProgressView("퀴즈를 불러오는 중...")
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
                            // 정보 보기
                            Button("정보 보기") {
                                viewModel.fetchQuizDetail(id: quiz.id, useForSheet: true) { }
                            }
                            
                            Spacer()
                            
                            // 퀴즈 풀기
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
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.vertical, 6)
                }
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
