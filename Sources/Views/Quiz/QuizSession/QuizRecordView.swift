//
//  QuizRecordView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/27/25.
//

import SwiftUI

struct QuizRecordView: View {
    @StateObject private var viewModel = QuizRecordViewModel()
    @State private var showQuizDeck = false
    @State private var cardVM = QuizCardViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sessions) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.quizTitle)
                            .font(.headline)
                        HStack {
                        Text("시작 시간: \(session.startedAt ?? "시간 정보 없음")")
                            .font(.caption)
                            .foregroundColor(.gray)
                            
                            Spacer()
                        
                            if session.completed {
                                Button("기록 보기") {
                                    viewModel.fetchSessionDetail(sessionId: session.id)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.black)
                                .foregroundColor(.white)
                                
                            } else {
                                Button("이어서 풀기") {
                                    handleResumeSession(for: session)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("퀴즈 기록")
            .onAppear {
                viewModel.fetchQuizSessions()
            }
            .sheet(item: $viewModel.selectedSessionDetail) { detail in
                QuizSessionDetailSheet(detail: detail)
            }
            .fullScreenCover(isPresented: $showQuizDeck, onDismiss: {
                DispatchQueue.main.async {
                    viewModel.fetchQuizSessions()
                }
            }) {
                QuizDeckView(viewModel: cardVM, isPresented: $showQuizDeck)
            }
        }
    }

    // MARK: - 이어서 풀기 로직 분리
    private func handleResumeSession(for session: QuizSessionSummary) {
        viewModel.fetchSessionDetail(sessionId: session.id, useForSheet: false) {
            guard let current = viewModel.selectedQuizDetailForSession?.currentQuestion else {
                print("❌ currentQuestion 없음")
                return
            }
            
            cardVM = QuizCardViewModel(cards: [
                QuizCard(question: current.front, answer: current.back)
            ])
            
            cardVM.onAnswer = handleAnswer(sessionId: session.id)
            
            
            showQuizDeck = true
            
            cardVM.onAllAnswered = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    viewModel.completeQuizSession()
                    showQuizDeck = false
                }
            }
        }
    }


    // MARK: - 답변 처리 로직 분리
    private func handleAnswer(sessionId: Int) -> (Int, Bool) -> Void {
        return { index, isCorrect in
            viewModel.sendAnswer(answer: isCorrect ? "O" : "X") {
                viewModel.fetchSessionDetail(sessionId: sessionId, useForSheet: false) {
                    if let next = viewModel.selectedQuizDetailForSession?.currentQuestion {
                        cardVM.cards = [
                            QuizCard(question: next.front, answer: next.back)
                        ]
                        
                    }

                }
            }
        
        }
    }
}





// MARK: - QuizSessionSummary 프리뷰용 더미 모델
let sampleSessions: [QuizSessionSummary] = [
    QuizSessionSummary(id: 1, quizTitle: "Swift 기초 퀴즈", completed: true, startedAt: "2025-05-25 14:30"),
    QuizSessionSummary(id: 2, quizTitle: "iOS 아키텍처", completed: false, startedAt: "2025-05-26 10:00")
]

let sampleDetail = QuizSessionDetailResponse(
    id: 1,
    quizId: 101,
    quizTitle: "Swift 기초 퀴즈",
    quizDescription: "Swift와 SwiftUI에 대한 기초 개념 퀴즈입니다.",
    totalQuestions: 2,
    currentQuestionIndex: 1,
    currentQuestion: QuizSessionQuestion(
        id: 2,
        weekId: 10,
        front: "SwiftUI에서 상태값을 관리하는 속성 래퍼는?",
        back: "@State를 사용하여 상태 관리를 수행합니다."
    ),
    completed: false,
    score: nil,
    totalQuestionsAnswered: 1,
    totalCorrectAnswers: 1,
    userAnswers: [
        UserAnswer(
            id: 1,
            questionId: 1,
            questionFront: "Swift의 옵셔널 바인딩 키워드는?",
            userAnswer: "if let",
            correctAnswer: "if let",
            isCorrect: true,
            answeredAt: "2025-05-28T12:34:56"
        )
    ],
    createdAt: "2025-05-28T12:30:00",
    completedAt: nil
)

// MARK: - QuizRecordView 프리뷰
#Preview {
    QuizRecordView()
}

// MARK: - QuizSessionDetailSheet 프리뷰
#Preview {
    QuizSessionDetailSheet(detail: sampleDetail)
}


