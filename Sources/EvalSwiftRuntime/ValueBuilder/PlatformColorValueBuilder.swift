#if canImport(UIKit)
import SwiftUI
import UIKit

public struct UIColorValueBuilder: RuntimeValueBuilder {
    public let name = "UIColor"
    public let definitions: [RuntimeBuilderDefinition] = []

    public init() {}

    public func populate(type: RuntimeType) {
        type.define(
            "systemGroupedBackground",
            value: .swiftUI(.platformColor(RuntimePlatformColor(UIColor.systemGroupedBackground)))
        )
    }
}
#elseif canImport(AppKit)
import SwiftUI
import AppKit

public struct NSColorValueBuilder: RuntimeValueBuilder {
    public let name = "NSColor"
    public let definitions: [RuntimeBuilderDefinition] = []

    public init() {}

    public func populate(type: RuntimeType) {
        type.define(
            "systemGroupedBackground",
            value: .swiftUI(.platformColor(RuntimePlatformColor(NSColor.windowBackgroundColor)))
        )
    }
}
#endif
