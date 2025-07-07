//
//  Fonts.swift
//  Starbucks
//
//  Created by 박현규 on 3/19/25.
//

import Foundation
import SwiftUI

extension Font {
   enum Pretend: String {
       case extraBold = "Pretendard-ExtraBold"
       case bold = "Pretendard-Bold"
       case semibold = "Pretendard-SemiBold"
       case medium = "Pretendard-Medium"
       case regular = "Pretendard-Regular"
       case light = "Pretendard-Light"

       var value: String {
           return self.rawValue
       }
       
       // 함수로 변경하여 크기 조정 가능하도록 수정
       static func pretendardBold(size: CGFloat) -> Font {
           return Lecture2QuizFontFamily.Pretendard.bold.swiftUIFont(size: size)
       }
       
       static func pretendardLight(size: CGFloat) -> Font {
           return Lecture2QuizFontFamily.Pretendard.light.swiftUIFont(size: size)
       }
       
       static func pretendardExtraBold(size: CGFloat) -> Font {
           return Lecture2QuizFontFamily.Pretendard.extraBold.swiftUIFont(size: size)
       }
       
       static func pretendardSemiBold(size: CGFloat) -> Font {
           return Lecture2QuizFontFamily.Pretendard.semiBold.swiftUIFont(size: size)
       }
       
       static func pretendardMedium(size: CGFloat) -> Font {
           return Lecture2QuizFontFamily.Pretendard.medium.swiftUIFont(size: size)
       }
       
       static func pretendardRegular(size: CGFloat) -> Font {
           return Lecture2QuizFontFamily.Pretendard.regular.swiftUIFont(size: size)
       }
   
   }
}



