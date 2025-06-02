//
//  FlowLayout.swift
//  Lecture2Quiz
//
//  Created by 바견규 on 5/31/25.
//

import SwiftUI

//키워드용 FlowLayout
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    init(data: Data, spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var rows: [[Data.Element]] = [[]]
        
        // 레이아웃 계산
        for element in data {
            let item = content(element)
            let size = item
                .background(GeometryReader { geo in Color.clear })
                .fixedSize()
                .frame(height: 10)
            
            let itemWidth: CGFloat = 80 // 추정값 또는 측정 값
            if width + itemWidth > geometry.size.width {
                width = 0
                rows.append([])
            }
            rows[rows.count - 1].append(element)
            width += itemWidth + spacing
        }

        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { element in
                        content(element)
                    }
                }
            }
        }
    }
}
