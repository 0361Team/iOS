//
//  CustomCourseActionSheet.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/30/25.
//

import SwiftUI

struct CustomCourseActionSheet: View {
    var onDelete: () -> Void
    var onCancel: () -> Void
    var actionStr:String

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text(actionStr)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.white)
                }

                Divider()

                Button {
                    onCancel()
                } label: {
                    Text("취소")
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 5)
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.001)) // 투명 배경으로 만들기
        .ignoresSafeArea()
    }
}
#Preview {
    CustomCourseActionSheet(
        onDelete: {
            print("🗑️ 삭제 프리뷰")
        },
        onCancel: {
            print("❌ 취소 프리뷰")
        },
        actionStr: "삭제"
    )
    .previewLayout(.sizeThatFits)
    .padding()
    .background(Color.gray.opacity(0.2))
}
