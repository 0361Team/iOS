//
//  SplashView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 6/3/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.blue) // Assets에서 정의한 파란색 또는 Color.blue로 대체 가능
                .ignoresSafeArea()

            VStack {
                Image("Logo_Lecture2Quiz") // 흰색 로고 이미지
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .padding(.bottom, 24)

            }
        }
    }
}

#Preview {
    SplashView()
}
