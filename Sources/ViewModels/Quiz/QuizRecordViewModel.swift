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

    private let quizProvider = MoyaProvider<QuizAPI>()
    private let userId = 1

    // 전체 세션 조회
    func fetchQuizSessions() {
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
        }
    }

    // 세션 상세 조회
    func fetchSessionDetail(sessionId: Int, useForSheet: Bool = true, completion: (() -> Void)? = nil) {
        quizProvider.request(.getQuizSessionDetail(sessionId: sessionId)) { [weak self] result in
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
                        completion?()
                    }
                } catch {
                    print("❌ 세션 디코딩 실패: \(error)")
                    completion?()
                }
            case .failure(let error):
                print("❌ 세션 요청 실패: \(error)")
                completion?()
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

        quizProvider.request(.answerQuizSession(sessionId: sessionId, userAnswer: answer)) { result in
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
    func completeQuizSession() {
        guard let sessionId = currentSessionId else { return }
        quizProvider.request(.completeQuizSession(sessionId: sessionId)) { result in
            if case let .failure(error) = result {
                print("❌ 세션 완료 실패: \(error)")
            }
            print("✅ 퀴즈 세션 완료")
        }
    }
}
