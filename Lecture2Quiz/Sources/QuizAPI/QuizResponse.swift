        //
        //  QuizResponse.swift
        //  Lecture2Quiz
        //
        //  Created by 바견규 on 5/27/25.
        //

        import Foundation

        // MARK: - 전체 퀴즈 요약 (목록용)
        struct QuizSummary: Codable, Identifiable {
            let id: Int
            let title: String
            let description: String
            let quizType: String
            let questionCount: Int      // 실제는 totalQuestions로 들어옴
            let createdAt: String?

            enum CodingKeys: String, CodingKey {
                case id
                case title
                case description
                case quizType
                case questionCount = "totalQuestions" // 키 매핑
                case createdAt
            }
        }

        // MARK: - 퀴즈 상세
        struct QuizDetailResponse: Decodable, Identifiable {
            let id: Int
            let title: String
            let description: String
            let quizType: String
            let totalQuestions: Int
            let creator: Creator?
            let weeks: [Week]
            let questions: [QuizQuestion]
            let createdAt: String?
            let modifiedAt: String?

            struct Creator: Decodable {
                let id: Int
                let name: String?
                let email: String?
            }

            struct Week: Decodable, Identifiable {
                let id: Int
                let title: String
                let weekNumber: Int
                let courseId: Int
                let courseTitle: String
            }

            struct QuizQuestion: Decodable, Identifiable {
                let id: Int
                let weekId: Int
                let front: String
                let back: String
            }
        }

        // MARK: - 퀴즈 세션 시작 응답
        struct QuizSessionStartResponse: Codable, Identifiable {
            let id: Int // 세션 ID
        }

        // MARK: - 퀴즈 세션 상세
        struct QuizSessionDetailResponse: Codable, Identifiable {
            let id: Int
            let quizId: Int
            let quizTitle: String
            let quizDescription: String
            let totalQuestions: Int
            let currentQuestionIndex: Int
            let currentQuestion: QuizSessionQuestion?
            let completed: Bool
            let score: Int?
            let totalQuestionsAnswered: Int?
            let totalCorrectAnswers: Int?
            let userAnswers: [UserAnswer]
            let createdAt: String?
            let completedAt: String?
        }

        struct QuizSessionQuestion: Codable, Identifiable {
            let id: Int
            let weekId: Int
            let front: String
            let back: String
        }

        struct UserAnswer: Codable, Identifiable {
            let id: Int
            let questionId: Int
            let questionFront: String
            let userAnswer: String
            let correctAnswer: String
            let isCorrect: Bool
            let answeredAt: String
        }

        // MARK: - 사용자별 퀴즈 세션 목록
        struct QuizSessionSummary: Codable, Identifiable {
            let id: Int // 세션 ID
            let quizTitle: String
            let completed: Bool
            let startedAt: String?
        }

        // MARK: - 주차별 질문 생성 응답
        struct GenerateQuestionsResponse: Codable {
            let questionIds: [Int]
        }
        // 주차별 질문 생성 Request Body 모델
        struct GenerateQuestionRequest: Encodable {
            let minQuestionCount: Int
        }

        // MARK: - 주차별 질문 조회 응답
        struct QuestionResponse: Codable, Identifiable {
            let id: Int
            let weekId: Int
            let front: String
            let back: String

            // 기존 뷰에서 .question, .answer를 쓰던 걸 유지하려면 computed property 제공
            var question: String { front }
            var answer: String { back }
        }


        // MARK: - 퀴즈 세션 삭제 (다수)
        struct QuizSessionDeleteResponse: Codable {
            let totalRequested: Int
            let successCount: Int
            let failureCount: Int
            let deletedSessionIds: [Int]
            let failures: [QuizSessionDeleteFailure]
        }

        struct QuizSessionDeleteFailure: Codable {
            let sessionId: Int
            let reason: String
            let errorCode: String
        }
