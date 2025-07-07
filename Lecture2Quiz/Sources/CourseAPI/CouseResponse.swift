//
//  response.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/24/25.
//

import Foundation

// MARK: - 수업(Course)

struct CreateCourseRequest: Codable {
    let userId: Int
    let title: String
    let description: String
}

struct CourseResponse: Codable {
    let id: Int
    let userId: Int
    let title: String
    let description: String
    let weeks: [WeekResponse]? // 주차 정보 포함 가능
}

// MARK: - 주차(Week)

struct CreateWeekRequest: Codable {
    let courseId: Int
    let title: String
    let weekNumber: Int
}

struct WeekResponse: Codable {
    let id: Int
    let courseId: Int
    let title: String
    let weekNumber: Int
}

// MARK: - 텍스트(Text)

struct WeekTextResponse: Codable, Identifiable {
    let id: Int
    let weekId: Int
    let content: String
    let summation: String?
}


// MARK: - 사용자 수업 목록 조회
struct CourseResponseByUserID: Decodable, Identifiable,Hashable {
    let id: Int
    let title: String
    let description: String
    let weeks: [WeekResponseByUserID]
}

struct WeekResponseByUserID: Decodable,Identifiable,Hashable {
    let id: Int
    let courseId: Int
    let title: String
}


// MARK: - 텍스트 ID로 get
struct TextDetailResponse: Codable {
let id: Int
let weekId: Int
let content: String
let type: String
let summation: String?
}
