#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI

public struct RuntimePlatformColor {
#if canImport(UIKit)
    let uiColor: UIColor

    init(_ color: UIColor) {
        self.uiColor = color
    }

    func makeSwiftUIColor() -> Color {
        Color(uiColor)
    }
#elseif canImport(AppKit)
    let nsColor: NSColor

    init(_ color: NSColor) {
        self.nsColor = color
    }

    func makeSwiftUIColor() -> Color {
        Color(nsColor)
    }
#else
    func makeSwiftUIColor() -> Color {
        Color.clear
    }
#endif
}
