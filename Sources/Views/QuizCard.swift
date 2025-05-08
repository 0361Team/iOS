//
//  QuizCard.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 3/29/25.
//

import SwiftUI

struct QuizCardView: View {
    let card: QuizCard
    let onSwipe: (Bool) -> Void

    @State private var isFlipped = false
    @State private var offset = CGSize.zero
    @State private var isRemoved = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if !isRemoved {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(radius: 5)
                        .overlay(
                            VStack {
                                if isFlipped {
                                    Text(card.answer)
                                        .font(Font.Pretend.pretendardSemiBold(size: 20))
                                        .foregroundColor(.green)
                                } else {
                                    Text(card.question)
                                        .font(Font.Pretend.pretendardSemiBold(size: 20))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding()
                            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            
                        )
                        .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(borderColor, lineWidth: 4)
                        )
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                }
                                .onEnded { _ in
                                    handleDragEnd()
                                }
                        )
                        .onTapGesture {
                            withAnimation {
                                isFlipped.toggle()
                            }
                        }
                        .animation(.easeOut, value: offset)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                }
            }
        }
    }

    var borderColor: Color {
        if isFlipped ? offset.width < -150 : offset.width > 150 {
            return .green
        } else if isFlipped ? offset.width > 150 : offset.width < -150 {
            return .red
        } else {
            return .clear // 또는 .gray.opacity(0.3) 정도로 기본 테두리
        }
    }

    private func handleDragEnd() {
        let threshold: CGFloat = 150
        let isCorrect: Bool?

        if offset.width > threshold {
            isCorrect = isFlipped ? false : true  // ← 뒤집힌 경우 해석 반대로
        } else if offset.width < -threshold {
            isCorrect = isFlipped ? true : false
        } else {
            isCorrect = nil
        }

        if let result = isCorrect {
            let direction = CGSize(width: isFlipped ? result ? -1000 : 1000 : result ? 1000 : -1000, height: 0)
            flyAway(to: direction, isCorrect: result)
        } else {
            withAnimation {
                offset = .zero
            }
        }
    }

    private func flyAway(to target: CGSize, isCorrect: Bool) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = target
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isRemoved = true
            onSwipe(isCorrect)
        }
    }
}



// MARK: - 프리뷰
    #Preview {
        QuizCardView(
            card: QuizCard(
                question: "SwiftUI는 어떤 프레임워크인가요?",
                answer: "애플의 선언형 UI 프레임워크입니다."
            ),
            onSwipe: { isCorrect in
                print(isCorrect ? "정답 처리!" : "오답 처리!")
            }
        )
        .background(Color.gray.opacity(0.1))
    }
