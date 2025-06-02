//
//  QuizTopTab.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/26/25.
//


import SwiftUI

enum QuizTopTab: String, CaseIterable {
    case WeekQuestion = "주차 질문"
    case Quiz = "퀴즈"
    case QuizRecord = "퀴즈 기록"
}

struct QuizTopTabView: View {
    @Namespace private var animation
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        VStack(spacing: 0) {
            QuiztabBar
            QuizseparatorLine
        }
    }

    // 탭 바 부분 분리
    private var QuiztabBar: some View {
        HStack(spacing: 20) {
            ForEach(QuizTopTab.allCases, id: \.self) { tab in
                QuiztabItem(for: tab)
            }
        }
        .padding(.top)
        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
    }

    // 탭 항목 개별 뷰 분리
    private func QuiztabItem(for tab: QuizTopTab) -> some View {
        let isSelected = viewModel.selectedTab == tab

        return VStack(spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut) {
                    viewModel.selectedTab = tab
                }
            }) {
                Text(tab.rawValue)
                    .font(Font.Pretend.pretendardBold(size: 16))
                    .foregroundColor(isSelected ? .black : .gray)
            }
            .padding()

            if isSelected {
                Capsule()
                    .fill(Color.blue)
                    .frame(height: 3)
                    .matchedGeometryEffect(id: "underline", in: animation)
            } else {
                Color.clear.frame(height: 3)
            }
        }
        .padding(.bottom, -10)
    }

    // 하단 구분선
    private var QuizseparatorLine: some View {
        ZStack(alignment: .leading) {
            Color.white.opacity(0.01)
                .frame(height: 3)
                .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
        }
        .frame(height: 3)
    }
}


#Preview("주차 질문 탭") {
    QuizTopTabView(viewModel: {
        let vm = QuizViewModel()
        vm.selectedTab = .WeekQuestion
        return vm
    }())
}
