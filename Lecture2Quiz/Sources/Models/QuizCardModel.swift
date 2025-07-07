//
//  QuizCard.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import Foundation

struct QuizCard: Identifiable, Codable {
    let id = UUID()
    let question: String
    let answer: String
}

