//
//  WeekQuestionView.swift
//  Lecture2Quiz
//

import SwiftUI

struct WeekQuestionView: View {
    @ObservedObject var viewModel: WeekQuestionViewModel
    @State private var showMinCountPrompt: Int? = nil
    @State private var minQuestionCount: Int = 3

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 수업 선택
                    HStack {
                        Text("수업을 선택해주세요.")
                            .foregroundColor(.black)

                        Spacer()

                        Menu {
                            Picker("수업 선택", selection: $viewModel.selectedCourseId) {
                                ForEach(viewModel.courses, id: \.id) { course in
                                    Text(course.title).tag(Optional(course.id))
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.selectedCourseTitle ?? "선택")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedCourseId) {
                        if let id = viewModel.selectedCourseId {
                            viewModel.selectCourse(id: id)
                        }
                    }

                    // 주차별 질문 목록
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.weeks, id: \.id) { week in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Week \(week.title)")
                                        .font(.headline)
                                    Spacer()

                                    let questions = viewModel.questionsPerWeek[week.id]

                                    if let questions = viewModel.questionsPerWeek[week.id], !questions.isEmpty {
                                        Button(viewModel.isQuestionsVisible[week.id] == true ? "질문 숨기기" : "질문 조회") {
                                            viewModel.toggleQuestionVisibility(for: week.id)
                                        }
                                        .buttonStyle(BlackButtonStyle())
                                    } else {
                                        Button("질문 생성") {
                                            showMinCountPrompt = week.id
                                        }
                                        .buttonStyle(BlackButtonStyle())
                                    }
                                }

                                if viewModel.isQuestionsVisible[week.id] == true,
                                   let questions = viewModel.questionsPerWeek[week.id], !questions.isEmpty {
                                    ForEach(questions) { question in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Q. \(question.question)")
                                                .fontWeight(.semibold)
                                            Text("A. \(question.answer)")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }

                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .disabled(viewModel.isLoading)
            .blur(radius: viewModel.isLoading ? 3 : 0)

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("로딩 중입니다...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    .shadow(radius: 10)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            viewModel.fetchCourses()
        }
        .alert("질문 개수 입력", isPresented: Binding<Bool>(
            get: { showMinCountPrompt != nil },
            set: { if !$0 { showMinCountPrompt = nil } }
        )) {
            TextField("예: 3", value: $minQuestionCount, formatter: NumberFormatter())
            Button("생성") {
                if let weekId = showMinCountPrompt {
                    viewModel.generateQuestions(for: weekId, minCount: minQuestionCount)
                    showMinCountPrompt = nil
                }
            }
            Button("취소", role: .cancel) {
                showMinCountPrompt = nil
            }
        } message: {
            Text("생성할 최소 질문 수를 입력하세요.")
        }
    }
}

struct BlackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
