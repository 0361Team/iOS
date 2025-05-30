//
//  SubmitTranscriptViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/25/25.
//

import Foundation
import Moya

class SubmitTranscriptViewModel: ObservableObject {
    @Published var folders: [CourseResponseByUserID] = []
    @Published var selectedCourseId: Int?
    @Published var selectedWeekId: Int?
    @Published var showAddWeekAlert = false
    @Published var newWeekTitle: String = ""

    let userId: Int = 1 // TODO: 실제 로그인된 사용자 ID로 교체
    private let provider = MoyaProvider<CourseAPI>()

    var selectedCourse: CourseResponseByUserID? {
        folders.first { $0.id == selectedCourseId }
    }

    var selectedWeek: WeekResponseByUserID? {
        selectedCourse?.weeks.first { $0.id == selectedWeekId }
    }

    func fetchFolders() {
        provider.request(.getUserCourses(userId: userId)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try JSONDecoder().decode([CourseResponseByUserID].self, from: response.data)
                    DispatchQueue.main.async {
                        self?.folders = decoded

                        // 선택된 course나 week가 사라졌을 경우 대비
                        if let courseId = self?.selectedCourseId,
                           !decoded.contains(where: { $0.id == courseId }) {
                            self?.selectedCourseId = nil
                            self?.selectedWeekId = nil
                        }
                    }
                } catch {
                    print(" 파싱 오류: \(error)")
                }
            case .failure(let error):
                print(" 요청 실패: \(error)")
            }
        }
    }

    func addWeek(to course: CourseResponseByUserID, completion: @escaping () -> Void) {
        guard !newWeekTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newWeekNumber = (course.weeks.map { $0.id }.max() ?? 0) + 1
        provider.request(.createWeek(courseId: course.id, title: newWeekTitle, weekNumber: newWeekNumber)) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.newWeekTitle = ""
                    completion()
                }
            case .failure(let error):
                print(" 주차 생성 실패: \(error)")
            }
        }
    }

    func submitTranscript(content: String, completion: @escaping (Bool) -> Void) {
        guard let weekId = selectedWeekId else {
            completion(false)
            return
        }

        provider.request(.submitTranscript(weekId: weekId, content: content, type: "RECORDING")) { result in
            switch result {
            case .success(let response):
                print(" 저장 성공: \(response.statusCode)")
                completion(true)
            case .failure(let error):
                print(" 저장 실패: \(error)")
                completion(false)
            }
        }
    }
}
