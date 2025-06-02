//
//  OtherView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/31/25.
//

import SwiftUI

struct OtherView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var userId: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. 상단 인사 배너
                greetingBanner

                // 2. 사용자 정보 배너
                profileBanner

                // 3. 앱 소개 배너
                infoBanner(title: "Lecture2Quiz는?", subtitle: "수업 녹음과 퀴즈를 한 번에!", color: .cyan)

                // 4. 꿀팁 배너
                infoBanner(title: "Tip", subtitle: "퀴즈 풀고 학습 효과 2배!", color: .mint)

                // 5. 업데이트 소식 배너
                infoBanner(title: "최근 업데이트", subtitle: "더 예뻐진 디자인을 확인해보세요", color: .indigo.opacity(0.8))
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadUserInfo)
    }

    var greetingBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("안녕하세요")
                    .font(.headline)
                Text("\(name)님, 오늘도 좋은 하루 되세요!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "sun.max.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    var profileBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.title3).bold()
                Text(email)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("ID: \(userId)")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    func infoBanner(title: String, subtitle: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "star.fill")
                .foregroundColor(.white)
                .font(.title2)
        }
        .padding()
        .background(color)
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    private func loadUserInfo() {
        name = KeychainHelper.shared.read(forKey: "userName") ?? "이름 없음"
        email = KeychainHelper.shared.read(forKey: "userEmail") ?? "이메일 없음"
        userId = KeychainHelper.shared.read(forKey: "userId") ?? "-"
    }
}
