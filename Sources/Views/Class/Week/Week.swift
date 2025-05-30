//
//  Week.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/25/25.
//

import SwiftUI

struct WeekListView: View {
    @StateObject private var viewModel: WeekListViewModel

    init(course: CourseResponseByUserID, onDeleteSuccess: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: WeekListViewModel(course: course, onDeleteSuccess: onDeleteSuccess))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(viewModel.course.title)
                        .font(.title)
                        .bold()
                    Spacer()
                    Button {
                        viewModel.isShowingActionSheet = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90)) // 세로로 ...
                            .foregroundColor(.primary)
                            .padding()
                    }
                }
                .padding(.top)

                if viewModel.course.weeks.isEmpty {
                    Text("등록된 주차가 없습니다.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 100)
                } else {
                    ForEach(viewModel.course.weeks) { week in
                        WeekRowView(
                            week: week,
                            courseTitle: viewModel.course.title,
                            onDeleteSuccess: viewModel.onDeleteSuccess
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("주차 목록")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isShowingActionSheet) {
            CustomCourseActionSheet(
                onDelete: {
                    viewModel.deleteCourse()
                },
                onCancel: {
                    viewModel.isShowingActionSheet = false
                },
                actionStr: "수업 삭제"
            )
            .presentationDetents([.height(140)])
            .presentationDragIndicator(.visible)
            .padding(.top, 24)
        }
    }
}



    struct WeekRowView: View {
        let week: WeekResponseByUserID
        let courseTitle: String
        let onDeleteSuccess: () -> Void

        var body: some View {
            NavigationLink(
                destination: TextListView(
                    weekId: week.id,
                    courseTitle: courseTitle,
                    weekTitle: week.title,
                    onDeleteSuccess: onDeleteSuccess
                )
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("🗓️ \(week.title)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    Text("Week ID: \(week.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }





    // Preview용 Mock 데이터
    // 📦 Mock 데이터
    let mockCourse = CourseResponseByUserID(
        id: 1,
        title: "프로그래밍 언어",
        description: "프로그래밍 언어 수업입니다.",
        weeks: [
            WeekResponseByUserID(id: 101, courseId: 1, title: "1주차 - 변수와 자료형"),
            WeekResponseByUserID(id: 102, courseId: 1, title: "2주차 - 제어문"),
            WeekResponseByUserID(id: 103, courseId: 1, title: "3주차 - 함수")
        ]
    )

    // 🧪 Preview
    #Preview {
        NavigationStack {
            WeekListView(course: mockCourse) {
                print("삭제 성공 (Preview)")
            }
        }
    }

