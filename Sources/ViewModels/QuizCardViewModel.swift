//
//  QuizCardViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import Foundation

class QuizViewModel: ObservableObject {
    @Published var cards: [QuizCard] = []
    @Published var currentIndex: Int = 0
    @Published var correct: [UUID] = []
    @Published var wrong: [UUID] = []

    init() {
        // 예시 카드
        cards = [
            QuizCard(question: "Swift의 UI 프레임워크는?", answer: "SwiftUI"),
            QuizCard(question: "애플의 OS는?", answer: "iOS"),
            QuizCard(question: "iPhone은 어느 회사 제품?", answer: "Apple")
        ]
    }

    var currentCard: QuizCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    func swipeCard(isCorrect: Bool) {
        guard let currentCard = currentCard else { return }
        if isCorrect {
            correct.append(currentCard.id)
        } else {
            wrong.append(currentCard.id)
        }
        currentIndex += 1
    }

    func restart() {
        currentIndex = 0
        correct = []
        wrong = []
    }
}

