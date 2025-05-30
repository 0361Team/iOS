//
//  QuizCardViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import Foundation

class QuizCardViewModel: ObservableObject {
    @Published var cards: [QuizCard] = []
    @Published var currentIndex: Int = 0
    @Published var correct: [UUID] = []
    @Published var wrong: [UUID] = []
    var quizViewModel: QuizViewModel?
    
    var onAllAnswered: (() -> Void)?
    var onAnswer: ((Int, Bool) -> Void)?

    init(cards: [QuizCard] = []) {
        self.cards = cards
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

        onAnswer?(currentIndex, isCorrect)
        currentIndex += 1
        
        if currentIndex >= cards.count {
                    // ✅ 마지막 카드 넘긴 후에만 호출됨
                    onAllAnswered?()
        }
    }

    func restart() {
        currentIndex = 0
        correct = []
        wrong = []
    }
}


