import SwiftUI

import DesignSystem

/// 핸드오프 v4 §2 타이포그래피 토큰. tracking은 핸드오프의 em 단위 letter-spacing을 각 폰트 크기 기준 pt로 환산한 값이다.
enum HomeTypography {
    struct Style {
        let font: Font
        let tracking: CGFloat
    }
}

extension HomeTypography.Style {
    static let monthHeader = Self(font: DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 26), tracking: -0.676)
    static let weekdayHeader = Self(font: DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 11), tracking: 0.44)
    static let dateNumber = Self(font: DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 15), tracking: -0.15)
    static let dateNumberEmphasis = Self(font: DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 15), tracking: -0.15)
    static let selectedDateContext = Self(font: DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 15), tracking: -0.18)
    static let lessonCountCaption = Self(font: DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 12.5), tracking: 0)
    static let ctaTitle = Self(font: DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 18), tracking: -0.288)
    static let recordRowTitle = Self(font: DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 15), tracking: -0.15)
    static let recordRowMeta = Self(font: DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 12.5), tracking: 0)
    static let emptyDayTitle = Self(font: DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 14.5), tracking: -0.145)
    static let emptyDaySubtext = Self(font: DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 12.5), tracking: 0)
}

extension View {
    func homeTypography(_ style: HomeTypography.Style) -> some View {
        font(style.font).tracking(style.tracking)
    }
}
