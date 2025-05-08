//
//  FileViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import Foundation

class FolderViewModel: ObservableObject {
    @Published var folders: [AudioFolder] = []

    init() {
        // 예시 폴더 2개
        folders = [
            AudioFolder(id: UUID(), name: "소프트웨어 프로젝트", recordings: []),
            AudioFolder(id: UUID(), name: "프로그래밍 언어", recordings: [])
        ]
    }

    func addFolder(name: String) {
        let newFolder = AudioFolder(id: UUID(), name: name, recordings: [])
        folders.append(newFolder)
    }
}
