//
//  QuizSessionSheet.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/28/25.
//

import SwiftUI

struct QuizSessionDetailSheet: View {
    let detail: QuizSessionDetailResponse

    var body: some View {
        NavigationStack {
            List {
                ForEach(detail.userAnswers.indices, id: \.self) { i in
                    let ua = detail.userAnswers[i]
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Q\(i+1). \(ua.questionFront)")
                            .font(.headline)

                        Text("정답: \(ua.correctAnswer)")
                            .font(.subheadline)

                        Text("내 답변: \(ua.userAnswer)")
                            .font(.subheadline)
                            .foregroundColor(ua.userAnswer == ua.correctAnswer ? .green : .red)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}


extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
