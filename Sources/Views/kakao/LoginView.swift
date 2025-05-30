//
//  LoginView.swift
//  Starbucks
//
//  Created by 박현규 on 3/18/25.
//

import SwiftUI
import KakaoSDKUser
import KakaoSDKCommon

struct MainLoginView: View {
   @State private var isLoggedIn = false
    var body: some View {
        NavigationStack{
        VStack{
                kakaoLoginView(isLoggedIn: $isLoggedIn)
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                            TableView()
            }
            .navigationTitle("Login")
        }
    }
}

struct kakaoLoginView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        
        Button(action: {
            // 카카오 로그인 요청
            if (UserApi.isKakaoTalkLoginAvailable()) {
                                UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
                                    if let error = error {
                                        print(error)
                                    } else if let oauthToken = oauthToken{
                                        print("카카오톡 로그인 성공")
                                        print(oauthToken)
                                        isLoggedIn = true
                                    }
                                }
                            } else {
                                UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
                                    if let error = error {
                                        print(error)
                                    } else if let oauthToken = oauthToken{
                                        print("카카오 계정 로그인 성공")
                                        print(oauthToken)
                                        isLoggedIn = true
                                    }
                                }
                            }
        }, label: {
            Image("kakaoLogo")
            Text("카카오 로그인")
                .frame(width: 301, height: 45)
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .font(Font.Pretend.pretendardMedium(size: 16))
        })
        .frame(width: 306, height: 45)
        .buttonStyle(.borderedProminent) // 버튼 스타일 적용
        .tint(Color(hex: "#FEE500")) // 버튼 색상 적용
        .fixedSize(horizontal: false, vertical: true)
        
        
    }
}


#Preview {
    MainLoginView()
        
}
