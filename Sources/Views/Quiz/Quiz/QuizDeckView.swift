    //
    //  QuizDeckView.swift
    //  Lecture2Quiz
    //
    //  Created by 바견규 on 3/29/25.
    //

    import SwiftUI

    struct QuizDeckView: View {
        @StateObject var viewModel: QuizCardViewModel
        @Binding var isPresented: Bool

        var body: some View {
            ZStack {
                if viewModel.currentIndex >= viewModel.cards.count {
                    VStack {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.seal.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.green)

                            Text("퀴즈 완료!")
                                .font(.title)
                                .fontWeight(.bold)

                            HStack(spacing: 40) {
                                VStack {
                                    Text("정답")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("\(viewModel.correct.count)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }

                                VStack {
                                    Text("오답")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("\(viewModel.wrong.count)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                            }

                            Button(action: {
                                isPresented = false
                            }) {
                                Text("닫기")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(radius: 5)
                        )
                        .padding()

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


    struct QuizDeckViewWrapper: View {
        @ObservedObject var viewModel: QuizViewModel
        @Binding var isPresented: Bool

        var body: some View {
            let cardVM = QuizCardViewModel(cards: viewModel.quizCards)

            cardVM.onAnswer = { index, isCorrect in
                viewModel.sendAnswer(answer: isCorrect ? "O" : "X") {
                    let isLast = index == viewModel.quizCards.count - 1
                    if isLast {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.completeQuizSession()
                            viewModel.quizCards = []
                            isPresented = false
                        }
                    }
                }
            }

            return QuizDeckView(viewModel: cardVM, isPresented: $isPresented)
        }
    }




