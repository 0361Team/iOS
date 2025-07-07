//
//  kakaoSDKApp.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/19/25.
//

//kakaoSDKApp.swift
import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct kakaoSDKApp: App {
    init() {
        let KakaoApiKey = Bundle.main.object(forInfoDictionaryKey: "Kakao_AppKey") as? String ?? ""
        KakaoSDK.initSDK(appKey: KakaoApiKey)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
