//
//  QuizDetailSheet.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/27/25.
//

import SwiftUI

struct QuizDetailSheet: View {
    let detail: QuizDetailResponse
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(detail.title)
                    .font(.title)
                    .bold()

                Text(detail.description)
                    .font(.body)

                HStack {
                    Text("문항 수:")
                        .fontWeight(.semibold)
                    Text("\(detail.totalQuestions)")
                }

                HStack {
                    Text("퀴즈 유형:")
                        .fontWeight(.semibold)
                    Text(detail.quizType)
                }

                if isDeleting {
                    ProgressView("삭제 중...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Button(role: .destructive) {
                        isDeleting = true
                        viewModel.deleteQuiz(id: detail.id) {
                            isDeleting = false
                            dismiss()
                        }
                    } label: {
                        Text("퀴즈 삭제")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("퀴즈 상세")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
