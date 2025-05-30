//
//  WeekQuestionViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/27/25.
//


import Foundation
import Moya

class WeekQuestionViewModel: ObservableObject {
    @Published var courses: [CourseResponseByUserID] = []
    @Published var selectedCourseId: Int?
    @Published var weeks: [WeekResponseByUserID] = []
    @Published var questionsPerWeek: [Int: [QuestionResponse]] = [:] // weekId → 질문 배열
    
    var selectedCourseTitle: String? { //수업 선택 picker용
           if let id = selectedCourseId {
               return courses.first(where: { $0.id == id })?.title
           }
           return nil
       }

    private let courseProvider = MoyaProvider<CourseAPI>()
    private let quizProvider = MoyaProvider<QuizAPI>()
    private let userId = 1

    func fetchCourses() {
        courseProvider.request(.getUserCourses(userId: userId)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let courses = try JSONDecoder().decode([CourseResponseByUserID].self, from: response.data)
                    DispatchQueue.main.async {
                        self?.courses = courses
                        self?.selectedCourseId = courses.first?.id
                        self?.weeks = courses.first?.weeks ?? []
                    }
                } catch {
                    print("❌ 수업 디코딩 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 수업 조회 실패: \(error)")
            }
        }
    }

    func selectCourse(id: Int) {
        selectedCourseId = id
        if let course = courses.first(where: { $0.id == id }) {
            weeks = course.weeks
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
                    print(String(data: response.data, encoding: .utf8) ?? "응답 출력 실패")
                    print("❌ 질문 디코딩 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 질문 조회 실패: \(error)")
            }
        }
    }

    func generateQuestions(for weekId: Int, minCount: Int = 3) {
        quizProvider.request(.generateQuestions(weekId: weekId, minQuestionCount: minCount)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let result = try JSONDecoder().decode(GenerateQuestionsResponse.self, from: response.data)
                    print("✅ 생성된 질문 ID: \(result.questionIds)")
                    self?.fetchQuestions(for: weekId)
                } catch {
                    print(String(data: response.data, encoding: .utf8) ?? "응답 출력 실패")
                    print("❌ 질문 생성 응답 디코딩 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 질문 생성 실패: \(error)")
            }
        }
    }
}

