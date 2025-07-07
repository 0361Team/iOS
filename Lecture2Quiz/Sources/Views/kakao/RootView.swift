//
//  RootView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 6/3/25.
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else {
                MainLoginView()
            }
        }
        .onAppear {
            // 2초 후 스플래시 종료
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}
