//
//  WeekQuestionViewModel.swift
//  Lecture2Quiz
//

import Foundation
import Moya

class WeekQuestionViewModel: ObservableObject {
    @Published var courses: [CourseResponseByUserID] = []
    @Published var selectedCourseId: Int?
    @Published var weeks: [WeekResponseByUserID] = []
    @Published var questionsPerWeek: [Int: [QuestionResponse]] = [:]
    @Published var isLoading: Bool = false
    @Published var isQuestionsVisible: [Int: Bool] = [:]


    var selectedCourseTitle: String? {
        if let id = selectedCourseId {
            return courses.first(where: { $0.id == id })?.title
        }
        return nil
    }

    private let courseProvider = MoyaProvider<CourseAPI>()
    private let quizProvider = MoyaProvider<QuizAPI>()
    private let userId = Int(KeychainHelper.shared.read(forKey: "userId")!)!

    func fetchCourses() {
        isLoading = true
        courseProvider.request(.getUserCourses(userId: userId)) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    do {
                        let courses = try JSONDecoder().decode([CourseResponseByUserID].self, from: response.data)
                        self?.courses = courses
                        self?.selectedCourseId = courses.first?.id
                        self?.weeks = courses.first?.weeks ?? []
                        self?.fetchAllQuestions()
                    } catch {
                        print("❌ 수업 디코딩 실패: \(error)")
                    }
                case .failure(let error):
                    print("❌ 수업 조회 실패: \(error)")
                }
                self?.isLoading = false
            }
        }
    }

    func selectCourse(id: Int) {
        selectedCourseId = id
        if let course = courses.first(where: { $0.id == id }) {
            weeks = course.weeks
            fetchAllQuestions()
        }
    }

    func fetchAllQuestions() {
        for week in weeks {
            fetchQuestions(for: week.id)
        }
    }

    func fetchQuestions(for weekId: Int) {
        quizProvider.request(.getWeekQuestions(weekId: weekId)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let questions = try JSONDecoder().decode([QuestionResponse].self, from: response.data)
                    DispatchQueue.main.async {
                        self?.questionsPerWeek[weekId] = questions
                    }
                } catch {
                    print("❌ 질문 디코딩 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 질문 조회 실패: \(error)")
            }
        }
    }

    func generateQuestions(for weekId: Int, minCount: Int = 3) {
        isLoading = true
        quizProvider.request(.generateQuestions(weekId: weekId, minQuestionCount: minCount)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    do {
                        let decoded = try JSONDecoder().decode(GenerateQuestionsResponse.self, from: response.data)
                        print("✅ 질문 생성 완료: \(decoded.questionIds)")
                        self?.fetchQuestions(for: weekId) // 생성 후 즉시 업데이트
                    } catch {
                        print("❌ 질문 생성 응답 디코딩 실패: \(error)")
                    }
                case .failure(let error):
                    print("❌ 질문 생성 실패: \(error)")
                }
            }
        }
    }
    
    func toggleQuestionVisibility(for weekId: Int) {
        if isQuestionsVisible[weekId] == true {
            isQuestionsVisible[weekId] = false
        } else {
            // 처음 누르는 경우엔 질문도 조회하도록 처리
            if questionsPerWeek[weekId] == nil {
                fetchQuestions(for: weekId)
            }
            isQuestionsVisible[weekId] = true
        }
    }

}
