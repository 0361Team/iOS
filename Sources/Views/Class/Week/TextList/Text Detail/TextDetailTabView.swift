//
//  TextDetailTabView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/25/25.
//

import SwiftUI

enum TextTopTab: String, CaseIterable {
    case script = "음성 기록"
    case sumary = "요약"
    case keyword = "키워드"
}

struct TextDetailTabView: View {
    @Namespace private var animation
    @ObservedObject var viewModel: TextViewModel

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            separatorLine
        }
    }

    // ✅ 탭 바 부분 분리
    private var tabBar: some View {
        HStack(spacing: 20) {
            ForEach(TextTopTab.allCases, id: \.self) { tab in
                tabItem(for: tab)
            }
        }
        .padding(.top)
        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
    }

    // ✅ 탭 항목 개별 뷰 분리
    private func tabItem(for tab: TextTopTab) -> some View {
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

    // ✅ 하단 구분선
    private var separatorLine: some View {
        ZStack(alignment: .leading) {
            Color.white.opacity(0.01)
                .frame(height: 3)
                .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
        }
        .frame(height: 3)
    }
}


