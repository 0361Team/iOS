//
//  QuizMainView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/26/25.
//

import SwiftUI

struct QuizMainView: View {
    @Namespace private var animation
    @StateObject private var quizViewModel: QuizViewModel = QuizViewModel()
    @StateObject private var weekQuestionViewModel: WeekQuestionViewModel = WeekQuestionViewModel()

    var body: some View {
        VStack(spacing: 0) {
            QuizTopTabView(viewModel: quizViewModel)

            Group {
                switch quizViewModel.selectedTab {
                case .WeekQuestion:
                    WeekQuestionView(viewModel: weekQuestionViewModel)
                case .Quiz:
                    QuizView(viewModel: quizViewModel)
                case .QuizRecord:
                    QuizRecordView()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}




