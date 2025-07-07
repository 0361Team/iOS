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
    @Published var isLoading: Bool = false

    let userId: Int = Int(KeychainHelper.shared.read(forKey: "userId")!)! // TODO: 실제 로그인된 사용자 ID로 교체
    private let provider = MoyaProvider<CourseAPI>()

    var selectedCourse: CourseResponseByUserID? {
        folders.first { $0.id == selectedCourseId }
    }

    var selectedWeek: WeekResponseByUserID? {
        selectedCourse?.weeks.first { $0.id == selectedWeekId }
    }

    func fetchFolders() {
        isLoading = true
        provider.request(.getUserCourses(userId: userId)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    do {
                        let decoded = try JSONDecoder().decode([CourseResponseByUserID].self, from: response.data)
                        self?.folders = decoded

                        // 기존 선택이 유효한지 확인
                        if let courseId = self?.selectedCourseId,
                           !decoded.contains(where: { $0.id == courseId }) {
                            self?.selectedCourseId = nil
                            self?.selectedWeekId = nil
                        }
                    } catch {
                        print(" 파싱 오류: \(error)")
                    }
                case .failure(let error):
                    print(" 요청 실패: \(error)")
                }
            }
        }
    }

    func addWeek(to course: CourseResponseByUserID, completion: @escaping () -> Void) {
        guard !newWeekTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newWeekNumber = (course.weeks.map { $0.id }.max() ?? 0) + 1
        isLoading = true
        provider.request(.createWeek(courseId: course.id, title: newWeekTitle, weekNumber: newWeekNumber)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.newWeekTitle = ""
                    completion()
                case .failure(let error):
                    print(" 주차 생성 실패: \(error)")
                }
            }
        }
    }

    func submitTranscript(content: String, completion: @escaping (Bool) -> Void) {
        guard let weekId = selectedWeekId else {
            completion(false)
            return
        }

        isLoading = true
        provider.request(.submitTranscript(weekId: weekId, content: content, type: "RECORDING")) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
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
}
