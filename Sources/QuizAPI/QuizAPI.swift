//
//  QuizAPI.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/27/25.
//

import Foundation
import Moya

// 퀴즈 관련 API 라우터
enum QuizAPI {
    // 사용자별 전체 퀴즈 조회
    case getQuizzes(userId: Int)

    // 퀴즈 생성
    case createQuiz(userId: Int, title: String, description: String, weekIds: [Int], quizType: String, questionCount: Int)
    
    // 주차 질문 생성
    case generateQuestions(weekId: Int, minQuestionCount: Int)
    
    // 주차의 질문 조회
    case getWeekQuestions(weekId: Int)
    
    // 퀴즈 상세 조회
    case getQuizDetail(id: Int)
    
    // 퀴즈 세션 시작
    case startQuizSession(quizId: Int, userId: Int)
    
    // 퀴즈 세션 답변 기록
    case answerQuizSession(sessionId: Int, userAnswer: String)
    
    // 퀴즈 세션 완료
    case completeQuizSession(sessionId: Int)
    
    // 사용자별 퀴즈 세션 목록 조회
    case getUserQuizSessions(userId: Int)
    
    // 퀴즈 세션 상세 조회
    case getQuizSessionDetail(sessionId: Int)
    
    // 퀴즈 삭제
    case deleteQuiz(id: Int)
}

extension QuizAPI: TargetType {
    var baseURL: URL {
        let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_URL") as! String
        return URL(string: baseURL)!
    }

    var path: String {
        switch self {
        case .getQuizzes:
            return "/v1/quizzes"
        case .createQuiz:
            return "/v1/quizzes"
        case .generateQuestions(let weekId, _):
            return "/v1/questions/weeks/\(weekId)/generate"
        case .getWeekQuestions(let weekId):
            return "/v1/questions/weeks/\(weekId)"
        case .getQuizDetail(let id):
            return "/v1/quizzes/\(id)"
        case .startQuizSession(let quizId, _):
            return "/v1/quizzes/\(quizId)/start"
        case .answerQuizSession(let sessionId, _):
            return "/v1/quiz-sessions/\(sessionId)/answer"
        case .completeQuizSession(let sessionId):
            return "/v1/quiz-sessions/\(sessionId)/complete"
        case .getUserQuizSessions(let userId):
            return "/v1/quiz-sessions/user/\(userId)"
        case .getQuizSessionDetail(let sessionId):
            return "/v1/quiz-sessions/\(sessionId)"
        case .deleteQuiz(let id):
            return "/v1/quizzes/\(id)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createQuiz, .generateQuestions, .startQuizSession, .answerQuizSession, .completeQuizSession:
            return .post
        case .getQuizzes, .getWeekQuestions, .getQuizDetail, .getUserQuizSessions, .getQuizSessionDetail:
            return .get
        case .deleteQuiz:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case .getQuizzes(let userId):
            // 사용자 ID로 퀴즈 목록 조회
            return .requestParameters(parameters: ["userId": userId], encoding: URLEncoding.queryString)

        case let .createQuiz(userId, title, description, weekIds, quizType, questionCount):
            // 퀴즈 생성 시 필요한 파라미터
            let body: [String: Any] = [
                "userId": userId,
                "title": title,
                "description": description,
                "weekIds": weekIds,
                "quizType": quizType,
                "questionCount": questionCount
            ]
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)

        case .generateQuestions(_, let minQuestionCount):
            let body = GenerateQuestionRequest(minQuestionCount: minQuestionCount)
            return .requestJSONEncodable(body)
          
        case let .answerQuizSession(_, userAnswer):
            // 사용자의 답변 기록
            return .requestParameters(parameters: ["userAnswer": userAnswer], encoding: JSONEncoding.default)

        case let .startQuizSession(_, userId):
            return .requestParameters(parameters: ["userId": userId], encoding: URLEncoding.queryString)

        case .deleteQuiz:
            return .requestPlain
            
        default:
            return .requestPlain // GET 요청 또는 바디 없는 POST
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "Accept": "*/*"
        ]

        if let token = KeychainHelper.shared.readAccessToken() {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}
