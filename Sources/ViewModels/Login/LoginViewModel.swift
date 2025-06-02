//
//  LoginViewModel.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/30/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import Moya

class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    private let authProvider = MoyaProvider<KakaoAuthAPI>()

    func loginWithKakao() {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
                self?.handleLoginResult(oauthToken: oauthToken, error: error)
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
                self?.handleLoginResult(oauthToken: oauthToken, error: error)
            }
        }
    }

    private func handleLoginResult(oauthToken: OAuthToken?, error: Error?) {
        if let error = error {
            print("❌ 로그인 실패: \(error)")
            return
        }

        guard let token = oauthToken else {
            print("❌ 토큰 없음")
            return
        }

        print("✅ 로그인 성공, 토큰: \(token)")

        // 사용자 정보 조회
        UserApi.shared.me { [weak self] user, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 사용자 정보 조회 실패: \(error)")
                return
            }


            self.sendTokenToServer(
                accessToken: token.accessToken,
                refreshToken: token.refreshToken,
                expiresIn: Int64(token.expiresIn)
            )
        }
        
        isLoggedIn = true // 뷰 전환
    }

    private func sendTokenToServer(accessToken: String, refreshToken: String, expiresIn: Int64?) {
        let expires = expiresIn ?? 0
        authProvider.request(.sendToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expires
        )) { [weak self] result in
            switch result {
            case .success(let response):
                print("✅ 서버 응답 코드: \(response.statusCode)")
                let raw = String(data: response.data, encoding: .utf8)
                print("📦 서버 원본 응답: \(raw ?? "파싱 실패")")
                do {
                    let jwtResponse = try JSONDecoder().decode(JWTTokenResponse.self, from: response.data)
                    KeychainHelper.shared.save(jwtResponse.accessToken, forKey: "jwtToken")
                    KeychainHelper.shared.save(jwtResponse.name, forKey: "userName")
                    KeychainHelper.shared.save(jwtResponse.email, forKey: "userEmail")
                    KeychainHelper.shared.save("\(jwtResponse.userId)", forKey: "userId")
                    print("📦 JWT 저장 완료: \(jwtResponse.accessToken)")
                    
                    DispatchQueue.main.async {
                        self?.isLoggedIn = true
                    }
                } catch {
                    print("❌ JWT 응답 파싱 실패: \(error)")
                }

            case .failure(let error):
                print("❌ 토큰 전송 실패: \(error)")
            }
        }
    }
}
