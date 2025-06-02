//
//  LoginResponse.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/30/25.
//

import Foundation

struct JWTTokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int64
    let userId: Int
    let email: String
    let name: String
}
