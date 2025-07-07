//
//  WeekViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/30/25.
//

import SwiftUI
import Moya

class WeekListViewModel: ObservableObject {
    @Published var course: CourseResponseByUserID
    @Published var isShowingActionSheet: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isLoading: Bool = false

    private let provider = MoyaProvider<CourseAPI>()
    var onDeleteSuccess: () -> Void

    init(course: CourseResponseByUserID, onDeleteSuccess: @escaping () -> Void) {
        self.course = course
        self.onDeleteSuccess = onDeleteSuccess
    }

    func deleteCourse(onSuccess: @escaping () -> Void) {
        isDeleting = true
        provider.request(.deleteCourse(courseId: course.id)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isDeleting = false
                switch result {
                case .success(let response):
                    if (200..<300).contains(response.statusCode) {
                        print("✅ 수업 삭제 성공")
                        onSuccess()
                    } else {
                        print("⚠️ 수업 삭제 실패: \(response.statusCode)")
                    }
                case .failure(let error):
                    print("❌ 수업 삭제 실패: \(error)")
                }
            }
        }
    }

    func fetchCourse() {
        isLoading = true // ✅ 요청 시작 시 true
        provider.request(.getCourseWeeks(courseId: course.id)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    do {
                        self?.course = try JSONDecoder().decode(CourseResponseByUserID.self, from: response.data)
                    } catch {
                        print("❌ 코스 디코딩 실패: \(error)")
                    }
                case .failure(let error):
                    print("❌ 코스 요청 실패: \(error)")
                }
            }
        }
    }
}
