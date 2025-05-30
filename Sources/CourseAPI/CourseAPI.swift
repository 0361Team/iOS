//
//  CourseAPI.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/24/25.
//

import Foundation
import Moya

// 수업 및 텍스트 관련 API 라우터
enum CourseAPI {
    
    // 수업 생성
    case createCourse(userId: Int, title: String, description: String)
    
    // 수업 ID로 주차 목록 조회
    // - 사용처: 녹음 종료 시 수업 선택 뷰 등에서 호출
    case getCourseWeeks(courseId: Int)
    
    // 주차 ID로 텍스트 조회
    // - 사용처: 텍스트 상세 열람 시 사용
    case getWeekText(weekId: Int)
    
    // 주차 생성
    // - 사용처: 주차 선택 뷰에서 새 주차 생성 시
    case createWeek(courseId: Int, title: String, weekNumber: Int)
    
    // 텍스트 ID로 키워드 조회
    case getKeywords(textId: Int)
    
    // 키워드 생성 요청
    case createKeyword(textId: Int)
    
    // 텍스트 요약 생성 요청
    case summarizeText(textId: Int)
    
    // 사용자별 수업 목록 조회
    // - 사용처: 수업 선택 뷰 최초 로딩 시
    case getUserCourses(userId: Int)
    
    // 녹음 내용을 주차에 제출
    // - 사용처: 녹음 종료 후 내용 업로드
    case submitTranscript(weekId: Int, content: String, type: String)
    
    // 텍스트 ID로 텍스트 단건 조회
    // - 사용처: 퀴즈 생성 시 텍스트 내용 기반 활용
    case getTextById(id: Int)
    
    // 수업 삭제
    case deleteCourse(courseId: Int)

    // 주차 삭제
    case deleteWeek(weekId: Int)

    // 텍스트 삭제
    case deleteText(textId: Int)

    // 텍스트 수정
    case updateText(textId: Int, content: String, type: String)
}


extension CourseAPI: TargetType {
    var baseURL: URL {
        let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_URL") as! String
        return URL(string: baseURL)!
    }
    
    var path: String {
        switch self {
        case .createCourse:
            return "/v1/course"
        case .getCourseWeeks(let courseId):
            return "/v1/course/\(courseId)"
        case .getWeekText(let weekId):
            return "/v1/texts/weeks/\(weekId)"
        case .createWeek:
            return "/weeks"
        case .getKeywords(let textId), .createKeyword(let textId):
            return "/v1/texts/keywords/\(textId)"
        case .summarizeText(let textId):
            return "/v1/texts/summation/\(textId)"
        case .getUserCourses(let userId):
            return "/v1/course/user/\(userId)/courses"
        case .submitTranscript:
            return "/v1/texts"
        case .getTextById(let id):
            return "/v1/texts/\(id)"
        case .deleteCourse(let courseId):
            return "/v1/course/\(courseId)"
        case .deleteWeek(let weekId):
            return "/api/weeks/\(weekId)"
        case .deleteText(let textId), .updateText(let textId, _, _):
            return "/v1/texts/\(textId)"

        }
    }

    var method: Moya.Method {
        switch self {
        case .createCourse, .createWeek, .createKeyword, .summarizeText, .submitTranscript:
            return .post
        case .getCourseWeeks, .getWeekText, .getKeywords, .getUserCourses, .getTextById:
            return .get
        case .deleteCourse, .deleteWeek, .deleteText:
            return .delete
        case .updateText:
            return .put
        }
    }

    var task: Task {
        switch self {
        case let .createCourse(userId, title, description):
            return .requestParameters(parameters: [
                "userId": userId,
                "title": title,
                "description": description
            ], encoding: JSONEncoding.default)
        case let .createWeek(courseId, title, weekNumber):
            return .requestParameters(parameters: [
                "courseId": courseId,
                "title": title,
                "weekNumber": weekNumber
            ], encoding: JSONEncoding.default)
        case .createKeyword, .summarizeText:
            return .requestPlain
        case let .submitTranscript(weekId, content, type):
                return .requestParameters(
                    parameters: [
                        "weekId": weekId,
                        "content": content,
                        "type": type
                    ],
                    encoding: JSONEncoding.default
                )
        case .updateText(_, let content, let type):
            return .requestParameters(parameters: [
                "content": content,
                "type": type
            ], encoding: JSONEncoding.default)

        default:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return [
            "accept": "*/*",
            "content-type": "application/json"
        ]
    }
}
