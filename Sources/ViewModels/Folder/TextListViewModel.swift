import Foundation
import Moya

class TextListViewModel: ObservableObject {
    @Published var texts: [WeekTextResponse] = []
    @Published var isLoading = false
    @Published var showActionSheet = false

    private let weekId: Int
    private let provider = MoyaProvider<CourseAPI>()
    private let onDeleteSuccess: () -> Void

    init(weekId: Int, onDeleteSuccess: @escaping () -> Void) {
        self.weekId = weekId
        self.onDeleteSuccess = onDeleteSuccess
        fetchTexts()
    }

    func fetchTexts() {
        isLoading = true
        provider.request(.getWeekText(weekId: weekId)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    do {
                        self?.texts = try JSONDecoder().decode([WeekTextResponse].self, from: response.data)
                    } catch {
                        print("❌ 텍스트 파싱 오류: \(error)")
                    }
                case .failure(let error):
                    print("❌ 텍스트 요청 실패: \(error)")
                }
            }
        }
    }

    func deleteWeek() {
        provider.request(.deleteWeek(weekId: weekId)) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if (200..<300).contains(response.statusCode) {
                        print("✅ 주차 삭제 성공")
                        self?.onDeleteSuccess()
                    } else {
                        print("⚠️ 삭제 실패: \(response.statusCode)")
                    }
                case .failure(let error):
                    print("❌ 주차 삭제 실패: \(error)")
                }
            }
        }
    }
}
