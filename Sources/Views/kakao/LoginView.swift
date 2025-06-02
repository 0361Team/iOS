//
//  LoginView.swift
//  Starbucks
//
//  Created by 박현규 on 3/18/25.
//

import SwiftUI

struct MainLoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                KakaoLoginButtonView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                TableView()
            }
            .navigationTitle("Login")
        }
    }
}


struct KakaoLoginButtonView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        Button(action: {
            viewModel.loginWithKakao()
        }) {
            HStack {
                Image("kakaoLogo")
                Text("카카오 로그인")
                    .frame(width: 301, height: 45)
                    .foregroundStyle(Color.black)
                    .font(Font.Pretend.pretendardMedium(size: 16))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 306, height: 45)
        .buttonStyle(.borderedProminent)
        .tint(Color(hex: "#FEE500"))
        .fixedSize(horizontal: false, vertical: true)
    }
}


#Preview {
    MainLoginView()
        
}
