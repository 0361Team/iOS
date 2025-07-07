//
//  FileModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import Foundation

struct AudioFolder: Identifiable, Codable {
    let id: UUID
    var name: String
    var recordings: [AudioNote]
}

struct AudioNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var transcript: String
    var date: Date
    var audioURL: URL
}
