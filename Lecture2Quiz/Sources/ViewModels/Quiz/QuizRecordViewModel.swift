//
//  QuizRecordViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/28/25.
//

// QuizRecordViewModel.swift
import Foundation
import Moya

class QuizRecordViewModel: ObservableObject {
    
    @Published var sessions: [QuizSessionSummary] = []
    @Published var selectedSessionDetail: QuizSessionDetailResponse? = nil
    @Published var selectedQuizDetailForSession: QuizSessionDetailResponse? = nil
    @Published var currentSessionId: Int? = nil
    @Published var isLoading: Bool = false
    @Published var isDeleting: Bool = false
    @Published var pendingAnswerCount = 0

    private let quizProvider = MoyaProvider<QuizAPI>()
    private let userId = Int(KeychainHelper.shared.read(forKey: "userId")!)!

    // 전체 세션 조회
    func fetchQuizSessions(completion: (() -> Void)? = nil) {
        quizProvider.request(.getUserQuizSessions(userId: userId)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    self?.sessions = try JSONDecoder().decode([QuizSessionSummary].self, from: response.data)
                } catch {
                    print("❌ 세션 목록 디코딩 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 세션 목록 조회 실패: \(error)")
            }
            completion?()  // ✅ 콜백 호출
        }
    }

    // 세션 상세 조회
    func fetchSessionDetail(
        sessionId: Int,
        useForSheet: Bool = true,
        completion: ((QuizSessionDetailResponse?) -> Void)? = nil
    ) {
        isLoading = true
        quizProvider.request(.getQuizSessionDetail(sessionId: sessionId)) { [weak self] result in
            defer { self?.isLoading = false }
            switch result {
            case .success(let response):
                do {
                    let detail = try JSONDecoder().decode(QuizSessionDetailResponse.self, from: response.data)
                    DispatchQueue.main.async {
                        if useForSheet {
                            self?.selectedSessionDetail = detail
                        } else {
                            self?.selectedQuizDetailForSession = detail
                        }
                        self?.currentSessionId = detail.id

                        // ✅ 디코딩된 detail을 넘김
                        completion?(detail)
                    }
                } catch {
                    print("❌ 세션 디코딩 실패: \(error)")
                    completion?(nil)
                }
            case .failure(let error):
                print("❌ 세션 요청 실패: \(error)")
                completion?(nil)
            }
        }
    }


    
    // 답변 전송
    func sendAnswer(answer: String, completion: (() -> Void)? = nil) {
        guard let sessionId = currentSessionId else {
            print("❌ 세션 ID 없음")
            completion?()
            return
        }

        pendingAnswerCount += 1
        print("⏳ pendingAnswerCount 증가 → \(pendingAnswerCount)")

        quizProvider.request(.answerQuizSession(sessionId: sessionId, userAnswer: answer)) { [weak self] result in
            self?.pendingAnswerCount -= 1
            print("✅ pendingAnswerCount 감소 → \(self?.pendingAnswerCount ?? -1)")

            switch result {
            case .success(let response):
                print("✅ 답변 전송 성공: \(response.statusCode)")
            case .failure(let error):
                print("❌ 답변 전송 실패: \(error)")
            }
            completion?()
        }
    }



    // 세션 종료
    func completeQuizSession(completion: (() -> Void)? = nil) {
        guard let sessionId = currentSessionId else {
            completion?()
            return
        }

        quizProvider.request(.completeQuizSession(sessionId: sessionId)) { result in
            if case let .failure(error) = result {
                print("❌ 세션 완료 실패: \(error)")
            } else {
                print("✅ 퀴즈 세션 완료")
            }
            completion?()
        }
    }
    
    // 이어서 풀기
    func fetchQuizDetailAndResume(quizId: Int, fromIndex: Int, completion: @escaping ([QuizCard]) -> Void) {
        quizProvider.request(.getQuizDetail(id: quizId)) { result in
            switch result {
            case .success(let response):
                do {
                    let detail = try JSONDecoder().decode(QuizDetailResponse.self, from: response.data)
                    let questions = detail.questions

                    // ⏩ currentQuestionIndex부터 남은 문제만 카드로 변환
                    let remainingCards = questions
                        .dropFirst(fromIndex)
                        .map { QuizCard(question: $0.front, answer: $0.back) }

                    completion(remainingCards)
                } catch {
                    print("❌ 퀴즈 상세 디코딩 실패: \(error)")
                    completion([])
                }

            case .failure(let error):
                print("❌ 퀴즈 상세 조회 실패: \(error)")
                completion([])
            }
        }
    }
    
    func deleteQuizSessions(sessionIds: [Int], completion: @escaping () -> Void) {
        
        quizProvider.request(.deleteQuizSessions(sessionIds: sessionIds)) { result in
            
            switch result {
            case .success(let response):
                do {
                    let result = try JSONDecoder().decode(QuizSessionDeleteResponse.self, from: response.data)
                    print("✅ 삭제 완료된 ID 목록:", result.deletedSessionIds)

                    DispatchQueue.main.async {
                        self.sessions.removeAll { session in
                            result.deletedSessionIds.contains(session.id)
                        }
                        completion()
                    }

                } catch {
                    print("❌ 응답 디코딩 실패:", error)
                    completion()
                }

            case .failure(let error):
                print("❌ 삭제 실패:", error)
                completion()
            }
        }
    }

    
    
}
