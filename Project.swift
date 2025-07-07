import ProjectDescription

let project = Project(
    name: "Lecture2Quiz",
    packages: [
        .package(url: "https://github.com/kakao/kakao-ios-sdk", .upToNextMajor(from: "2.13.0")),
        .package(url: "https://github.com/Moya/Moya.git", .exact("15.0.0")),
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", .upToNextMajor(from: "1.0.0"))
    ],
    // ✅ 아래처럼 settings도 추가해야 함
    settings: .settings(
        configurations: [
            .debug(name: "SecretOnly", xcconfig: .relativeToRoot("../iOS/Configuration/Secret.xcconfig"))
        ]
    ),
    targets: [
        .target(
            name: "Lecture2Quiz",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Lecture2Quiz",
            infoPlist: .extendingDefault(
                with: [
                    // 1️⃣ 런치 스크린 설정
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ],
                    
                    // 2️⃣ 마이크 권한
                    "NSMicrophoneUsageDescription": "앱이 녹음을 위해 마이크를 사용합니다.",
                    
                    // 3️⃣ 네트워크 권한 (ws:// 프로토콜 허용)
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": true
                    ],

                    // ✅ Secret.xcconfig에서 가져올 값들
                    "API_URL": "$(API_URL)",
                    "Kakao_AppKey": "$(Kakao_AppKey)",
                    "AudioAPI_URL": "$(AudioAPI_URL)"
                ]
            ),
            sources: ["Lecture2Quiz/Sources/**"],
            resources: ["Lecture2Quiz/Resources/**"],
            dependencies: [
                .package(product: "KakaoSDKCommon"),
                .package(product: "KakaoSDKAuth"),
                .package(product: "KakaoSDKUser"),
                .package(product: "Moya"),
                .package(product: "MarkdownUI")
            ]
        ),
        .target(
            name: "Lecture2QuizTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.Lecture2QuizTests",
            infoPlist: .default,
            sources: ["Lecture2Quiz/Tests/**"],
            resources: [],
            dependencies: [
                .target(name: "Lecture2Quiz")
            ]
        )
    ]
)
