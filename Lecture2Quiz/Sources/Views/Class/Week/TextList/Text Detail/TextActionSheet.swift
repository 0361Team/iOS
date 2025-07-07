//
//  TextActionSheet.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/30/25.
//

import SwiftUI

struct CustomTextActionSheet: View {
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onEdit) {
                Text("텍스트 수정")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Text("텍스트 삭제")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            Divider()
            Button(action: onCancel) {
                Text("취소")
                    .frame(maxWidth: .infinity)
                    .padding()
            }

            Spacer().frame(height: 20) // 하단 여백
        }
    }
}
