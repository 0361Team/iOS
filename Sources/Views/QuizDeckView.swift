//
//  QuizDeckView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import SwiftUI

struct QuizDeckView: View {
    @StateObject private var viewModel = QuizViewModel()

    var body: some View {
        ZStack {
            if viewModel.currentIndex >= viewModel.cards.count {
                VStack {
                    Text("🎉 퀴즈 완료!")
                        .font(.largeTitle)
                        .padding()
                    Text("정답: \(viewModel.correct.count)")
                    Text("오답: \(viewModel.wrong.count)")

                    Button("다시 시작") {
                        viewModel.restart()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            } else {
                ForEach(viewModel.cards.indices.reversed(), id: \.self) { index in
                    if index >= viewModel.currentIndex {
                        let card = viewModel.cards[index]
                        QuizCardView(card: card) { isCorrect in
                            viewModel.swipeCard(isCorrect: isCorrect)
                        }
                        .padding()
                        .zIndex(Double(viewModel.cards.count - index))
                        .animation(.easeInOut, value: viewModel.currentIndex)
                    }
                }
            }
        }
        .background(Color.gray.opacity(0.1).ignoresSafeArea())
    }
}



#Preview {
    QuizDeckView()
}
