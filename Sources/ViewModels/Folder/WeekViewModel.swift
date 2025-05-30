//
//  WeekViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/30/25.
//

import Foundation
import SwiftUI
import Moya

class WeekListViewModel: ObservableObject {
    @Published var course: CourseResponseByUserID
    @Published var isShowingActionSheet: Bool = false
    @Published var isDeleting: Bool = false

    private let provider = MoyaProvider<CourseAPI>()
    var onDeleteSuccess: () -> Void

    init(course: CourseResponseByUserID, onDeleteSuccess: @escaping () -> Void) {
        self.course = course
        self.onDeleteSuccess = onDeleteSuccess
    }

    func deleteCourse() {
        isDeleting = true
        provider.request(.deleteCourse(courseId: course.id)) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isDeleting = false
                switch result {
                case .success(let response):
                    print("삭제 성공: \(response.statusCode)")
                    self.onDeleteSuccess()
                case .failure(let error):
                    print("삭제 실패: \(error.localizedDescription)")
                }
            }
        }
    }
}
