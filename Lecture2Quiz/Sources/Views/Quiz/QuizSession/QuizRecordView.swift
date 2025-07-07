//  QuizRecordView.swift
//  Lecture2Quiz

import SwiftUI

struct QuizRecordView: View {
    @State private var showQuizDeck = false
    @State private var isDeckReady = false
    @State private var cardVM = QuizCardViewModel()
    @State private var isAnswerSubmitting = false
    @State private var selectedSessionIds: Set<Int> = []
    @State private var isDeleteMode = false

    @StateObject private var viewModel = QuizRecordViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("세션을 불러오는 중입니다...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            Button(isDeleteMode ? "삭제 취소" : "삭제") {
                                isDeleteMode.toggle()
                                if !isDeleteMode {
                                    selectedSessionIds.removeAll()
                                }
                            }
                            .foregroundColor(.red)
                            .font(Font.Pretend.pretendardMedium(size: 16))
                            .padding()
                        }

                        List {
                            ForEach(viewModel.sessions) { session in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        if isDeleteMode {
                                            Button(action: {
                                                if selectedSessionIds.contains(session.id) {
                                                    selectedSessionIds.remove(session.id)
                                                } else {
                                                    selectedSessionIds.insert(session.id)
                                                }
                                            }) {
                                                Image(systemName: selectedSessionIds.contains(session.id) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        Text(session.quizTitle)
                                            .font(.headline)
                                    }
                                    HStack {
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
                                            .tint(.blue)
                                            .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }

                        if isDeleteMode && !selectedSessionIds.isEmpty {
                            Button(action: {
                                viewModel.isDeleting = true
                                viewModel.deleteQuizSessions(sessionIds: Array(selectedSessionIds)) {
                                    selectedSessionIds.removeAll()
                                    isDeleteMode = false
                                    viewModel.isDeleting = false
                                }
                            }) {
                                if viewModel.isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("선택한 세션 삭제")
                                        .font(Font.Pretend.pretendardSemiBold(size: 16))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                }

                if isAnswerSubmitting {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("답변 저장 중...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
            }
            .onAppear {
                viewModel.isLoading = true
                viewModel.fetchQuizSessions {
                    viewModel.isLoading = false
                }
            }
            .sheet(item: $viewModel.selectedSessionDetail) { detail in
                QuizSessionDetailSheet(detail: detail)
            }
            .fullScreenCover(isPresented: Binding(
                get: { showQuizDeck && isDeckReady },
                set: { if !$0 { showQuizDeck = false; isDeckReady = false } }
            ), onDismiss: {
                viewModel.isLoading = true
                viewModel.fetchQuizSessions {
                    viewModel.isLoading = false
                }
            }) {
                QuizDeckView(viewModel: cardVM, isPresented: $showQuizDeck)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isAnswerSubmitting = false
                        }
                    }
            }
        }
    }

    private func handleResumeSession(for session: QuizSessionSummary) {
        viewModel.isLoading = true
        viewModel.fetchSessionDetail(sessionId: session.id, useForSheet: false) { detail in
            guard let detail = detail else {
                print(" 세션 정보 없음")
                viewModel.isLoading = false
                return
            }
            if detail.completed {
                print(" 이미 완료된 세션입니다.")
                viewModel.isLoading = false
                return
            }
            viewModel.fetchQuizDetailAndResume(quizId: detail.quizId, fromIndex: detail.currentQuestionIndex) { cards in
                DispatchQueue.main.async {
                    if cards.isEmpty {
                        print(" 남은 카드 없음")
                        viewModel.isLoading = false
                        return
                    }
                    cardVM = QuizCardViewModel(cards: cards)
                    cardVM.onAnswer = handleAnswer(sessionId: session.id)
                    cardVM.onAllAnswered = handleAllAnswered()
                    showQuizDeck = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isDeckReady = true
                    }
                }
            }
        }
    }

    private func handleAnswer(sessionId: Int) -> (Int, Bool) -> Void {
        return { index, isCorrect in
            isAnswerSubmitting = true
            viewModel.sendAnswer(answer: isCorrect ? "O" : "X") {
                fetchSessionDetailWithRetry(sessionId: sessionId) {
                    guard let sessionDetail = viewModel.selectedQuizDetailForSession else {
                        print(" 세션 상세 없음")
                        isAnswerSubmitting = false
                        return
                    }
                    if sessionDetail.completed {
                        DispatchQueue.global().async {
                            while viewModel.pendingAnswerCount > 0 {
                                usleep(100_000)
                            }
                            DispatchQueue.main.async {
                                viewModel.completeQuizSession {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isAnswerSubmitting = false
                                        showQuizDeck = false
                                    }
                                }
                            }
                        }
                        return
                    }
                    if let next = sessionDetail.currentQuestion {
                        cardVM = QuizCardViewModel(cards: [
                            QuizCard(question: next.front, answer: next.back)
                        ])
                        cardVM.onAnswer = handleAnswer(sessionId: sessionId)
                        cardVM.onAllAnswered = handleAllAnswered()
                    } else {
                        print("문제 없음, 세션 완료 유무: \(sessionDetail.completed)")
                        isAnswerSubmitting = false
                    }
                }
            }
        }
    }

    private func fetchSessionDetailWithRetry(sessionId: Int, retry: Int = 0, maxRetry: Int = 3, delay: Double = 0.3, completion: @escaping () -> Void) {
        viewModel.fetchSessionDetail(sessionId: sessionId, useForSheet: false) { _ in
            guard let detail = viewModel.selectedQuizDetailForSession else {
                print(" 세션 상세 없음")
                completion()
                return
            }
            if detail.currentQuestion == nil && !detail.completed && retry < maxRetry {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    fetchSessionDetailWithRetry(sessionId: sessionId, retry: retry + 1, completion: completion)
                }
            } else {
                completion()
            }
        }
    }

    private func handleAllAnswered() -> () -> Void {
        return {
            print(" onAllAnswered 추출됨")
            isAnswerSubmitting = true
            DispatchQueue.global().async {
                let start = Date()
                while viewModel.pendingAnswerCount > 0 {
                    if Date().timeIntervalSince(start) > 5 {
                        print("⛔️ 5초 초과 응답 대기, 강제 종료")
                        break
                    }
                    usleep(100_000)
                }
                DispatchQueue.main.async {
                    print(" 세션 종료 시도")
                    viewModel.completeQuizSession {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print(" 세션 종료 완료, 데크 닫기")
                            isAnswerSubmitting = false
                            showQuizDeck = false
                            viewModel.isLoading = true
                            viewModel.fetchQuizSessions {
                                viewModel.isLoading = false
                            }
                        }
                    }
                }
            }
        }
    }
}
