//
//  LoginAPI.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/30/25.
//

import Foundation
import Moya

enum KakaoAuthAPI {
    case sendToken(accessToken: String, refreshToken: String, expiresIn: Int64)
}

extension KakaoAuthAPI: TargetType {
    var baseURL: URL {
        let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_URL") as! String
        return URL(string: baseURL)!
    }
    

    var path: String {
        return "/public/auth/kakao/token"
    }

    var method: Moya.Method {
        return .post
    }

    var task: Task {
        switch self {
        case let .sendToken(accessToken, refreshToken, expiresIn):
            let params: [String: Any] = [
                "accessToken": accessToken,
                "refreshToken": refreshToken,
                "expiresIn": expiresIn
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "*/*"
        ]
    }
}
