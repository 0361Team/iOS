//
//  FileViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import Foundation
import Moya

class FolderViewModel: ObservableObject {
    @Published var folders: [CourseResponseByUserID] = []
    @Published var isLoading: Bool = false  // 로딩 상태 추가
    
    private let provider = MoyaProvider<CourseAPI>()

    func fetchFolders(userId: Int) {
        isLoading = true  // 요청 시작 시 로딩 시작
        provider.request(.getUserCourses(userId: userId)) { result in
            DispatchQueue.main.async {
                            self.isLoading = false  // 요청 완료 시 로딩 종료
            }
            switch result {
            case .success(let response):
                do {
                    if let json = String(data: response.data, encoding: .utf8) {
                        print("📦 실제 서버 응답:\n\(json)")
                    }
                    self.folders = try JSONDecoder().decode([CourseResponseByUserID].self, from: response.data)
                } catch {
                    print("❌ 파싱 오류: \(error)")
                }
            case .failure(let error):
                print("❌ 요청 실패: \(error)")
            }
        }
    }

    func addFolder(name: String, userId: Int) {
        provider.request(.createCourse(userId: userId, title: name, description: "")) { result in
            switch result {
            case .success:
                self.fetchFolders(userId: userId)
                print("수업 생성 성공 userId: \(userId), name: \(name)")
            case .failure(let error):
                print("❌ 수업 생성 실패: \(error)")
            }
        }
    }

    func createWeek(courseId: Int, title: String, weekNumber: Int, completion: @escaping () -> Void) {
        provider.request(.createWeek(courseId: courseId, title: title, weekNumber: weekNumber)) { result in
            switch result {
            case .success(let response):
                print("✅ 주차 생성 완료: \(response.statusCode)")
                completion()
            case .failure(let error):
                print("❌ 주차 생성 실패: \(error)")
            }
        }
    }
}
