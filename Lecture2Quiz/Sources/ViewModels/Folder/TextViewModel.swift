//
//  TextViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/25/25.
//

import Foundation
import Moya

class TextViewModel: ObservableObject {
    enum Tab {
        case script, sumary, keyword
    }

    @Published var selectedTab: TextTopTab = .script
    @Published var text: String
    @Published var sumary: String?
    @Published var keywords: [String]?
    @Published var isEditing: Bool = false
    @Published var isDeleting = false
    @Published var isShowingActionSheet: Bool = false
    
    let id: Int
    private let provider = MoyaProvider<CourseAPI>()

    init(text: String, sumary: String?, id: Int) {
        self.text = text
        self.sumary = sumary
        self.id = id

        if sumary == nil {
            generateSummary()
        }

        fetchKeywords()
    }

    // MARK: - 요약 생성 요청 및 반영
    func generateSummary() {
        provider.request(.summarizeText(textId: id)) { [weak self] result in
            switch result {
            case .success:
                self?.fetchSummary()
            case .failure(let error):
                print("❌ 요약 생성 실패: \(error)")
            }
        }
    }

    func fetchSummary() {
        provider.request(.getTextById(id: id)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try JSONDecoder().decode(TextDetailResponse.self, from: response.data)
                    DispatchQueue.main.async {
                        self?.sumary = decoded.summation
                    }
                } catch {
                    print("❌ 요약 디코딩 실패: \(error)")
                    if let fallback = String(data: response.data, encoding: .utf8) {
                        print("📦 서버 응답 본문:\n\(fallback)")
                    }
                }

            case .failure(let error):
                print("❌ 요약 fetch 실패: \(error)")
            }
        }
    }

    // MARK: - 키워드 생성 요청 및 반영
    func fetchKeywords() {
        provider.request(.getKeywords(textId: id)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try JSONDecoder().decode([String].self, from: response.data)
                    DispatchQueue.main.async {
                        if decoded.isEmpty {
                            self?.generateKeywords()
                        } else {
                            self?.keywords = decoded.map { $0 }
                        }
                    }
                } catch {
                    print("❌ 키워드 파싱 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 키워드 fetch 실패: \(error)")
            }
        }
    }

    func generateKeywords() {
        provider.request(.createKeyword(textId: id)) { [weak self] result in
            switch result {
            case .success:
                self?.fetchKeywords()
            case .failure(let error):
                print("❌ 키워드 생성 실패: \(error)")
            }
        }
    }
    
    func deleteText(onComplete: (() -> Void)? = nil) {
        provider.request(.deleteText(textId: id)) { [weak self] result in
            switch result {
            case .success:
                print("✅ 텍스트 삭제 성공")
                DispatchQueue.main.async {
                    onComplete?()
                }
            case .failure(let error):
                print("❌ 텍스트 삭제 실패: \(error)")
            }
        }
    }
    
    func refreshText() {
        provider.request(.getTextById(id: id)) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try JSONDecoder().decode(TextDetailResponse.self, from: response.data)
                    DispatchQueue.main.async {
                        self?.text = decoded.content
                        self?.sumary = decoded.summation
                        self?.keywords = nil // 키워드 초기화 (옵션)
                        self?.fetchKeywords() // 키워드도 다시 받아오게
                    }
                } catch {
                    print("❌ 텍스트 리프레시 디코딩 실패: \(error)")
                }
            case .failure(let error):
                print("❌ 텍스트 리프레시 실패: \(error)")
            }
        }
    }
    
    func deleteText(completion: @escaping () -> Void) {
        isDeleting = true
        provider.request(.deleteText(textId: id)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isDeleting = false
                completion()
            }
        }
    }
    
}
