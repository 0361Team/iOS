//
//  CreationQuizSheetView.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/28/25.
//

import SwiftUI

struct CreateQuizSheetView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedCourseId: Int?
    @State private var selectedWeekIds: Set<Int> = []
    @State private var questionCount: Int = 5
    @State private var filteredWeeks: [WeekResponseByUserID] = []

    var body: some View {
        NavigationStack {
            Form {
                // ✅ 수업 선택
                Section(header: Text("수업 선택")) {
                    Picker("수업", selection: $selectedCourseId) {
                        ForEach(viewModel.courses) { course in
                            Text(course.title).tag(Optional(course.id))
                        }
                    }
                    .onChange(of: selectedCourseId) { oldValue, newValue in
                        if let id = newValue {
                            viewModel.getWeeksWithQuestions(for: id) { weeks in
                                filteredWeeks = weeks
                                selectedWeekIds = [] // 선택 초기화
                            }
                        }
                    }

                }

                // ✅ 질문이 있는 주차만 표시
                if !filteredWeeks.isEmpty {
                    Section(header: Text("주차 선택 (질문 있음)")) {
                        ForEach(filteredWeeks) { week in
                            Toggle(week.title, isOn: Binding(
                                get: { selectedWeekIds.contains(week.id) },
                                set: { isOn in
                                    if isOn {
                                        selectedWeekIds.insert(week.id)
                                    } else {
                                        selectedWeekIds.remove(week.id)
                                    }
                                }
                            ))
                        }
                    }
                }

                // ✅ 문항 수
                Section(header: Text("문항 수")) {
                    Stepper(value: $questionCount, in: 1...20) {
                        Text("\(questionCount)문항")
                    }
                }

                // ✅ 생성 버튼
                Section {
                    Button("퀴즈 생성") {
                        if let courseId = selectedCourseId {
                            viewModel.createQuiz(
                                for: Array(selectedWeekIds),
                                courseTitle: viewModel.courses.first(where: { $0.id == courseId })?.title ?? "",
                                questionCount: questionCount
                            )
                            dismiss()
                        }
                    }
                    .disabled(selectedWeekIds.isEmpty || selectedCourseId == nil)
                }
            }
            .navigationTitle("퀴즈 생성")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

