//
//  HomeView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/5/25.
//

import SwiftUI

//
//  HomeView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 4/5/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: String
    @State private var currentPage = 0
    @State private var showRecordingModal = false

    let banners: [Banner] = [
        Banner(imageName: "banner1", title: "오늘의 퀴즈 한입 🧠", subtitle: "오늘도 한 문제 풀고 성장해요!"),
        Banner(imageName: "banner2", title: "복습으로 완성!", subtitle: "기록한 퀴즈 다시 풀어보세요."),
        Banner(imageName: "banner3", title: "성적 분석 준비 중..", subtitle: "나의 성장을 시각화할 수 있어요!")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        TabView(selection: $currentPage) {
                            ForEach(Array(banners.enumerated()), id: \ .offset) { index, banner in
                                BannerView(banner: banner)
                                    .padding(.horizontal, 16)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 200)
                        .padding(.top, 24)

                        HStack(spacing: 8) {
                            ForEach(0..<banners.count, id: \ .self) { index in
                                Circle()
                                    .fill(index == currentPage ? Color.black : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                        VStack(alignment: .leading, spacing: 16) {
                            Text("나를 위한 추천 🪄")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            ForEach(decorCards) { item in
                                RecommendationCardView(item: item)
                            }
                        }
                        .padding(.bottom, 32)

                        let tips: [String] = [
                            "⏱️ 짧은 시간이라도 매일 퀴즈를 풀어보세요.",
                            "🧠 반복 학습은 기억력을 향상시켜요.",
                            "📈 매일의 학습이 성장을 만듭니다!"
                        ]

                        VStack(alignment: .leading, spacing: 12) {
                            Text("오늘의 학습 팁 💡")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            TabView {
                                ForEach(tips.indices, id: \ .self) { index in
                                    Text(tips[index])
                                        .font(Font.Pretend.pretendardLight(size: 16))
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.yellow.opacity(0.15))
                                        .cornerRadius(12)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .automatic))
                            .frame(height: 100)
                        }
                        .padding(.bottom, 32)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("COMING SOON 🔧")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 120)
                                .overlay(
                                    VStack(alignment: .leading) {
                                        Text("더 많은 기능이 준비 중이에요")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Text("랭킹, AI 분석, 커뮤니티 등")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding()
                                )
                                .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 60)
                    }
                }

                VStack {
                    Spacer()
                    FloatingMenuButton(selectedTab: $selectedTab, showRecordingModal: $showRecordingModal)
                        .padding(.bottom, 32)
                }

                if showRecordingModal {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showRecordingModal = false
                            }
                        }

                    RecordingModal(
                        onDismiss: {
                            withAnimation {
                                showRecordingModal = false
                            }
                        }
                    )
                    .zIndex(1)
                }
            }
        }
    }

    let decorCards: [Recommendation] = [
        Recommendation(icon: "lightbulb", title: "기억력 UP 챌린지", subtitle: "퀴즈로 두뇌 회전!"),
        Recommendation(icon: "clock", title: "빠른 3분 퀴즈", subtitle: "시간은 짧고 문제는 강력하게"),
        Recommendation(icon: "book", title: "전공 요약 카드", subtitle: "학습한 내용을 정리해봐요")
    ]
}

struct FloatingMenuButton: View {
    @State private var isExpanded = false
    @Binding var selectedTab: String
    @Binding var showRecordingModal: Bool

    let menuItems: [(icon: String, label: String)] = [
        ("note.text.badge.plus", "새 노트"),
        ("mic.fill", "녹음")
    ]

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing, spacing: 16) {
                        ForEach(menuItems.indices.reversed(), id: \ .self) { index in
                            HStack(spacing: 10) {
                                Text(menuItems[index].label)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .opacity(isExpanded ? 1 : 0)
                                    .offset(y: isExpanded ? 0 : 20)
                                    .animation(
                                        .easeOut.delay(Double(index) * 0.05),
                                        value: isExpanded
                                    )

                                FloatingSubButton(iconName: menuItems[index].icon) {
                                    if menuItems[index].label == "녹음" {
                                        withAnimation {
                                            showRecordingModal = true
                                        }
                                    }
                                    if menuItems[index].label == "새 노트" {
                                        selectedTab = "Class"
                                    }
                                }
                                .scaleEffect(isExpanded ? 1 : 0.6)
                                .opacity(isExpanded ? 1 : 0)
                                .offset(y: isExpanded ? 0 : 30)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.05),
                                    value: isExpanded
                                )
                            }
                        }
                    }
                    .padding(.bottom, 80)
                    .padding(.trailing, 8)

                    FloatingSubButton(iconName: isExpanded ? "xmark" : "plus") {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// 나머지 모델과 뷰는 동일
struct Banner: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String
}

struct BannerView: View {
    let banner: Banner

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(banner.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(banner.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 160)
    }
}

struct Recommendation: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct RecommendationCardView: View {
    let item: Recommendation

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: item.icon)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}


struct FloatingSubButton: View {
    var iconName: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
    }
}






#Preview {
}
