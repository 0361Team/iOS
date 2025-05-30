//
//  QuizViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/26/25.
//

import Foundation
import Moya
import SwiftUI

class QuizViewModel: ObservableObject {
    @Published var selectedTab: QuizTopTab = .WeekQuestion

    // MARK: - 수업 및 주차
    @Published var courses: [CourseResponseByUserID] = []
    @Published var weeks: [WeekResponseByUserID] = []

    // MARK: - 퀴즈 목록 및 주차별 퀴즈 존재 여부
    @Published var quizzes: [QuizSummary] = []
    @Published var weekQuizExist: [Int: Bool] = [:]

    // MARK: - 퀴즈 세션용
    @Published var selectedQuizDetailForSheet: QuizDetailResponse?
    @Published var selectedQuizDetailForSession: QuizDetailResponse?

    @Published var currentSessionId: Int?
    @Published var quizCards: [QuizCard] = []

    // MARK: - 퀴즈 만들기용
    @Published var selectedCourseId: Int? = nil
    @Published var selectedWeekIds: Set<Int> = []
    // 해당 수업의 주차만 가져오는 computed property
    var filteredWeeks: [WeekResponseByUserID] {
        guard let courseId = selectedCourseId else { return [] }
        return weeks.filter { $0.courseId == courseId }
    }
    
    private let courseProvider = MoyaProvider<CourseAPI>()
    private let quizProvider = MoyaProvider<QuizAPI>()
    private let userId = 1


    // MARK: - 수업 목록 불러오기 (모든 수업의 주차 반영)
    func fetchCourses() {
        courseProvider.request(.getUserCourses(userId: userId)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let courses = try JSONDecoder().decode([CourseResponseByUserID].self, from: response.data)
                    DispatchQueue.main.async {
                        self?.courses = courses
                        let allWeeks = courses.flatMap { $0.weeks }
                        self?.weeks = allWeeks
                    }
                } catch {
                    print("❌ 수업 디코딩 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 수업 조회 실패: \(error)")
            }
        }
    }


    // MARK: - 퀴즈 전체 조회
    func fetchAllQuizzes() {
        quizProvider.request(.getQuizzes(userId: userId)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try JSONDecoder().decode([QuizSummary].self, from: response.data)
                    DispatchQueue.main.async {
                        self?.quizzes = decoded
                    }
                } catch {
                    print("❌ 퀴즈 디코딩 실패: \(error)")
                    print(String(data: response.data, encoding: .utf8) ?? "응답 디버깅 실패")
                }
            case .failure(let error):
                print("❌ 퀴즈 조회 실패: \(error)")
            }
        }
    }


    // MARK: - 퀴즈 상세 조회
    func fetchQuizDetail(id: Int, useForSheet: Bool, completion: @escaping () -> Void) {
        quizProvider.request(.getQuizDetail(id: id)) { [weak self] result in
            switch result {
            case .success(let response):
                print("📦 Raw Detail Response:", String(data: response.data, encoding: .utf8) ?? "N/A")
                do {
                    let detail = try JSONDecoder().decode(QuizDetailResponse.self, from: response.data)
                    DispatchQueue.main.async {
                        if useForSheet {
                            self?.selectedQuizDetailForSheet = detail
                        } else {
                            self?.selectedQuizDetailForSession = detail
                        }
                        completion()
                    }
                } catch {
                    print("❌ 상세 디코딩 실패: \(error)")
                    completion()
                }
            case .failure(let error):
                print("❌ 상세 요청 실패: \(error)")
                completion()
            }
        }
    }


    // MARK: - 퀴즈 세션 시작
    func startQuizSession(quizId: Int, completion: @escaping (Bool) -> Void) {
        quizProvider.request(.startQuizSession(quizId: quizId, userId: userId)) { [weak self] result in
            switch result {
            case .success(let response):
                let success = (200...299).contains(response.statusCode)
                guard success else {
                    print("❌ 퀴즈 세션 시작 실패: \(response.statusCode)")
                    print(String(data: response.data, encoding: .utf8) ?? "")
                    DispatchQueue.main.async {
                        self?.quizCards = []
                        completion(false)
                    }
                    return
                }

                do {
                    // ✅ 세션 ID만 파싱
                    let sessionId = try JSONDecoder().decode(Int.self, from: response.data)
                    self?.currentSessionId = sessionId
                    print("✅ 퀴즈 세션 시작 성공 (sessionId: \(sessionId))")

                    // ✅ 카드 생성을 위해 퀴즈 상세 요청
                    self?.fetchQuizDetail(id: quizId, useForSheet: false) {
                        let cards = self?.selectedQuizDetailForSession?.questions.map {
                            QuizCard(question: $0.front, answer: $0.back)
                        } ?? []

                        DispatchQueue.main.async {
                            self?.quizCards = cards
                            completion(true)
                        }
                    }

                } catch {
                    print("❌ 세션 응답 디코딩 실패: \(error)")
                    completion(false)
                }

            case .failure(let error):
                print("❌ 세션 요청 실패: \(error)")
                DispatchQueue.main.async {
                    self?.quizCards = []
                    completion(false)
                }
            }
        }
    }









    // MARK: - 카드 넘길 때 답변 전송
    func sendAnswer(answer: String, completion: (() -> Void)? = nil) {
        guard let sessionId = currentSessionId else { return }
        print("📤 답변 전송 시작 (sessionId: \(sessionId), answer: \(answer))")

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


    // MARK: - 세션 완료 처리
    func completeQuizSession() {
        guard let sessionId = currentSessionId else { return }
        quizProvider.request(.completeQuizSession(sessionId: sessionId)) { result in
            if case let .failure(error) = result {
                print("❌ 세션 완료 실패: \(error)")
            }
            print("퀴즈 세션 완료")
        }
    }

    // MARK: - 퀴즈 시작 + 카드 셋팅 + 뷰 전환 트리거
    func startQuizAndShowDeck(quizId: Int, quizCardViewModel: QuizCardViewModel, showDeck: Binding<Bool>) {
        startQuizSession(quizId: quizId) { [weak self] success in
            guard success, let self = self else { return }

            // 카드 셋업하고 덱 보여주기
            quizCardViewModel.cards = self.quizCards
            showDeck.wrappedValue = true
        }
    }


    
    // MARK: - 주차 기반 퀴즈 생성
    func createQuiz(for weekIds: [Int], courseTitle: String, questionCount: Int = 5) {
        let request = QuizAPI.createQuiz(
            userId: userId,
            title: "\(courseTitle) 퀴즈",
            description: "weeks: \(weekIds)",
            weekIds: weekIds,
            quizType: "AUTO",
            questionCount: questionCount
        )

        quizProvider.request(request) { [weak self] result in
            switch result {
            case .success(let response):
                print("✅ 퀴즈 생성 응답:", response.statusCode)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.fetchAllQuizzes()
                }

            case .failure(let error):
                print("❌ 퀴즈 생성 실패: \(error)")
            }
        }
    }

    // MARK: -  필터링된 주차 계산(질문이 하나라도 있는 주차만 사용)
    func getWeeksWithQuestions(for courseId: Int, completion: @escaping ([WeekResponseByUserID]) -> Void) {
        guard let course = courses.first(where: { $0.id == courseId }) else {
            completion([])
            return
        }

        let group = DispatchGroup()
        var result: [WeekResponseByUserID] = []

        for week in course.weeks {
            group.enter()
            quizProvider.request(.getWeekQuestions(weekId: week.id)) { response in
                defer { group.leave() }

                switch response {
                case .success(let res):
                    if let questions = try? JSONDecoder().decode([QuestionResponse].self, from: res.data), !questions.isEmpty {
                        result.append(week)
                    }
                case .failure:
                    break
                }
            }
        }

        group.notify(queue: .main) {
            completion(result)
        }
    }

    func selectedCourseChanged(to courseId: Int) {
            selectedCourseId = courseId
            if let course = courses.first(where: { $0.id == courseId }) {
                weeks = course.weeks
            } else {
                weeks = []
            }
        }
    
    func deleteQuiz(id: Int, completion: @escaping () -> Void) {
        quizProvider.request(.deleteQuiz(id: id)) { [weak self] result in
            switch result {
            case .success(let response):
                if (200...299).contains(response.statusCode) {
                    print("✅ 퀴즈 삭제 성공")
                    DispatchQueue.main.async {
                        self?.fetchAllQuizzes()
                        completion()
                    }
                } else {
                    print("❌ 퀴즈 삭제 실패: \(response.statusCode)")
                }
            case .failure(let error):
                print("❌ 퀴즈 삭제 요청 실패: \(error)")
            }
        }
    }


}

